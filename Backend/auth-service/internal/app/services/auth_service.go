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
	registrationID := uuid.New().String()

	verificationCode := fmt.Sprintf("%04d", rand.Intn(10000)) // Генерирует случайное число от 0000 до 9999

	redisKey := fmt.Sprintf("registration:%s", registrationID)
	expiryTime := time.Minute * 15 // Код действителен в течение 15 минут (настройте по необходимости)

	err = s.redisRepo.HSet(ctx, redisKey, map[string]interface{}{
		"email": email,
		"code":  verificationCode,
	}).Err()
	if err != nil {
		return nil, fmt.Errorf("failed to store verification code in Redis: %w", err)
	}

	err = s.redisRepo.Expire(ctx, redisKey, expiryTime).Err()
	if err != nil {
		log.Printf("Warning: failed to set expiry for Redis key %s: %v\n", redisKey, err)
	}

	err = rabbitmq.PublishVerificationCode(email, verificationCode)
	if err != nil {
		log.Printf("Error publishing verification code to RabbitMQ: %v", err)
		return nil, fmt.Errorf("failed to publish verification code: %w", err)
	}

	return &pb.StartRegistrationResponse{RegistrationId: registrationID, Success: true}, nil
}

func (s *AuthService) VerifyEmailCode(ctx context.Context, req *pb.VerifyEmailCodeRequest) (*pb.VerifyEmailCodeResponse, error) {
	registrationID := req.GetRegistrationId()
	verificationCode := req.GetVerificationCode()

	redisKey := fmt.Sprintf("registration:%s", registrationID)

	registrationData, err := s.redisRepo.HGetAll(ctx, redisKey).Result()
	if err != nil {
		return nil, fmt.Errorf("invalid or expired registration ID: %w", err)
	}

	storedEmail, okEmail := registrationData["email"]
	storedCode, okCode := registrationData["code"]

	if !okEmail || !okCode {
		return nil, fmt.Errorf("registration data incomplete for ID: %s", registrationID)
	}

	if verificationCode != storedCode {
		return &pb.VerifyEmailCodeResponse{Success: false}, fmt.Errorf("invalid verification code")
	}

	verifiedKey := fmt.Sprintf("verified:%s", registrationID)
	expiryTime := time.Minute * 120

	err = s.redisRepo.SetEX(ctx, verifiedKey, storedEmail, expiryTime).Err()
	if err != nil {
		return nil, fmt.Errorf("failed to mark email as verified in Redis: %w", err)
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

	if err := s.validator.Var(password, "required,min=6"); err != nil {
		return nil, fmt.Errorf("invalid password: %w", err)
	}
	if err := s.validator.Var(username, "required,min=3,max=50"); err != nil {
		return nil, fmt.Errorf("invalid username: %w", err)
	}

	verifiedKey := fmt.Sprintf("verified:%s", registrationID)

	email, err := s.redisRepo.Get(ctx, verifiedKey).Result()
	if err != nil {
		return nil, fmt.Errorf("invalid or expired registration ID: %w", err)
	}

	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("failed to hash password: %w", err)
	}

	newUser := &models.User{
		Email:    email,
		Password: string(hashedPassword),
		Username: username,
	}

	// TODO delete delete method
	user, err := s.userRepo.GetDeletedUserByEmail(nil, email)
	if err == nil {
		log.Printf("Warning: user with email %s already existed, but was deleted, recreating", email)
		newUser.ID = user.ID
		err = s.userRepo.SaveDeleted(nil, newUser)
		if err != nil {
			return nil, fmt.Errorf("failed to save new user: %w", err)
		}
	} else {

		err = s.userRepo.CreateUser(nil, newUser)
		if err != nil {
			return nil, fmt.Errorf("failed to create user in database: %w", err)
		}

	}

	err = s.redisRepo.Del(ctx, verifiedKey).Err()
	if err != nil {
		log.Printf("Warning: failed to delete verification record from Redis for ID %s: %v\n", registrationID, err)
	}

	secretKey := os.Getenv("JWT_SECRET_KEY")
	if secretKey == "" {
		return nil, fmt.Errorf("JWT_SECRET_KEY environment variable not found")
	}

	accessToken, err := utils.GenerateAccessToken(newUser.ID, username, secretKey)
	if err != nil {
		return nil, fmt.Errorf("failed to generate access token")
	}

	refreshToken, err := utils.GenerateRefreshToken()
	if err != nil {
		return nil, fmt.Errorf("failed to generate refresh token")
	}

	err = s.userRepo.AddSession(nil, newUser.ID, refreshToken)
	if err != nil {
		return nil, fmt.Errorf("failed to add refresh token to database")
	}

	return &pb.SetPasswordAndUsernameResponse{AccessToken: accessToken, RefreshToken: refreshToken}, nil
}

