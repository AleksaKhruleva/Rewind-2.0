package di

import (
	"github.com/go-playground/validator/v10"

	"Rewind-group-service/clients/auth"
	"Rewind-group-service/clients/media"
	"Rewind-group-service/internal/app/repositories"
	"Rewind-group-service/internal/app/services"
	pb "Rewind-group-service/pkg/proto"

	"gorm.io/gorm"
)

type Dependencies struct {
	DB           *gorm.DB
	GroupRepo    repositories.Repository
	Validator    *validator.Validate
	GroupService pb.GroupServiceServer
	AuthClient   *auth.AuthServiceClient
	MediaClient  *media.MediaServiceClient
}

func BuildDependencies(db *gorm.DB) Dependencies {
	authClient, err := auth.NewAuthServiceClient()
	if err != nil {
		// In a real application, you might want to handle this error more gracefully
		panic("Failed to create auth client: " + err.Error())
	}
	mediaClient, err := media.NewMediaServiceClient()
	if err != nil {
		panic("Failed to create media client: " + err.Error())
	}

	groupRepo := repositories.NewRepository(db)
	groupValidator := validator.New()
	groupService := services.NewGroupService(groupRepo, groupValidator, authClient, mediaClient)

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
	if d.MediaClient != nil {
		if err := d.MediaClient.Close(); err != nil {
			println("Error closing media client:", err.Error())
		}
	}
}
