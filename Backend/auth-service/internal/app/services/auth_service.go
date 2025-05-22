package services

import (
	"context"
	"errors"
	"fmt"
	"log"
	"net/url"
	"os"
	"time"

	"github.com/go-redis/redis/v8"
	"golang.org/x/crypto/bcrypt"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"gorm.io/gorm"

	"Rewind-auth-service/internal/app/models"
	"Rewind-auth-service/internal/app/repositories"
	"Rewind-auth-service/internal/utils"
	"Rewind-auth-service/pkg/rabbitmq"

	"github.com/go-playground/validator/v10"
	"github.com/google/uuid"

	pb "Rewind-auth-service/pkg/proto"
)

type AuthService struct {
	userRepo repositories.UserRepositoryInterface
	pb.UnimplementedAuthServiceServer
	validator *validator.Validate
	redisRepo repositories.RedisRepositoryInterface
}

func NewAuthService(repo repositories.UserRepositoryInterface, validator *validator.Validate, redisClient repositories.RedisRepositoryInterface) *AuthService {
	return &AuthService{
		userRepo:  repo,
		validator: validator,
		redisRepo: redisClient,
	}
}

func (s *AuthService) StartRegistration(ctx context.Context, req *pb.StartRegistrationRequest) (*pb.StartRegistrationResponse, error) {
	email := req.GetEmail()

	if err := s.validator.Var(email, "required,email"); err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "invalid email format: %v", err)
	}

	_, err := s.userRepo.GetUserByEmail(nil, email)
	if err == nil {
		return nil, status.Errorf(codes.AlreadyExists, "user with email %s already exists", email)
	}

	if !errors.Is(err, gorm.ErrRecordNotFound) {
		log.Printf("Error querying user by email %s during registration check: %v", email, err)
		return nil, status.Errorf(codes.Internal, "Failed to check user existence")
	}

	registrationID := uuid.New().String()

	verificationCode := utils.GenerateVerificationCode()

	redisKey := fmt.Sprintf("registration:%s", registrationID)
	expiryTime := time.Minute * 15 // Код действителен в течение 15 минут (настройте по необходимости)

	// Сохранение данных регистрации в Redis
	err = s.redisRepo.HSet(ctx, redisKey, map[string]interface{}{
		"email": email,
		"code":  verificationCode,
	}).Err()
	if err != nil {
		log.Printf("Error saving registration data to Redis for ID %s: %v", registrationID, err)
		return nil, status.Errorf(codes.Internal, "Failed to store registration data")
	}

	// Установка времени жизни ключа в Redis (ошибка не блокирует основную операцию, логируем как warning)
	err = s.redisRepo.Expire(ctx, redisKey, expiryTime).Err()
	if err != nil {
		log.Printf("Warning: failed to set expiry for Redis key %s: %v\n", redisKey, err)
	}

	// Публикация события для отправки email
	err = rabbitmq.PublishVerificationCode(email, verificationCode)
	if err != nil {
		log.Printf("Error publishing verification code to RabbitMQ for email %s: %v", email, err)
		return nil, status.Errorf(codes.Internal, "Failed to send verification email")
	}

	// Успешное начало регистрации
	return &pb.StartRegistrationResponse{RegistrationId: registrationID, Success: true}, nil
}

func (s *AuthService) VerifyEmailCode(ctx context.Context, req *pb.VerifyEmailCodeRequest) (*pb.VerifyEmailCodeResponse, error) {
	registrationID := req.GetRegistrationId()
	verificationCode := req.GetVerificationCode()

	redisKey := fmt.Sprintf("registration:%s", registrationID)

	registrationData, err := s.redisRepo.HGetAll(ctx, redisKey).Result()
	if err != nil {
		log.Printf("Error getting registration data from Redis for ID %s: %v", registrationID, err)
		return nil, status.Errorf(codes.Internal, "Failed to retrieve registration data")
	}

	// Если данные пусты, это тоже может означать, что ID не найден или истек
	if len(registrationData) == 0 {
		// Возвращаем статус gRPC с кодом NotFound
		return nil, status.Errorf(codes.NotFound, "Invalid or expired registration ID")
	}

	storedEmail, okEmail := registrationData["email"]
	storedCode, okCode := registrationData["code"]

	if !okEmail || !okCode {
		log.Printf("Internal error: registration data incomplete for ID %s. Data: %+v", registrationID, registrationData)
		return nil, status.Errorf(codes.Internal, "Failed to process registration data")
	}

	if verificationCode != storedCode {
		return &pb.VerifyEmailCodeResponse{Success: false}, status.Errorf(codes.InvalidArgument, "Invalid verification code")
	}

	verifiedKey := fmt.Sprintf("verified:%s", registrationID)
	expiryTime := time.Minute * 120

	err = s.redisRepo.SetEX(ctx, verifiedKey, storedEmail, expiryTime).Err()
	if err != nil {
		log.Printf("Error marking email as verified in Redis for ID %s: %v", registrationID, err)
		return nil, status.Errorf(codes.Internal, "Failed to finalize verification")
	}

	err = s.redisRepo.Del(ctx, redisKey).Err()
	if err != nil {
		log.Printf("Warning: failed to delete registration data from Redis for ID %s: %v\n", registrationID, err)
	}

	return &pb.VerifyEmailCodeResponse{Success: true}, nil
}

