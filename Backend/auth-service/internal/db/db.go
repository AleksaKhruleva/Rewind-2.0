// Package db Description: Файл содержит функцию инициализации соединения с БД и миграции таблиц.
package db

import (
	"Rewind/auth-service/internal/app/models"
	"fmt"
	"log"
	"os"
	"time"

	"gorm.io/driver/postgres"
	"gorm.io/gorm"
)

// InitDB инициализирует соединение с БД
func InitDB() *gorm.DB {
	dbHost := os.Getenv("DB_HOST")
	dbPort := os.Getenv("DB_PORT")
	dbUser := os.Getenv("DB_USER")
	dbPassword := os.Getenv("DB_PASSWORD")
	dbName := os.Getenv("DB_NAME")

	dsn := fmt.Sprintf("host=%s port=%s user=%s password=%s dbname=%s sslmode=disable",
		dbHost, dbPort, dbUser, dbPassword, dbName)
	db, err := gorm.Open(postgres.Open(dsn), &gorm.Config{})
	if err != nil {
		log.Fatalf("Ошибка подключения к БД: %v", err)
	}

	sqlDB, err := db.DB()
	if err != nil {
		log.Fatalf("Ошибка получения *sql.DB: %v", err)
	}

	// Настройка параметров пула соединений
	sqlDB.SetMaxOpenConns(25)
	sqlDB.SetMaxIdleConns(25)
	sqlDB.SetConnMaxLifetime(5 * time.Minute)

	// Проверяем соединение
	if err := sqlDB.Ping(); err != nil {
		log.Fatalf("Не удалось подключиться к БД: %v", err)
	}

	log.Println("Подключение к БД установлено")

	err = db.AutoMigrate(&models.User{}, &models.RefreshToken{})
	if err != nil {
		log.Fatal("Ошибка миграции таблиц: ", err)
	}

	return db
}
