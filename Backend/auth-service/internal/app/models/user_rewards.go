package models

import (
	"gorm.io/gorm"
)

// UserRewards is a model that represents the relationship between a user and a reward
type UserRewards struct {
	gorm.Model
	UserID   uint `gorm:"index"`
	RewardID uint `gorm:"index"`
	User     User `gorm:"foreignKey:UserID"` // Связь с моделью User
}

type UserRewardDetailed struct {
	ID         uint
	Name       string
	Icon       string
	IsUnlocked bool
}
