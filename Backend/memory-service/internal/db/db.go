// Package db Description: Файл содержит функцию инициализации соединения с БД и миграции таблиц.
package db

import (
	"fmt"
	"log"
	"os"
	"time"

	"Rewind-memory-service/internal/app/models"

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
		log.Fatalf("Error while connecting to DB: %v", err)
	}

	sqlDB, err := db.DB()
	if err != nil {
		log.Fatalf("Error while getting *sql.DB: %v", err)
	}

	// Настройка параметров пула соединений
	sqlDB.SetMaxOpenConns(25)
	sqlDB.SetMaxIdleConns(25)
	sqlDB.SetConnMaxLifetime(5 * time.Minute)

	// Проверяем соединение
	if err := sqlDB.Ping(); err != nil {
		log.Fatalf("Couldn't connect to DB: %v", err)
	}

	log.Println("Connected to DB")

	err = db.AutoMigrate(&models.Memory{}, &models.MemoryTag{}, &models.Favourite{})
	if err != nil {
		log.Fatal("Tables migration error: ", err)
	}

	return db
}