func (s *AuthService) SetPasswordAndUsername(ctx context.Context, req *pb.SetPasswordAndUsernameRequest) (*pb.SetPasswordAndUsernameResponse, error) {
	registrationID := req.GetRegistrationId()
	password := req.GetPassword()
	username := req.GetUsername()

	// Валидация пароля
	if err := s.validator.Var(password, "required,min=6"); err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "invalid password: %v", err)
	}
	// Валидация имени пользователя
	if err := s.validator.Var(username, "required,min=3,max=50"); err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "invalid username: %v", err)
	}

	verifiedKey := fmt.Sprintf("verified:%s", registrationID)

	// Получение email из Redis по registrationID
	email, err := s.redisRepo.Get(ctx, verifiedKey).Result()
	if err != nil {
		// Ошибка получения из Redis, скорее всего, ID не найден или истек
		log.Printf("Error getting verified email from Redis for ID %s: %v", registrationID, err)
		// Возвращаем NotFound статус
		return nil, status.Errorf(codes.NotFound, "Invalid or expired registration ID")
	}

	// Хеширование пароля
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		// Внутренняя ошибка хеширования
		log.Printf("Failed to hash password: %v", err)
		return nil, status.Errorf(codes.Internal, "Failed to process password")
	}

	newUser := &models.User{
		Email:    email,
		Password: string(hashedPassword),
		Username: username,
	}

	// Поиск удаленного пользователя по email для "восстановления"
	user, err := s.userRepo.GetDeletedUserByEmail(nil, email)

	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		// Если ошибка не nil и НЕ ErrRecordNotFound, это другая ошибка БД
		log.Printf("Error querying deleted user by email %s: %v", email, err)
		return nil, status.Errorf(codes.Internal, "Failed to check for deleted user")
	}

	if err == nil { // Если err == nil, значит пользователь найден (был мягко удален)
		// Пользователь найден (был мягко удален) - "восстанавливаем" его
		log.Printf("User with email %s already existed and was deleted, undeleting and updating", email)
		newUser.ID = user.ID                       // Сохраняем старый ID
		err = s.userRepo.SaveDeleted(nil, newUser) // SaveDeleted установит deleted_at = NULL
		if err != nil {
			// Ошибка сохранения/обновления в БД
			log.Printf("Failed to save (undelete/update) user with ID %d: %v", newUser.ID, err)
			return nil, status.Errorf(codes.Internal, "Failed to finalize user registration")
		}
	} else { // Если err == gorm.ErrRecordNotFound (пользователь не найден)
		// Пользователь не найден (ни активный, ни удаленный) - создаем нового

		err = s.userRepo.CreateUser(nil, newUser)
		if err != nil {

			if errors.Is(err, gorm.ErrDuplicatedKey) {
				log.Printf("Conflict creating new user with email %s or username %s: %v", email, username, err)
				return nil, status.Errorf(codes.AlreadyExists, "User with this email or username already exists")
			}

			// Если это не ошибка уникального ключа, это другая ошибка БД
			log.Printf("Failed to create new user with email %s: %v", email, err)
			return nil, status.Errorf(codes.Internal, "Failed to finalize user registration")
		}
	}

	// Удаляем запись о верификации из Redis (ошибка не блокирует основную операцию, логируем как warning)
	err = s.redisRepo.Del(ctx, verifiedKey).Err()
	if err != nil {
		log.Printf("Warning: failed to delete verification record from Redis for ID %s: %v\n", registrationID, err)
	}

	// Получение секретного ключа JWT из переменных окружения
	secretKey := os.Getenv("JWT_SECRET_KEY")
	if secretKey == "" {
		// Ошибка конфигурации - внутренняя ошибка
		log.Println("JWT_SECRET_KEY environment variable not found")
		return nil, status.Errorf(codes.Internal, "Server configuration error")
	}

	// Генерация токенов
	accessToken, err := utils.GenerateAccessToken(newUser.ID, username, secretKey)
	if err != nil {
		// Внутренняя ошибка генерации токена
		log.Printf("Failed to generate access token for user ID %d: %v", newUser.ID, err)
		return nil, status.Errorf(codes.Internal, "Failed to generate access token")
	}

	refreshToken, err := utils.GenerateRefreshToken()
	if err != nil {
		// Внутренняя ошибка генерации токена
		log.Printf("Failed to generate refresh token for user ID %d: %v", newUser.ID, err)
		return nil, status.Errorf(codes.Internal, "Failed to generate refresh token")
	}

	// Добавление сессии в БД
	err = s.userRepo.AddSession(nil, newUser.ID, refreshToken)
	if err != nil {
		// Ошибка сохранения сессии в БД
		log.Printf("Failed to add refresh token to database for user ID %d: %v", newUser.ID, err)
		return nil, status.Errorf(codes.Internal, "Failed to save user session")
	}

	// Успешное завершение регистрации и логин
	return &pb.SetPasswordAndUsernameResponse{AccessToken: accessToken, RefreshToken: refreshToken}, nil
}