func (s *AuthService) Login(ctx context.Context, req *pb.LoginRequest) (*pb.LoginResponse, error) {
	email := req.GetEmail()
	password := req.GetPassword()

	if err := s.validator.Var(password, "required"); err != nil {
		return nil, fmt.Errorf("password is required")
	}
	if err := s.validator.Var(email, "required,email"); err != nil {
		return nil, fmt.Errorf("email is required")
	}

	var user *models.User
	var err error

	// Попытка найти пользователя по email
	if err = s.validator.Var(email, "email"); err == nil {
		user, err = s.userRepo.GetUserByEmail(nil, email)
		if err != nil && !errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("failed to query user by email: %w", err)
		}
	}

	// Если пользователь не найден по email
	if user == nil {
		return nil, fmt.Errorf("invalid credentials")
	}

	// Проверка пароля
	err = bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password))
	if err != nil {
		return nil, fmt.Errorf("invalid credentials")
	}

	secretKey := os.Getenv("JWT_SECRET_KEY")
	if secretKey == "" {
		return nil, fmt.Errorf("JWT_SECRET_KEY environment variable not found")
	}

	accessToken, err := utils.GenerateAccessToken(user.ID, user.Username, secretKey)
	if err != nil {
		return nil, fmt.Errorf("failed to generate access token")
	}

	refreshToken, err := utils.GenerateRefreshToken()
	if err != nil {
		return nil, fmt.Errorf("failed to generate refresh token")
	}

	err = s.userRepo.AddSession(nil, user.ID, refreshToken)
	if err != nil {
		return nil, fmt.Errorf("failed to add refresh token to database")
	}

	return &pb.LoginResponse{AccessToken: accessToken, RefreshToken: refreshToken}, nil
}

func (s *AuthService) RefreshToken(ctx context.Context, req *pb.RefreshTokenRequest) (*pb.RefreshTokenResponse, error) {
	refreshToken := req.GetRefreshToken()

	if refreshToken == "" {
		return nil, fmt.Errorf("refresh token is required")
	}

	refreshTokenRecord, err := s.userRepo.GetRefreshToken(nil, refreshToken)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("invalid refresh token")
		}
		return nil, fmt.Errorf("failed to query refresh token: %w", err)
	}

	user, err := s.userRepo.GetUserByID(nil, refreshTokenRecord.UserID)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("user associated with refresh token not found")
		}
		return nil, fmt.Errorf("failed to query user: %w", err)
	}

	secretKey := os.Getenv("JWT_SECRET_KEY")
	if secretKey == "" {
		return nil, fmt.Errorf("JWT_SECRET_KEY environment variable not found")
	}

	newAccessToken, err := utils.GenerateAccessToken(user.ID, user.Username, secretKey)
	if err != nil {
		return nil, fmt.Errorf("failed to generate new access token")
	}

	return &pb.RefreshTokenResponse{AccessToken: newAccessToken}, nil
}

