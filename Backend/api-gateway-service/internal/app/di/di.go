package di

import (
	"Rewind-api-gateway-service/clients/auth"
	"Rewind-api-gateway-service/clients/group"
	"Rewind-api-gateway-service/internal/app/handlers"
	"Rewind-api-gateway-service/internal/app/services"
)

type Dependencies struct {
	AuthClient   *auth.AuthServiceClient
	AuthService  services.AuthServiceInterface
	AuthHandler  *handlers.AuthHandler
	GroupClient  *group.GroupServiceClient
	GroupService services.GroupServiceInterface
	GroupHandler *handlers.GroupHandler
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

	groupClient, err := group.NewGroupServiceClient()
	if err != nil {
		panic("Failed to create group client: " + err.Error())
	}

	groupService := services.NewGroupService(groupClient, authClient)
	groupHandler := handlers.NewGroupHandler(groupService)

	return &Dependencies{
		AuthClient:   authClient,
		AuthService:  authService,
		AuthHandler:  authHandler,
		GroupClient:  groupClient,
		GroupService: groupService,
		GroupHandler: groupHandler,
	}
}

func (d *Dependencies) Close() {
	if d.AuthClient != nil {
		if err := d.AuthClient.Close(); err != nil {
			// Log the error, but don't necessarily panic in a defer
			println("Error closing auth client:", err.Error())
		}
	}
	if d.GroupClient != nil {
		if err := d.GroupClient.Close(); err != nil {
			// Log the error, but don't necessarily panic in a defer
			println("Error closing group client:", err.Error())
		}
	}
}
