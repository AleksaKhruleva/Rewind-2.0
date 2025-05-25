package di

import (
	"Rewind-memory-service/clients/auth"
	"Rewind-memory-service/internal/app/repositories"
	"Rewind-memory-service/internal/app/services"
	pb "Rewind-memory-service/pkg/proto"
	"github.com/go-playground/validator/v10"

	"gorm.io/gorm"
)

type Dependencies struct {
	DB            *gorm.DB
	MemoryRepo    *repositories.MemoryRepository
	Validator     *validator.Validate
	MemoryService pb.MemoryServiceServer
	AuthClient    *auth.AuthServiceClient
}

func BuildDependencies(db *gorm.DB) Dependencies {
	authClient, err := auth.NewAuthServiceClient()
	if err != nil {
		// In a real application, you might want to handle this error more gracefully
		panic("Failed to create auth client: " + err.Error())
	}

	memoryRepo := repositories.NewMemoryRepository(db)
	memoryValidator := validator.New()
	memoryService := services.NewMemoryService(memoryRepo, memoryValidator, authClient)

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
	// Close other clients here if needed
}
