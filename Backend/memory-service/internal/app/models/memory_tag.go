package models

import "gorm.io/gorm"

// MemoryTag представляет модель для таблицы "memory_tags".
type MemoryTag struct {
	gorm.Model
	MemoryID uint   `gorm:"not null;index"`
	Tag      string `gorm:"not null"`
}
