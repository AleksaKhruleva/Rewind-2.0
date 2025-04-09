// Package main Description: Точка входа в приложение.
// Здесь происходит инициализация базы данных, DI-контейнера и запуск gRPC сервера.
package main

import (
	"Rewind-auth-service/internal/app/di"
	"Rewind-auth-service/internal/app/repositories"
	"Rewind-auth-service/internal/db"
	"Rewind-auth-service/internal/server"
	"github.com/joho/godotenv"
	"log"
)

func main() {
	// Загружаем .env
	if err := godotenv.Load(); err != nil {
		log.Println("Can't load .env file") // Используем Println для необязательной загрузки
	}

	// Инициализируем базу данных
	database := db.InitDB()
	sqlDB, err := database.DB()
	if err != nil {
		log.Fatalf("Can't get *sql.DB from Gorm: %v", err)
	}
	defer func() {
		log.Println("Closing connection to DB")
		if err := sqlDB.Close(); err != nil {
			log.Printf("Error while closing connection to DB: %v", err)
		}
	}()

	redis, err := repositories.InitRedisClient()
	if err != nil {
		log.Fatalf("Can't connect to redis: %v", err)
	}

	// Создаем DI-контейнер
	dependencies := di.BuildDependencies(database, redis)

	// Создаем gRPC сервер
	grpcServer := server.NewGRPCServer()

	// Запускаем gRPC сервер
	if err := server.RunGRPCServer(grpcServer, dependencies.AuthService); err != nil {
		log.Fatalf("Error while starting gRPC server: %v", err)
	}
}
