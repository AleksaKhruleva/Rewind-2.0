package models

import (
	"gorm.io/gorm"
)

// RefreshToken model
type RefreshToken struct {
	gorm.Model
	UserID uint   `gorm:"not null;index"` // Внешний ключ на таблицу users
	Token  string `gorm:"type:text;not null;uniqueIndex"`
	User   User   `gorm:"foreignKey:UserID"` // Связь с моделью User
}
