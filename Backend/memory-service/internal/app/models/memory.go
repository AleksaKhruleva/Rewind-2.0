package models

import (
	"gorm.io/gorm"
)

// Memory представляет модель для таблицы "memories".
type Memory struct {
	gorm.Model
	GroupID    uint    `gorm:"not null;index"`
	UserID     uint    `gorm:"not null;index"`
	MediaType  string  `gorm:"not null"`
	MediaURL   string  `gorm:"not null"`
	Latitude   float64 // Широта
	Longitude  float64 // Долгота
	MusicID    string
	Offset     float64 // Смещение в секундах
	Duration   float64 // Длительность в секундах
	MemoryTags []MemoryTag
	Favourites []Favourite
}

// MemoryDetailed представляет структуру для возврата данных из запроса ListMemoriesByGroupDetailed.
// Она содержит все необходимые данные из Memory, строку тегов и булево значение, указывающее, добавлено ли воспоминание в избранное текущим пользователем.
type MemoryDetailed struct {
	Memory
	Tags        string   `gorm:"column:tags"` // Строка тегов из базы данных
	TagsArray   []string // Слайс тегов для использования в Go
	IsFavourite bool     `gorm:"column:is_favourite"`
}
