package models

import (
	"gorm.io/gorm"
)

// Rewards model
type Rewards struct {
	gorm.Model
	Name           string `gorm:"type:varchar(255);not null"`
	Icon           string `gorm:"type:varchar(255);not null"`
	Condition      string `gorm:"type:varchar(255);not null"`
	ConditionValue uint   `gorm:"type:int;not null"`
}
