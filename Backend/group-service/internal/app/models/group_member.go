package models

import (
	"gorm.io/gorm"
)

// GroupMember представляет модель участника группы в базе данных
type GroupMember struct {
	gorm.Model
	GroupID uint `gorm:"not null;index:idx_group_user,unique"` // ID группы
	UserID  uint `gorm:"not null;index:idx_group_user,unique"` // ID пользователя (ссылка на пользователя из Auth-Service)
	IsAdmin bool `gorm:"default:false"`                        // Является ли участник администратором

	// Счетчики активности участника в группе, связанные с воспоминаниями.
	// Сами воспоминания хранятся в memory-service и могут быть связаны с группой
	// и/или участником через соответствующие поля в моделях memory-service.
	// Эти поля здесь - метаданные, управляемые GroupService.
	MemoriesAddedCount  uint `gorm:"default:0"`
	MemoriesViewedCount uint `gorm:"default:0"`

	// Связь с группой
	Group Group `gorm:"foreignKey:GroupID"`
}
