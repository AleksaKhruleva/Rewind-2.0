// Package main Description: Точка входа в приложение.
// Здесь происходит инициализация базы данных, DI-контейнера и запуск gRPC сервера.
package main

import (
	"log"

	"github.com/joho/godotenv"

	"Rewind-media-service/internal/app/di"
	"Rewind-media-service/internal/server"
)

func main() {
	// Загружаем .env
	if err := godotenv.Load(); err != nil {
		log.Println("Can't load .env file") // Используем Println для необязательной загрузки
	}

	// Создаем DI-контейнер
	dependencies := di.BuildDependencies()

	// Создаем gRPC сервер
	grpcServer := server.NewGRPCServer()

	// Запускаем gRPC сервер
	if err := server.RunGRPCServer(grpcServer, dependencies.MediaService); err != nil {
		log.Fatalf("Error while starting gRPC server: %v", err)
	}
}