func (s *AuthService) Login(ctx context.Context, req *pb.LoginRequest) (*pb.LoginResponse, error) {
	email := req.GetEmail()
	password := req.GetPassword()

	// Валидация email и пароля
	if err := s.validator.Var(email, "required,email"); err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "Invalid email format: %v", err)
	}
	if err := s.validator.Var(password, "required"); err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "Password is required")
	}

	var user *models.User
	user, err := s.userRepo.GetUserByEmail(nil, email)

	// Обработка ошибки поиска в репозитории, исключая ErrRecordNotFound
	if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, status.Errorf(codes.Internal, "Failed to retrieve user data")
	}

	// Если пользователь не найден (user == nil) или ошибка была ErrRecordNotFound
	if user == nil || errors.Is(err, gorm.ErrRecordNotFound) {
		return nil, status.Errorf(codes.Unauthenticated, "Invalid credentials")
	}

	// Проверка пароля
	err = bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password))
	if err != nil {
		return nil, status.Errorf(codes.Unauthenticated, "Invalid credentials")
	}

	// Получение секретного ключа JWT
	secretKey := os.Getenv("JWT_SECRET_KEY")
	if secretKey == "" {
		log.Println("JWT_SECRET_KEY environment variable not found")
		return nil, status.Errorf(codes.Internal, "Server configuration error")
	}

	// Генерация токенов
	accessToken, err := utils.GenerateAccessToken(user.ID, user.Username, secretKey)
	if err != nil {
		log.Printf("Failed to generate access token for user ID %d: %v", user.ID, err)
		return nil, status.Errorf(codes.Internal, "Failed to generate access token")
	}

	refreshToken, err := utils.GenerateRefreshToken()
	if err != nil {
		log.Printf("Failed to generate refresh token for user ID %d: %v", user.ID, err)
		return nil, status.Errorf(codes.Internal, "Failed to generate refresh token")
	}

	// Добавление сессии в БД
	err = s.userRepo.AddSession(nil, user.ID, refreshToken)
	if err != nil {
		log.Printf("Failed to add refresh token to database for user ID %d: %v", user.ID, err)
		return nil, status.Errorf(codes.Internal, "Failed to save user session")
	}

	// Успешный логин
	return &pb.LoginResponse{AccessToken: accessToken, RefreshToken: refreshToken}, nil
}

