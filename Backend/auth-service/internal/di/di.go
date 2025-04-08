package di

import (
	"Rewind/auth-service/internal/repositories"
	"Rewind/auth-service/internal/services"
	pb "Rewind/auth-service/pkg/proto"
	"gorm.io/gorm"
)

type Dependencies struct {
	DB          *gorm.DB
	UserRepo    repositories.UserRepositoryInterface
	AuthService pb.AuthServiceServer
}

func BuildDependencies(db *gorm.DB) Dependencies {
	userRepo := repositories.NewUserRepository(db)
	authService := services.NewAuthService(userRepo)

	return Dependencies{
		DB:          db,
		UserRepo:    userRepo,
		AuthService: authService,
	}
}
