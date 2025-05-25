package models

import "gorm.io/gorm"

// Favourite представляет модель для таблицы "favourites".
type Favourite struct {
	gorm.Model
	MemoryID uint `gorm:"not null;index"`
	UserID   uint `gorm:"not null;index"`
}