func (s *AuthService) RefreshToken(ctx context.Context, req *pb.RefreshTokenRequest) (*pb.RefreshTokenResponse, error) {
	refreshToken := req.GetRefreshToken()

	if refreshToken == "" {
		return nil, status.Errorf(codes.InvalidArgument, "Refresh token is required")
	}

	// Получение записи токена обновления из БД
	refreshTokenRecord, err := s.userRepo.GetRefreshToken(nil, refreshToken)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, status.Errorf(codes.Unauthenticated, "Invalid refresh token")
		}
		log.Printf("Failed to query refresh token %s: %v", refreshToken, err)
		return nil, status.Errorf(codes.Internal, "Failed to retrieve refresh token data")
	}

	// Получение пользователя, связанного с токеном
	user, err := s.userRepo.GetUserByID(nil, refreshTokenRecord.UserID)
	if err != nil {
		// Если пользователь не найден, связанный с токеном, это внутренняя проблема.
		log.Printf("Failed to query user by ID %d associated with refresh token %s: %v", refreshTokenRecord.UserID, refreshToken, err)
		return nil, status.Errorf(codes.Internal, "Failed to retrieve user data for refresh token")
	}

	// Получение секретного ключа JWT
	secretKey := os.Getenv("JWT_SECRET_KEY")
	if secretKey == "" {
		log.Println("JWT_SECRET_KEY environment variable not found")
		return nil, status.Errorf(codes.Internal, "Server configuration error")
	}

	// Генерация нового access токена
	newAccessToken, err := utils.GenerateAccessToken(user.ID, user.Username, secretKey)
	if err != nil {
		log.Printf("Failed to generate new access token for user ID %d: %v", user.ID, err)
		return nil, status.Errorf(codes.Internal, "Failed to generate access token")
	}

	// Успешное обновление access токена
	return &pb.RefreshTokenResponse{AccessToken: newAccessToken}, nil
}

func (s *AuthService) ForgotPassword(ctx context.Context, req *pb.ForgotPasswordRequest) (*pb.ForgotPasswordResponse, error) {
	email := req.GetEmail()

	// 1. Валидация email
	if err := s.validator.Var(email, "required,email"); err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "Invalid email format")
	}

	// 2. Проверка существования пользователя с таким email
	_, err := s.userRepo.GetUserByEmail(nil, email)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			log.Printf("ForgotPassword: user with email %s not found", email)
			return &pb.ForgotPasswordResponse{Success: true}, nil
		}
		log.Printf("Failed to query user by email %s: %v", email, err)
		return nil, status.Errorf(codes.Internal, "Failed to retrieve user data")
	}

	// 3. Генерация уникального токена для сброса пароля
	resetToken := uuid.New().String()

	// 4. Сохранение токена в Redis с привязкой к email и временем истечения
	resetTokenKey := fmt.Sprintf("reset-token:%s", resetToken)
	expirationTime := time.Hour * 2 // Например, токен действует 2 часа
	err = s.redisRepo.SetEX(ctx, resetTokenKey, email, expirationTime).Err()
	if err != nil {
		log.Printf("Failed to save reset token to Redis for email %s: %v", email, err)
		return nil, status.Errorf(codes.Internal, "Failed to store reset token")
	}

	// 5. Формирование ссылки для сброса пароля
	frontendURL := os.Getenv("FRONTEND_URL")
	if frontendURL == "" {
		log.Println("FRONTEND_URL environment variable not found")
		return nil, status.Errorf(codes.Internal, "Server configuration error")
	}
	resetLink := fmt.Sprintf("%s/reset-password?token=%s", frontendURL, url.QueryEscape(resetToken))

	// 6. Отправка ссылки для сброса пароля в сервис уведомлений
	err = rabbitmq.PublishForgotPasswordEmail(email, resetLink)
	if err != nil {
		log.Printf("Failed to publish forgot password email for email %s: %v", email, err)
		return nil, status.Errorf(codes.Internal, "Failed to send password reset email")
	}

	// Успех (даже если пользователь не найден, для предотвращения user enumeration)
	return &pb.ForgotPasswordResponse{Success: true}, nil
}

func (s *AuthService) ResetPassword(ctx context.Context, req *pb.ResetPasswordRequest) (*pb.ResetPasswordResponse, error) {
	token := req.GetToken()
	newPassword := req.GetNewPassword()

	// 1. Валидация нового пароля
	if err := s.validator.Var(newPassword, "required,min=6"); err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "Invalid new password format")
	}

	// 2. Формирование ключа Redis для поиска email по токену
	resetTokenKey := fmt.Sprintf("reset-token:%s", token)

	// 3. Получение email из Redis по токену
	email, err := s.redisRepo.Get(ctx, resetTokenKey).Result()
	if err != nil {
		if errors.Is(err, redis.Nil) {
			return nil, status.Errorf(codes.NotFound, "Invalid or expired reset token")
		}
		log.Printf("Failed to get email from Redis for token %s: %v", token, err)
		return nil, status.Errorf(codes.Internal, "Failed to retrieve reset token data")
	}

	// 4. Поиск пользователя в базе данных по email
	user, err := s.userRepo.GetUserByEmail(nil, email)
	if err != nil {
		log.Printf("Failed to query user by email %s associated with token %s: %v", email, token, err)
		return nil, status.Errorf(codes.Internal, "Failed to retrieve user data for token")
	}

	// 5. Хеширование нового пароля
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		log.Printf("Failed to hash new password: %v", err)
		return nil, status.Errorf(codes.Internal, "Failed to process password")
	}

	// 6. Обновление пароля пользователя в базе данных
	user.Password = string(hashedPassword)
	err = s.userRepo.Save(nil, user)
	if err != nil {
		log.Printf("Failed to update user password in database for user ID %d: %v", user.ID, err)
		return nil, status.Errorf(codes.Internal, "Failed to update user password")
	}

	// 7. Удаление использованного токена из Redis (ошибка не блокирует основную операцию, логируем как warning)
	err = s.redisRepo.Del(ctx, resetTokenKey).Err()
	if err != nil {
		log.Printf("Warning: failed to delete reset token %s from Redis: %v\n", token, err)
	}

	// 8. Возвращение успешного ответа
	return &pb.ResetPasswordResponse{Success: true}, nil
}

