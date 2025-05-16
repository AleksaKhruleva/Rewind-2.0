package services

import (
	"context"
	"errors"
	"fmt"
	"log"
	"math/rand"
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

	verificationCode := fmt.Sprintf("%04d", rand.Intn(10000)) // Генерирует случайное число от 0000 до 9999

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
