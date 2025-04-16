package di

import (
	"Rewind-api-gateway-service/clients/auth"
	"Rewind-api-gateway-service/internal/app/handlers"
	"Rewind-api-gateway-service/internal/app/services"
)

type Dependencies struct {
	AuthClient  *auth.AuthServiceClient
	AuthService services.AuthServiceInterface
	AuthHandler *handlers.AuthHandler
	// Add other service clients and handlers here as needed (e.g., GroupClient, GroupService, GroupHandler)
}

func BuildDependencies() *Dependencies {
	// Initialize gRPC clients
	authClient, err := auth.NewAuthServiceClient()
	if err != nil {
		// In a real application, you might want to handle this error more gracefully
		panic("Failed to create auth client: " + err.Error())
	}

	// Initialize service layer
	authService := services.NewAuthService(authClient)

	// Initialize handlers with injected dependencies
	authHandler := handlers.NewAuthHandler(authService)

	return &Dependencies{
		AuthClient:  authClient,
		AuthService: authService,
		AuthHandler: authHandler,
		// Initialize other clients and handlers here
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
