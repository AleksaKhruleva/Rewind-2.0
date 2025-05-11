package models

import (
	"gorm.io/gorm"
)

// Group представляет модель группы в базе данных
type Group struct {
	gorm.Model
	Name        string `gorm:"not null"`
	Image       string // URL изображения аватара группы (может быть null)
	AdminUserID int64  `gorm:"not null;index"` // ID пользователя-администратора (ссылка на пользователя из Auth-Service)

	// Связь с участниками группы
	Members []GroupMember `gorm:"foreignKey:GroupID"`
	// Связь с приглашениями
	Invitations []GroupInvitation `gorm:"foreignKey:GroupID"`

	// Воспоминания (Memories) хранятся в отдельном микросервисе (memory-service).
	// GroupService управляет привязкой воспоминаний к группе и их статусом через memory-service.
	// Прямых связей с моделями воспоминаний здесь нет.
}
