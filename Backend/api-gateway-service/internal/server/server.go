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

	httpSwagger "github.com/swaggo/http-swagger/v2"

	_ "Rewind-api-gateway-service/docs"

	"Rewind-api-gateway-service/internal/app/di"
)

type Server struct {
	httpServer *http.Server
}

func NewServer(dependencies *di.Dependencies) *Server {
	mux := http.NewServeMux()

	// Пример твоих API-обработчиков
	mux.HandleFunc("/api/auth/register", dependencies.AuthHandler.StartRegistration)
	mux.HandleFunc("/api/auth/verify-email", dependencies.AuthHandler.VerifyEmailCode)
	mux.HandleFunc("/api/auth/finish-register", dependencies.AuthHandler.SetPasswordAndUsername)
	mux.HandleFunc("/api/auth/login", dependencies.AuthHandler.Login)
	mux.HandleFunc("/api/auth/refresh", dependencies.AuthHandler.RefreshToken)
	mux.HandleFunc("/api/auth/forgot-password", dependencies.AuthHandler.ForgotPassword)
	mux.HandleFunc("/api/auth/reset-password", dependencies.AuthHandler.ResetPassword)
	mux.HandleFunc("/api/auth/logout", dependencies.AuthHandler.Logout)
	mux.HandleFunc("/api/auth/delete-user", dependencies.AuthHandler.DeleteUser)

	// Добавление обработчика для Swagger UI
	mux.Handle("/swagger/", httpSwagger.Handler(func(config *httpSwagger.Config) {
		config.URL = "/swagger/doc.json"
	}))

	port := os.Getenv("API_GATEWAY_PORT")
	if port == "" {
		port = "8080"
	}
	addr := fmt.Sprintf(":%s", port)

	return &Server{
		httpServer: &http.Server{
			Addr:              addr,
			Handler:           mux,
			ReadHeaderTimeout: 10 * time.Second,
		},
	}
}

func (s *Server) Run() error {
	log.Println("API Gateway listening on", s.httpServer.Addr)

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)

	go func() {
		if err := s.httpServer.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("Failed to start server: %v", err)
		}
	}()

	<-quit
	log.Println("Shutting down server...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := s.httpServer.Shutdown(ctx); err != nil {
		log.Printf("Server forced to shutdown: %v", err)
		return err
	}

	log.Println("Server gracefully stopped")
	return nil
}