func (s *AuthService) Logout(ctx context.Context, req *pb.LogoutRequest) (*pb.LogoutResponse, error) {
	refreshToken := req.GetRefreshToken()

	if refreshToken == "" {
		return nil, status.Errorf(codes.InvalidArgument, "Refresh token is required")
	}

	// 1. Поиск refresh токена в базе данных
	refreshTokenRecord, err := s.userRepo.GetRefreshToken(nil, refreshToken)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			log.Printf("Logout: refresh token %s not found, treating as successful logout", refreshToken)
			return &pb.LogoutResponse{Success: true}, nil // Успешный ответ
		}
		log.Printf("Failed to query refresh token %s: %v", refreshToken, err)
		return nil, status.Errorf(codes.Internal, "Failed to retrieve refresh token data")
	}

	// 2. Удаление refresh токена из базы данных
	err = s.userRepo.DeleteRefreshToken(nil, refreshTokenRecord.ID)
	if err != nil {
		log.Printf("Failed to delete refresh token with ID %d: %v", refreshTokenRecord.ID, err)
		return nil, status.Errorf(codes.Internal, "Failed to delete refresh token")
	}

	// 3. Возвращение успешного ответа
	return &pb.LogoutResponse{Success: true}, nil
}

func (s *AuthService) DeleteUser(ctx context.Context, req *pb.DeleteUserRequest) (*pb.DeleteUserResponse, error) {
	email := req.GetEmail()

	// Валидация email
	err := s.validator.Var(email, "required,email")
	if err != nil {
		// Клиентская ошибка - неверный ввод
		return nil, status.Errorf(codes.InvalidArgument, "invalid email format")
	}

	// 1. Получение пользователя по email
	user, err := s.userRepo.GetUserByEmail(nil, email)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, status.Errorf(codes.NotFound, "user not found")
		}
		log.Printf("Failed to query user by email %s: %v", email, err)
		return nil, status.Errorf(codes.Internal, "Failed to retrieve user data")
	}

	// 2. Удаление пользователя из базы данных
	err = s.userRepo.DeleteUser(nil, user.Email)
	if err != nil {
		log.Printf("Failed to delete user with email %s: %v", user.Email, err)
		return nil, status.Errorf(codes.Internal, "Failed to delete user")
	}

	// Успешное удаление
	return &pb.DeleteUserResponse{Success: true}, nil
}

// GetUsersByIDs реализует RPC метод для получения списка пользователей по их ID.
func (s *AuthService) GetUsersByIDs(ctx context.Context, req *pb.GetUsersByIDsRequest) (*pb.GetUsersByIDsResponse, error) {
	userIDs64 := req.GetUserIds()
	if len(userIDs64) == 0 {
		return &pb.GetUsersByIDsResponse{Users: []*pb.User{}}, nil
	}

	userIDs := make([]uint, len(userIDs64))
	for i, id := range userIDs64 {
		if id > uint64(^uint(0)) {
			log.Printf("GetUsersByIDs: User ID %d exceeds maximum uint value", id)
			return nil, status.Errorf(codes.InvalidArgument, "User ID %d is too large", id)
		}
		userIDs[i] = uint(id)
	}

	users, err := s.userRepo.ListUsersByIDs(nil, userIDs)

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			log.Printf("GetUsersByIDs: Couldn't find users: %v", err)
			return nil, status.Errorf(codes.NotFound, "Couldn't find users")
		}
		log.Printf("GetUsersByIDs: Failed to list users by IDs from DB: %v", err)
		return nil, status.Errorf(codes.Internal, "Failed to retrieve user data")
	}

	pbUsers := make([]*pb.User, 0, len(users))
	for _, user := range users {
		pbUsers = append(pbUsers, &pb.User{
			Id:       uint64(user.ID),
			Username: user.Username,
			Email:    user.Email,
			Image:    user.Image,
		})
	}

	return &pb.GetUsersByIDsResponse{Users: pbUsers}, nil
}

