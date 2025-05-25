package di

import (
	auth "Rewind-api-gateway-service/clients/auth"
	"Rewind-api-gateway-service/clients/group"
	"Rewind-api-gateway-service/clients/memory" // Import the memory client
	"Rewind-api-gateway-service/internal/app/handlers"
	"Rewind-api-gateway-service/internal/app/services"
)

type Dependencies struct {
	AuthClient    *auth.AuthServiceClient
	AuthService   services.AuthServiceInterface
	AuthHandler   *handlers.AuthHandler
	GroupClient   *group.GroupServiceClient
	GroupService  services.GroupServiceInterface
	GroupHandler  *handlers.GroupHandler
	MemoryClient  *memory.MemoryServiceClient
	MemoryService services.MemoryServiceInterface
	MemoryHandler *handlers.MemoryHandler
}

func BuildDependencies() *Dependencies {
	// Initialize gRPC clients
	authClient, err := auth.NewAuthServiceClient()
	if err != nil {
		// In a real application, you might want to handle this error more gracefully
		panic("Failed to create auth client: " + err.Error())
	}

	groupClient, err := group.NewGroupServiceClient()
	if err != nil {
		panic("Failed to create group client: " + err.Error())
	}

	memoryClient, err := memory.NewMemoryServiceClient() // Initialize the memory client
	if err != nil {
		panic("Failed to create memory client: " + err.Error())
	}

	// Initialize service layer
	authService := services.NewAuthService(authClient)
	memoryService := services.NewMemoryService(memoryClient, authClient, groupClient)
	groupService := services.NewGroupService(groupClient, authClient)

	// Initialize handlers with injected dependencies
	authHandler := handlers.NewAuthHandler(authService)
	memoryHandler := handlers.NewMemoryHandler(memoryService)
	groupHandler := handlers.NewGroupHandler(groupService)

	return &Dependencies{
		AuthClient:    authClient,
		AuthService:   authService,
		AuthHandler:   authHandler,
		GroupClient:   groupClient,
		GroupService:  groupService,
		GroupHandler:  groupHandler,
		MemoryClient:  memoryClient,
		MemoryService: memoryService,
		MemoryHandler: memoryHandler,
	}
}

func (d *Dependencies) Close() {
	if d.AuthClient != nil {
		if err := d.AuthClient.Close(); err != nil {
			println("Error closing auth client:", err.Error())
		}
	}
	if d.GroupClient != nil {
		if err := d.GroupClient.Close(); err != nil {
			println("Error closing group client:", err.Error())
		}
	}
	if d.MemoryClient != nil { // Close the memory client
		if err := d.MemoryClient.Close(); err != nil {
			println("Error closing memory client:", err.Error())
		}
	}
}
