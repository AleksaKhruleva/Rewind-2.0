package di

import (
	"Rewind/auth-service/internal/app/repositories"
	"Rewind/auth-service/internal/app/services"
	pb "Rewind/auth-service/pkg/proto"
	"github.com/go-playground/validator/v10"
	"github.com/go-redis/redis/v8"
	"gorm.io/gorm"
)

type Dependencies struct {
	DB          *gorm.DB
	UserRepo    repositories.UserRepositoryInterface
	RedisRepo   repositories.RedisRepositoryInterface
	Validator   *validator.Validate
	AuthService pb.AuthServiceServer
}

func BuildDependencies(db *gorm.DB, redis *redis.Client) Dependencies {
	userRepo := repositories.NewUserRepository(db)
	redisRepo := repositories.NewRedisRepository(redis)
	authValidator := validator.New()
	authService := services.NewAuthService(userRepo, authValidator, redisRepo)

	return Dependencies{
		DB:          db,
		UserRepo:    userRepo,
		AuthService: authService,
	}
}