// GetUserByID реализует RPC метод для получения пользователя по его ID.
func (s *AuthService) GetUserByID(ctx context.Context, req *pb.GetUserByIDRequest) (*pb.GetUserByIDResponse, error) {
	// 1. Валидация входных данных
	userID64 := req.GetUserId()
	if userID64 == 0 {
		log.Printf("GetUserByID: Invalid argument: user_id is missing or invalid: %d", userID64)
		return nil, status.Errorf(codes.InvalidArgument, "User ID is required and must be greater than 0")
	}

	if userID64 > uint64(^uint(0)) {
		log.Printf("GetUserByID: User ID %d exceeds maximum uint value", userID64)
		return nil, status.Errorf(codes.InvalidArgument, "User ID %d is too large", userID64)
	}
	userID := uint(userID64)

	// 2. Получение пользователя из репозитория
	user, err := s.userRepo.GetUserByID(nil, userID)

	// 3. Обработка ошибок репозитория
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Если запись не найдена, возвращаем статус NotFound
			log.Printf("GetUserByID: User with ID %d not found: %v", userID, err)
			return nil, status.Errorf(codes.NotFound, "User with ID %d not found", userID)
		}
		// Для всех остальных ошибок репозитория возвращаем статус Internal
		log.Printf("GetUserByID: Failed to get user by ID %d from DB: %v", userID, err)
		return nil, status.Errorf(codes.Internal, "Failed to retrieve user data")
	}

	// 4. Формирование успешного ответа
	// Маппинг модели GORM models.User на protobuf сообщение pb.User
	pbUser := &pb.User{
		Id:       uint64(user.ID),
		Username: user.Username,
		Email:    user.Email,
		Image:    user.Image,
	}

	// Формирование и возврат ответа
	return &pb.GetUserByIDResponse{User: pbUser}, nil
}

// UpdateUsername реализует RPC метод для обновления имени пользователя.
func (s *AuthService) UpdateUsername(ctx context.Context, req *pb.UpdateUsernameRequest) (*pb.UpdateUsernameResponse, error) {
	userID := req.GetUserId()
	newUsername := req.GetNewUsername()

	if err := s.validator.Var(newUsername, "required,min=3,max=50"); err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "Invalid username")
	}

	_, err := s.userRepo.GetUserByID(nil, uint(userID))

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Если запись не найдена, возвращаем статус NotFound
			log.Printf("GetUserByID: User with ID %d not found: %v", userID, err)
			return nil, status.Errorf(codes.NotFound, "User with ID %d not found", userID)
		}
		// Для всех остальных ошибок репозитория возвращаем статус Internal
		log.Printf("GetUserByID: Failed to get user by ID %d from DB: %v", userID, err)
		return nil, status.Errorf(codes.Internal, "Failed to retrieve user data")
	}

	err = s.userRepo.UpdateUsername(nil, uint(userID), newUsername)
	if err != nil {
		log.Printf("Failed to update username for user %d: %v", userID, err)
		return nil, status.Errorf(codes.Internal, "Failed to update username")
	}

	return &pb.UpdateUsernameResponse{Success: true}, nil
}

// CheckPassword реализует RPC метод для проверки пароля пользователя.
func (s *AuthService) CheckPassword(ctx context.Context, req *pb.CheckPasswordRequest) (*pb.CheckPasswordResponse, error) {
	userID := req.GetUserId()
	password := req.GetPassword()

	err := s.userRepo.CheckPassword(nil, uint(userID), password)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, status.Errorf(codes.NotFound, "User not found")
		}
		if errors.Is(err, bcrypt.ErrMismatchedHashAndPassword) {
			return nil, status.Errorf(codes.Unauthenticated, "Invalid password")
		}
		log.Printf("Failed to check password for user %d: %v", userID, err)
		return nil, status.Errorf(codes.Internal, "Failed to check password")
	}
	return &pb.CheckPasswordResponse{Success: true}, nil
}

