package services

import (
	"context"
	"fmt"
	"math/rand"
	"time"

	"Rewind/auth-service/internal/repositories"
	pb "Rewind/auth-service/pkg/proto"
	"github.com/go-playground/validator/v10"
	"github.com/google/uuid"
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

	// 1. Валидация email
	if err := s.validator.Var(email, "required,email"); err != nil {
		return nil, fmt.Errorf("invalid email format: %w", err)
	}

	// 2. Генерация уникального registration_id
	registrationID := uuid.New().String()

	// 3. Генерация кода верификации (например, 6-значный числовой код)
	verificationCode := fmt.Sprintf("%06d", rand.Intn(1000000)) // Генерирует случайное число от 000000 до 999999

	// 4. Сохранение кода верификации в Redis
	// Лучшая практика: использовать registrationID как ключ и хранить email и код как значения в hash.
	redisKey := fmt.Sprintf("registration:%s", registrationID)
	expiryTime := time.Minute * 15 // Код действителен в течение 15 минут (настройте по необходимости)

	err := s.redisRepo.HSet(ctx, redisKey, map[string]interface{}{
		"email": email,
		"code":  verificationCode,
	}).Err()
	if err != nil {
		return nil, fmt.Errorf("failed to store verification code in Redis: %w", err)
	}

	// Установка времени жизни для ключа Redis
	err = s.redisRepo.Expire(ctx, redisKey, expiryTime).Err()
	if err != nil {
		// Логируем ошибку, но не считаем ее критической, т.к. запись все равно есть
		fmt.Printf("Warning: failed to set expiry for Redis key %s: %v\n", redisKey, err)
	}

	// TODO: 5. Отправка кода верификации на email пользователя
	// Вам нужно интегрировать ваш сервис с сервисом отправки email (например, через отдельный Notification Service).
	fmt.Printf("Verification code for email %s: %s\n", email, verificationCode) // Временный вывод кода для демонстрации

	// 6. Возвращение registration_id
	return &pb.StartRegistrationResponse{RegistrationId: registrationID, Success: true}, nil
}
func (r *AuthService) VerifyEmailCode(context.Context, *pb.VerifyEmailCodeRequest) (*pb.VerifyEmailCodeResponse, error) {

}
func (r *AuthService) SetPasswordAndUsername(context.Context, *pb.SetPasswordAndUsernameRequest) (*pb.SetPasswordAndUsernameResponse, error) {

}
