// Package db Description: Файл содержит функцию инициализации соединения с БД и миграции таблиц.
package db

import (
	"errors"
	"fmt"
	"log"
	"os"
	"time"

	"Rewind-auth-service/internal/app/models"

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

	err = db.AutoMigrate(&models.User{}, &models.RefreshToken{}, &models.Rewards{}, &models.UserRewards{})
	if err != nil {
		log.Fatal("Tables migration error: ", err)
	}

	initDBRewards(db)

	return db
}

func initDBRewards(db *gorm.DB) {

	// Добавляем дефолтные награды, если они ещё не существуют
	defaultRewards := []models.Rewards{
		{
			Name:           "20 rewinds",
			Icon:           "RewindGradient",
			Condition:      "memories_added_count",
			ConditionValue: 20,
		},
		{
			Name:           "100 rewinds",
			Icon:           "RewindSakura",
			Condition:      "memories_added_count",
			ConditionValue: 2,
		},
		{
			Name:           "5 invites",
			Icon:           "RewindLazer",
			Condition:      "invited_members_count",
			ConditionValue: 5,
		},
		{
			Name:           "100 rolls",
			Icon:           "RewindForest",
			Condition:      "memories_viewed_count",
			ConditionValue: 100,
		},
		{
			Name:           "5 days",
			Icon:           "RewindSea",
			Condition:      "days_count",
			ConditionValue: 5,
		},
	}

	for _, reward := range defaultRewards {
		var existing models.Rewards
		err := db.Where("name = ?", reward.Name).First(&existing).Error
		if errors.Is(err, gorm.ErrRecordNotFound) {
			if err := db.Create(&reward).Error; err != nil {
				log.Printf("Failed to insert reward '%s': %v", reward.Name, err)
			} else {
				log.Printf("Inserted default reward: %s", reward.Name)
			}
		}
	}
}