// UpdateEmail реализует RPC метод для попытки обновления почты пользователя.
func (s *AuthService) UpdateEmail(ctx context.Context, req *pb.UpdateEmailRequest) (*pb.UpdateEmailResponse, error) {
	userID := req.GetUserId()
	newEmail := req.GetNewEmail()

	if err := s.validator.Var(newEmail, "required,email"); err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "invalid email format: %v", err)
	}

	_, err := s.userRepo.GetUserByID(nil, uint(userID))

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Если запись не найдена, возвращаем статус NotFound
			log.Printf("GetUserByID: User with ID %d not found: %v", userID, err)
			return nil, status.Errorf(codes.NotFound, "User with ID %d not found", userID)
		}
		// Для всех остальных ошибок репозитория возвращаем статус Internal
		log.Printf("GetUserByID: Failed to get user by ID %d from DB: %v", userID, err)
		return nil, status.Errorf(codes.Internal, "Failed to retrieve user data")
	}

	verificationCode := utils.GenerateVerificationCode()

	redisKey := fmt.Sprintf("email_verification:%d:%s", userID, newEmail)
	expiryTime := time.Minute * 15

	// Save verification code to Redis
	err = s.redisRepo.Set(ctx, redisKey, verificationCode, expiryTime).Err()
	if err != nil {
		log.Printf("Error saving email verification code to Redis for user %d and email %s: %v", userID, newEmail, err)
		return nil, status.Errorf(codes.Internal, "failed to store verification code")
	}

	// Publish event to send verification code via RabbitMQ
	err = rabbitmq.PublishVerificationCode(newEmail, verificationCode)
	if err != nil {
		log.Printf("Error publishing verification code to RabbitMQ for email %s: %v", newEmail, err)
		return nil, status.Errorf(codes.Internal, "failed to send verification email")
	}

	// Successful initiation of email update
	return &pb.UpdateEmailResponse{Success: true}, nil
}

func (s *AuthService) VerifyNewEmailCode(ctx context.Context, req *pb.VerifyNewEmailCodeRequest) (*pb.VerifyNewEmailCodeResponse, error) {
	userID := req.GetUserId()
	newEmail := req.GetNewEmail()
	verificationCode := req.GetVerificationCode()

	storedCode, err := s.redisRepo.Get(ctx, fmt.Sprintf("email_verification:%d:%s", userID, newEmail)).Result()
	if err != nil {
		if errors.Is(err, redis.Nil) {
			return nil, status.Errorf(codes.InvalidArgument, "Invalid or expired verification code")
		}
		log.Printf("Failed to retrieve email verification code from Redis: %v", err)
		return nil, status.Errorf(codes.Internal, "Failed to verify email code")
	}

	if storedCode != verificationCode {
		return nil, status.Errorf(codes.InvalidArgument, "Invalid or expired verification code")
	}

	_, err = s.userRepo.GetUserByID(nil, uint(userID))

	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Если запись не найдена, возвращаем статус NotFound
			log.Printf("GetUserByID: User with ID %d not found: %v", userID, err)
			return nil, status.Errorf(codes.NotFound, "User with ID %d not found", userID)
		}
		// Для всех остальных ошибок репозитория возвращаем статус Internal
		log.Printf("GetUserByID: Failed to get user by ID %d from DB: %v", userID, err)
		return nil, status.Errorf(codes.Internal, "Failed to retrieve user data")
	}

	// Update email in the database
	err = s.userRepo.UpdateEmail(nil, uint(userID), newEmail)
	if err != nil {
		log.Printf("Failed to update email for user %d: %v", userID, err)
		return nil, status.Errorf(codes.Internal, "Failed to update email")
	}

	// Clean up the verification code from Redis
	s.redisRepo.Del(ctx, fmt.Sprintf("email_verification:%d:%s", userID, newEmail))

	return &pb.VerifyNewEmailCodeResponse{Success: true}, nil
}

func (s *AuthService) StartPasswordReset(ctx context.Context, req *pb.StartPasswordResetRequest) (*pb.StartPasswordResetResponse, error) {
	userID := req.GetUserId()

	user, err := s.userRepo.GetUserByID(nil, uint(userID))
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, status.Errorf(codes.NotFound, "user not found")
		}
		log.Printf("Failed to get user with ID %d: %v", userID, err)
		return nil, status.Errorf(codes.Internal, "failed to retrieve user data")
	}

	verificationCode := utils.GenerateVerificationCode()
	redisKey := fmt.Sprintf("password_change:%d", userID)
	expiryTime := time.Minute * 15 // Code valid for 15 minutes

	err = s.redisRepo.HSet(ctx, redisKey, map[string]interface{}{
		"user_id": userID,
		"code":    verificationCode,
		"status":  "code_sent",
	}).Err()
	if err != nil {
		log.Printf("Failed to store password reset data in Redis for user %d: %v", userID, err)
		return nil, status.Errorf(codes.Internal, "failed to store password reset data")
	}

	err = s.redisRepo.Expire(ctx, redisKey, expiryTime).Err()
	if err != nil {
		log.Printf("Warning: failed to set expiry for Redis key %s: %v", redisKey, err)
	}

	// Publish event to send password reset code via RabbitMQ
	err = rabbitmq.PublishVerificationCode(user.Email, verificationCode)
	if err != nil {
		log.Printf("Error publishing password reset code to RabbitMQ for email %s: %v", user.Email, err)
		return nil, status.Errorf(codes.Internal, "failed to send password reset email")
	}

	return &pb.StartPasswordResetResponse{Success: true}, nil
}

