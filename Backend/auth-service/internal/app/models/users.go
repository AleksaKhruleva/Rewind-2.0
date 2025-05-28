package models

import "gorm.io/gorm"

type User struct {
	gorm.Model
	Email    string `gorm:"unique;not null"`
	Password string `gorm:"not null"`
	Username string `gorm:"not null"`
	Image    string

	MemoriesAddedCount  uint `gorm:"default:0"`
	InvitedMembersCount uint `gorm:"default:0"`
	MemoriesViewedCount uint `gorm:"default:0"`
}
