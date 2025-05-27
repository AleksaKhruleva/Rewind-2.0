package di

import (
	"regexp"

	"github.com/go-playground/validator/v10"
	"github.com/go-redis/redis/v8"
	"gorm.io/gorm"

	"Rewind-auth-service/clients/media"
	"Rewind-auth-service/internal/app/repositories"
	"Rewind-auth-service/internal/app/services"
	pb "Rewind-auth-service/pkg/proto"
)

type Dependencies struct {
	DB          *gorm.DB
	UserRepo    repositories.UserRepositoryInterface
	RedisRepo   repositories.RedisRepositoryInterface
	Validator   *validator.Validate
	AuthService pb.AuthServiceServer
	MediaClient *media.MediaServiceClient
}

func BuildDependencies(db *gorm.DB, redis *redis.Client) Dependencies {
	userRepo := repositories.NewUserRepository(db)
	redisRepo := repositories.NewRedisRepository(redis)
	authValidator := validator.New()

	authValidator.RegisterValidation("securepwd", func(fl validator.FieldLevel) bool {
		password := fl.Field().String()
		if len(password) < 6 {
			return false
		}
		if !regexp.MustCompile(`[A-Z]`).MatchString(password) {
			return false
		}
		if !regexp.MustCompile(`\d`).MatchString(password) {
			return false
		}
		return true
	})

	mediaClient, err := media.NewMediaServiceClient()
	if err != nil {
		panic("Failed to create media client: " + err.Error())
	}

	authService := services.NewAuthService(userRepo, authValidator, redisRepo, mediaClient)

	return Dependencies{
		DB:          db,
		UserRepo:    userRepo,
		AuthService: authService,
	}
}

func (d *Dependencies) Close() {
	if d.MediaClient != nil {
		if err := d.MediaClient.Close(); err != nil {
			// Log the error, but don't necessarily panic in a defer
			println("Error closing media client:", err.Error())
		}
	}
}
