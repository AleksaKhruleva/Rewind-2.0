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

	_ "Rewind-api-gateway-service/docs"

	"Rewind-api-gateway-service/internal/app/di"
	cm "Rewind-api-gateway-service/internal/app/middleware"
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

	// This middleware should extract the token, validate it, and add the user ID to the request context.
	mux.Use(cm.AuthMiddleware)

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
		r.Post("/api/users/logout", dependencies.AuthHandler.Logout)
		r.Delete("/api/users/delete-user", dependencies.AuthHandler.DeleteUser)
		r.Get("/api/users/{id}", dependencies.AuthHandler.GetUserByID)
		r.Patch("/api/users/username", dependencies.AuthHandler.UpdateUsername)
		r.Post("/api/users/check-password", dependencies.AuthHandler.CheckPassword)
		r.Post("/api/users/email/start-change", dependencies.AuthHandler.UpdateEmail)
		r.Patch("/api/users/email/verify-change", dependencies.AuthHandler.VerifyNewEmailCode)
		r.Patch("/api/users/avatar", dependencies.AuthHandler.UpdateAvatar)
		r.Delete("/api/users/avatar", dependencies.AuthHandler.DeleteAvatar)
		r.Post("/api/users/password/reset/start", dependencies.AuthHandler.StartPasswordReset)
		r.Post("/api/users/password/reset/verify", dependencies.AuthHandler.VerifyPasswordResetCode)
		r.Patch("/api/users/password/reset/set", dependencies.AuthHandler.SetNewPassword)
		r.Get("/api/users/achievements", dependencies.AuthHandler.GetUserAchievements)
	})

	// Group routes (typically require authentication middleware)
	mux.Group(func(r chi.Router) {
		// Add middleware specific to this group, e.g., requiring authentication
		// r.Use(auth.RequireAuthentication) // Assuming you have a middleware to check for authenticated user ID in context

		r.Post("/api/groups", dependencies.GroupHandler.CreateGroup)
		r.Get("/api/groups/{group_id}", dependencies.GroupHandler.GetGroup)
		r.Put("/api/groups/{group_id}", dependencies.GroupHandler.UpdateGroup)
		r.Delete("/api/groups/{group_id}", dependencies.GroupHandler.DeleteGroup)
		r.Delete("/api/groups/{group_id}/avatar", dependencies.GroupHandler.DeleteGroupAvatar)
		r.Get("/api/groups/{group_id}/members", dependencies.GroupHandler.ListGroupMembers)
		r.Delete("/api/groups/{group_id}/members/{user_id}", dependencies.GroupHandler.RemoveGroupMember)
		r.Post("/api/groups/{group_id}/invitations", dependencies.GroupHandler.CreateGroupInvitation)
		r.Post("/api/invitations/{code}/accept", dependencies.GroupHandler.AcceptGroupInvitation)
		r.Get("/api/users/groups", dependencies.GroupHandler.ListUserGroups)
		r.Patch("/api/groups/{group_id}/memories/viewed", dependencies.GroupHandler.UpdateMemoriesViewed)
	})

	// Memory routes (typically require authentication middleware)
	mux.Group(func(r chi.Router) {
		r.Post("/api/groups/{groupId}/memories", dependencies.MemoryHandler.CreateMemory)
		r.Get("/api/groups/{groupId}/memories/{memoryId}", dependencies.MemoryHandler.GetMemory)
		r.Delete("/api/groups/{groupId}/memories/{memoryId}", dependencies.MemoryHandler.DeleteMemory)
		r.Get("/api/groups/{groupId}/memories", dependencies.MemoryHandler.ListMemoriesByGroup)
		r.Get("/api/groups/{groupId}/memories/random", dependencies.MemoryHandler.ListMemoriesByGroupWithFilters)
		r.Post("/api/groups/{groupId}/memories/{memoryId}/tags/{tag}", dependencies.MemoryHandler.CreateMemoryTag)
		r.Delete("/api/groups/{groupId}/memories/{memoryId}/tags/{tag}", dependencies.MemoryHandler.DeleteMemoryTag)
		r.Get("/api/groups/{groupId}/memories/{memoryId}/tags", dependencies.MemoryHandler.ListMemoryTagsByMemoryID)
		r.Post("/api/groups/{groupId}/memories/{memoryId}/favourite", dependencies.MemoryHandler.CreateFavourite)
		r.Delete("/api/groups/{groupId}/memories/{memoryId}/favourite", dependencies.MemoryHandler.DeleteFavourite)
	})

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