func (s *AuthService) ForgotPassword(ctx context.Context, req *pb.ForgotPasswordRequest) (*pb.ForgotPasswordResponse, error) {
	email := req.GetEmail()

	// 1. Валидация email
	if err := s.validator.Var(email, "required,email"); err != nil {
		return nil, fmt.Errorf("invalid email format: %w", err)
	}

	// 2. Проверка существования пользователя с таким email
	_, err := s.userRepo.GetUserByEmail(nil, email)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			log.Printf("ForgotPassword: user with email %s not found\n", email)
			// Важно решить, стоит ли сообщать пользователю, что email не найден,
			// чтобы избежать утечки информации о существовании email в системе.
			// Часто в таких случаях просто возвращают успех, чтобы не давать подсказок злоумышленникам.
			return &pb.ForgotPasswordResponse{Success: true}, nil
		}
		return nil, fmt.Errorf("failed to query user by email: %w", err)
	}

	// 3. Генерация уникального токена для сброса пароля
	resetToken := uuid.New().String()

	// 4. Сохранение токена в Redis с привязкой к email и временем истечения
	resetTokenKey := fmt.Sprintf("reset-token:%s", resetToken)
	expirationTime := time.Hour * 2 // Например, токен действует 2 часа
	err = s.redisRepo.SetEX(ctx, resetTokenKey, email, expirationTime).Err()
	if err != nil {
		return nil, fmt.Errorf("failed to save reset token to Redis: %w", err)
	}

	// 5. Формирование ссылки для сброса пароля
	frontendURL := os.Getenv("FRONTEND_URL")
	if frontendURL == "" {
		return nil, fmt.Errorf("FRONTEND_URL environment variable not found")
	}
	resetLink := fmt.Sprintf("%s/reset-password?token=%s", frontendURL, url.QueryEscape(resetToken))

	// 6. Отправка ссылки для сброса пароля в сервис уведомлений
	err = rabbitmq.PublishForgotPasswordEmail(email, resetLink)
	if err != nil {
		return nil, fmt.Errorf("failed to send email reset password: %w", err)
	}

	return &pb.ForgotPasswordResponse{Success: true}, nil
}

func (s *AuthService) ResetPassword(ctx context.Context, req *pb.ResetPasswordRequest) (*pb.ResetPasswordResponse, error) {
	token := req.GetToken()
	newPassword := req.GetNewPassword()

	// 1. Валидация нового пароля
	if err := s.validator.Var(newPassword, "required,min=6"); err != nil {
		return nil, fmt.Errorf("invalid new password: %w", err)
	}

	// 2. Формирование ключа Redis для поиска email по токену
	resetTokenKey := fmt.Sprintf("reset-token:%s", token)

	// 3. Получение email из Redis по токену
	email, err := s.redisRepo.Get(ctx, resetTokenKey).Result()
	if err != nil {
		if errors.Is(err, redis.Nil) {
			return nil, fmt.Errorf("invalid or expired reset token")
		}
		return nil, fmt.Errorf("failed to get email from Redis: %w", err)
	}

	// 4. Поиск пользователя в базе данных по email
	user, err := s.userRepo.GetUserByEmail(nil, email)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, fmt.Errorf("user associated with this token not found")
		}
		return nil, fmt.Errorf("failed to query user by email: %w", err)
	}

	// 5. Хеширование нового пароля
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(newPassword), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("failed to hash new password: %w", err)
	}

	// 6. Обновление пароля пользователя в базе данных
	user.Password = string(hashedPassword)
	err = s.userRepo.Save(nil, user)
	if err != nil {
		return nil, fmt.Errorf("failed to update user password in database: %w", err)
	}

	// 7. Удаление использованного токена из Redis
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
		return nil, fmt.Errorf("refresh token is required")
	}

	// 1. Поиск refresh токена в базе данных
	refreshTokenRecord, err := s.userRepo.GetRefreshToken(nil, refreshToken)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			log.Printf("Logout: refresh token %s not found\n", refreshToken)
			// В данном случае можно считать, что пользователь уже вышел из системы,
			// поэтому можно вернуть успешный ответ.
			return &pb.LogoutResponse{Success: true}, nil
		}
		return nil, fmt.Errorf("failed to query refresh token: %w", err)
	}

	// 2. Удаление refresh токена из базы данных
	err = s.userRepo.DeleteRefreshToken(nil, refreshTokenRecord.ID)
	if err != nil {
		return nil, fmt.Errorf("failed to delete refresh token from database: %w", err)
	}

	// 3. Возвращение успешного ответа
	return &pb.LogoutResponse{Success: true}, nil
}

func (s *AuthService) DeleteUser(ctx context.Context, req *pb.DeleteUserRequest) (*pb.DeleteUserResponse, error) {
	email := req.GetEmail()
	err := s.validator.Var(email, "required,email")
	if err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "invalid email format")
	}

	// 1. Получение пользователя по email
	user, err := s.userRepo.GetUserByEmail(nil, email)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, status.Errorf(codes.NotFound, "user not found")
		}
		return nil, status.Errorf(codes.Internal, "failed to query user by email: %v", err)
	}

	// 2. Удаление пользователя из базы данных
	err = s.userRepo.DeleteUser(nil, user.Email)
	if err != nil {
		return nil, status.Errorf(codes.Internal, "failed to delete user from database: %v", err)
	}
	return &pb.DeleteUserResponse{Success: true}, nil
}
