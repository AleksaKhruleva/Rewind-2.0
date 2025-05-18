package server

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"github.com/go-chi/chi/v5"            // Import the chi router
	"github.com/go-chi/chi/v5/middleware" // Import chi middleware

	httpSwagger "github.com/swaggo/http-swagger/v2"

	_ "Rewind-api-gateway-service/docs" // Import generated swagger docs

	"Rewind-api-gateway-service/internal/app/di" // Your Dependency Injection setup
	// Import your authentication middleware package
	// "Rewind-api-gateway-service/internal/pkg/middleware/auth"
)

// Server represents the HTTP server for the API Gateway.
type Server struct {
	httpServer *http.Server
}

// NewServer creates a new Server instance with configured router and middleware.
func NewServer(dependencies *di.Dependencies) *Server {
	// Use chi.NewRouter() instead of http.NewServeMux()
	mux := chi.NewRouter()

	// --- Global Middleware ---
	// Add middleware that applies to all routes.
	mux.Use(middleware.RequestID)                // Adds a unique request ID to the context
	mux.Use(middleware.Logger)                   // Logs request details
	mux.Use(middleware.Recoverer)                // Recovers from panics and logs the stack trace
	mux.Use(middleware.Timeout(5 * time.Second)) // Sets a timeout for requests

	// TODO: Add your custom authentication middleware here.
	// This middleware should extract the token, validate it, and add the user ID to the request context.
	// mux.Use(auth.Authenticate) // Assuming your auth middleware is in internal/pkg/middleware/auth

	// --- Define Routes ---

	// Auth routes (usually don't require authentication middleware, or have specific handling)
	mux.Group(func(r chi.Router) {
		// Routes within this group might have different middleware or no auth middleware
		// For example, registration and login typically don't require a valid token
		// r.Use(optionalAuthMiddleware) // Or a specific middleware for these routes

		r.Post("/api/auth/register", dependencies.AuthHandler.StartRegistration)
		r.Post("/api/auth/verify-email", dependencies.AuthHandler.VerifyEmailCode)
		r.Post("/api/auth/finish-register", dependencies.AuthHandler.SetPasswordAndUsername)
		r.Post("/api/auth/login", dependencies.AuthHandler.Login)
		r.Post("/api/auth/refresh", dependencies.AuthHandler.RefreshToken)
		r.Post("/api/auth/forgot-password", dependencies.AuthHandler.ForgotPassword)
		r.Post("/api/auth/reset-password", dependencies.AuthHandler.ResetPassword)
		r.Post("/api/auth/logout", dependencies.AuthHandler.Logout)
		r.Delete("/api/auth/delete-user", dependencies.AuthHandler.DeleteUser)
		r.Get("/api/users/{id}", dependencies.AuthHandler.GetUserByID)
	})

	// Group routes (typically require authentication middleware)
	mux.Group(func(r chi.Router) {
		// Add middleware specific to this group, e.g., requiring authentication
		// r.Use(auth.RequireAuthentication) // Assuming you have a middleware to check for authenticated user ID in context

		// Use chi's specific HTTP method handlers (Post, Get, Put, Delete)
		r.Post("/api/groups", dependencies.GroupHandler.CreateGroup)
		r.Get("/api/groups/{id}", dependencies.GroupHandler.GetGroup)
		r.Put("/api/groups/{id}", dependencies.GroupHandler.UpdateGroup)
		r.Delete("/api/groups/{id}", dependencies.GroupHandler.DeleteGroup) // Assuming DELETE method
		r.Get("/api/groups/{id}/members", dependencies.GroupHandler.ListGroupMembers)
		r.Delete("/api/groups/{group_id}/members/{user_id}", dependencies.GroupHandler.RemoveGroupMember) // Assuming DELETE method
		r.Post("/api/groups/{id}/invitations", dependencies.GroupHandler.CreateGroupInvitation)           // Assuming POST method
		r.Post("/api/invitations/{code}/accept", dependencies.GroupHandler.AcceptGroupInvitation)         // Assuming POST method
		// Note: ListUserGroups path might be better under /api/users/{user_id}/groups
		r.Get("/api/users/{user_id}/groups", dependencies.GroupHandler.ListUserGroups) // Assuming GET method
	})

	// TODO: Add routes for other services (Memory, Media, Stats, Notification)
	// Example for Memory routes:
	// mux.Group(func(r chi.Router) {
	// 	r.Use(auth.RequireAuthentication) // Memory routes likely require authentication
	// 	r.Post("/api/groups/{group_id}/memories", dependencies.MemoryHandler.CreateMemory)
	// 	r.Get("/api/memories/{id}", dependencies.MemoryHandler.GetMemory)
	// 	r.Get("/api/groups/{group_id}/memories", dependencies.MemoryHandler.ListMemories) // Filtered list
	// 	r.Get("/api/groups/{group_id}/memories/random", dependencies.MemoryHandler.GetRandomMemory)
	// 	r.Put("/api/memories/{id}", dependencies.MemoryHandler.UpdateMemory)
	// 	r.Delete("/api/memories/{id}", dependencies.MemoryHandler.DeleteMemory)
	// 	r.Post("/api/memories/{id}/reactions", dependencies.MemoryHandler.AddReaction) // Assuming POST for adding reaction
	// 	r.Delete("/api/memories/{id}/reactions", dependencies.MemoryHandler.RemoveReaction) // Assuming DELETE
	// 	r.Post("/api/memories/{id}/favorite", dependencies.MemoryHandler.AddFavorite) // Assuming POST for adding favorite
	// 	r.Delete("/api/memories/{id}/favorite", dependencies.MemoryHandler.RemoveFavorite) // Assuming DELETE
	// 	r.Get("/api/groups/{group_id}/memories/geolocated", dependencies.MemoryHandler.ListGeolocatedMemories)
	// })

	// Add handler for Swagger UI
	mux.Handle("/swagger/*", httpSwagger.Handler(httpSwagger.URL("/swagger/doc.json")))

	port := os.Getenv("API_GATEWAY_PORT")
	if port == "" {
		port = "8080" // Default port
	}
	addr := fmt.Sprintf(":%s", port)

	return &Server{
		httpServer: &http.Server{
			Addr:              addr,
			Handler:           mux,              // Use the chi router as the main handler
			ReadHeaderTimeout: 10 * time.Second, // Good practice to set timeouts
		},
	}
}

// Run starts the HTTP server and handles graceful shutdown.
func (s *Server) Run() error {
	log.Println("API Gateway listening on", s.httpServer.Addr)

	// Channel to listen for OS signals for graceful shutdown
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM) // Listen for SIGINT and SIGTERM

	// Start the HTTP server in a goroutine
	go func() {
		if err := s.httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			// Log fatal error if server fails to start (and it's not a graceful shutdown error)
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	// Block until a signal is received
	<-quit
	log.Println("Shutting down server...")

	// Create a context with a timeout for graceful shutdown
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel() // Release resources associated with the context

	// Attempt to gracefully shut down the server
	if err := s.httpServer.Shutdown(ctx); err != nil {
		// Log if server shutdown fails
		log.Printf("Server forced to shutdown: %v", err)
		return err // Return the error
	}

	log.Println("Server gracefully stopped")
	return nil // Return nil on successful shutdown
}
