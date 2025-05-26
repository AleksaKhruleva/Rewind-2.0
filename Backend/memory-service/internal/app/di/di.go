package di

import (
	"github.com/go-playground/validator/v10"

	"Rewind-memory-service/clients/auth"
	"Rewind-memory-service/clients/media"
	"Rewind-memory-service/internal/app/repositories"
	"Rewind-memory-service/internal/app/services"
	pb "Rewind-memory-service/pkg/proto"

	"gorm.io/gorm"
)

type Dependencies struct {
	DB            *gorm.DB
	MemoryRepo    *repositories.MemoryRepository
	Validator     *validator.Validate
	MemoryService pb.MemoryServiceServer
	AuthClient    *auth.AuthServiceClient
	MediaClient   *media.MediaServiceClient
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

	memoryRepo := repositories.NewMemoryRepository(db)
	memoryValidator := validator.New()
	memoryService := services.NewMemoryService(memoryRepo, memoryValidator, authClient, mediaClient)

	return Dependencies{
		DB:            db,
		MemoryRepo:    memoryRepo,
		MemoryService: memoryService,
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
			// Log the error, but don't necessarily panic in a defer
			println("Error closing media client:", err.Error())
		}
	}
}
