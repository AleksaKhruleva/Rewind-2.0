package di

import (
	"Rewind-group-service/clients/auth"
	"Rewind-group-service/internal/app/repositories"
	"Rewind-group-service/internal/app/services"
	pb "Rewind-group-service/pkg/proto"
	"github.com/go-playground/validator/v10"

	"gorm.io/gorm"
)

type Dependencies struct {
	DB           *gorm.DB
	GroupRepo    repositories.Repository
	Validator    *validator.Validate
	GroupService pb.GroupServiceServer
	AuthClient   *auth.AuthServiceClient
}

func BuildDependencies(db *gorm.DB) Dependencies {
	authClient, err := auth.NewAuthServiceClient()
	if err != nil {
		// In a real application, you might want to handle this error more gracefully
		panic("Failed to create auth client: " + err.Error())
	}

	groupRepo := repositories.NewRepository(db)
	groupValidator := validator.New()
	groupService := services.NewGroupService(groupRepo, groupValidator, authClient)

	return Dependencies{
		DB:           db,
		GroupRepo:    groupRepo,
		GroupService: groupService,
	}
}

func (d *Dependencies) Close() {
	if d.AuthClient != nil {
		if err := d.AuthClient.Close(); err != nil {
			// Log the error, but don't necessarily panic in a defer
			println("Error closing auth client:", err.Error())
		}
	}
	// Close other clients here if needed
}
