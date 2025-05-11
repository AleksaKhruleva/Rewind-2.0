package models

import (
	"time"

	"gorm.io/gorm"
)

// GroupInvitation представляет модель приглашения в группу в базе данных
type GroupInvitation struct {
	gorm.Model
	GroupID         int64     `gorm:"not null;index"`  // ID группы, куда приглашают
	InvitationCode  string    `gorm:"unique;not null"` // Уникальный код приглашения
	CreatedByUserID int64     `gorm:"not null"`        // ID пользователя, создавшего приглашение (админ группы)
	ExpiresAt       time.Time `gorm:"not null"`        // Время истечения срока действия приглашения

	// Связь с группой
	Group Group `gorm:"foreignKey:GroupID"`
}