func (s *AuthService) VerifyPasswordResetCode(ctx context.Context, req *pb.VerifyPasswordResetCodeRequest) (*pb.VerifyPasswordResetCodeResponse, error) {
	userID := req.GetUserId()
	verificationCode := req.GetVerificationCode()

	redisKey := fmt.Sprintf("password_change:%d", userID)
	result, err := s.redisRepo.HGetAll(ctx, redisKey).Result()
	if err != nil {
		if errors.Is(err, redis.Nil) {
			return nil, status.Errorf(codes.InvalidArgument, "invalid or expired verification code")
		}
		log.Printf("Failed to retrieve password reset data from Redis for user %d: %v", userID, err)
		return nil, status.Errorf(codes.Internal, "failed to retrieve password reset data")
	}

	if result["code"] != verificationCode || result["status"] != "code_sent" {
		return nil, status.Errorf(codes.InvalidArgument, "invalid or expired verification code")
	}

	err = s.redisRepo.HSet(ctx, redisKey, "status", "code_verified").Err()
	if err != nil {
		log.Printf("Failed to update password reset status in Redis for user %d: %v", userID, err)
		return nil, status.Errorf(codes.Internal, "failed to update password reset status")
	}

	return &pb.VerifyPasswordResetCodeResponse{Success: true}, nil
}

func (s *AuthService) SetNewPassword(ctx context.Context, req *pb.SetNewPasswordRequest) (*pb.SetNewPasswordResponse, error) {
	userID := req.GetUserId()
	newPassword := req.GetNewPassword()

	if err := s.validator.Var(newPassword, "required,min=8"); err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "invalid new password format")
	}

	redisKey := fmt.Sprintf("password_change:%d", userID)
	result, err := s.redisRepo.HGetAll(ctx, redisKey).Result()
	if err != nil {
		if errors.Is(err, redis.Nil) {
			return nil, status.Errorf(codes.InvalidArgument, "invalid or expired verification code")
		}
		log.Printf("Failed to retrieve password reset data from Redis for user %d: %v", userID, err)
		return nil, status.Errorf(codes.Internal, "failed to retrieve password reset data")
	}

	if result["status"] != "code_verified" {
		return nil, status.Errorf(codes.InvalidArgument, "verification code not verified")
	}

	// Hash and update the new password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		log.Printf("Failed to hash new password for user %d: %v", userID, err)
		return nil, status.Errorf(codes.Internal, "failed to update password")
	}

	err = s.userRepo.UpdatePassword(nil, uint(userID), string(hashedPassword))
	if err != nil {
		log.Printf("Failed to update password for user %d: %v", userID, err)
		return nil, status.Errorf(codes.Internal, "failed to update password")
	}

	// Clean up the verification data from Redis
	err = s.redisRepo.Del(ctx, redisKey).Err()
	if err != nil {
		log.Printf("Warning: failed to delete password reset data from Redis for user %d: %v", userID, err)
	}

	return &pb.SetNewPasswordResponse{Success: true}, nil
}

func (s *AuthService) UpdateAvatar(ctx context.Context, req *pb.UpdateAvatarRequest) (*pb.UpdateAvatarResponse, error) {
	userID := req.GetUserId()
	image := req.GetImage()

	if len(image) == 0 {
		return nil, status.Errorf(codes.InvalidArgument, "Image data is required")
	}

	// TODO:  Call image service to upload the image and get the URL
	// imageUrl, err := s.mediaService.uploadImage(ctx, image)
	// if err != nil {
	//  return nil, err
	// }

	err := s.userRepo.UpdateAvatar(nil, uint(userID), "default")
	if err != nil {
		log.Printf("Failed to update avatar for user %d: %v", userID, err)
		return nil, status.Errorf(codes.Internal, "Failed to update avatar")
	}

	return &pb.UpdateAvatarResponse{Success: true}, nil
}
