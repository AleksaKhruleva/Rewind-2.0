package main

import (
	"log"

	"Rewind-api-gateway-service/internal/app/di"
	"Rewind-api-gateway-service/internal/server"

	"github.com/joho/godotenv"

	_ "Rewind-api-gateway-service/docs"
)

// @title Rewind API Gateway
// @version 1.0
// @description This is the API Gateway for the Rewind application.
// @host localhost:8080
// @securityDefinitions.apikey ApiKeyAuth
// @in header
// @name Authorization
// @description Enter your access token in the format "Bearer <token>"
func main() {
	// Загружаем .env (если используете)
	if err := godotenv.Load(); err != nil {
		log.Println("Error loading .env file")
	}

	// Создаем DI-контейнер
	dependencies := di.BuildDependencies()
	defer dependencies.Close()

	// Создаем и запускаем сервер, передавая ему зависимости
	srv := server.NewServer(dependencies)
	if err := srv.Run(); err != nil {
		log.Println("Error running server:", err)
	}
}
