package repositories

import (
	"Rewind/auth-service/internal/models"
	"gorm.io/gorm"
)

type UserRepositoryInterface interface {
	FindByUsername(tx *gorm.DB, username string) (*models.User, error)
	FindById(tx *gorm.DB, userID uint) (*models.User, error)
	Save(tx *gorm.DB, user *models.User) error
}

type UserRepository struct {
	db *gorm.DB
}

func NewUserRepository(db *gorm.DB) UserRepositoryInterface {
	return &UserRepository{db: db}
}

func (r *UserRepository) FindByUsername(tx *gorm.DB, username string) (*models.User, error) {
	if tx == nil {
		tx = r.db
	}
	var user models.User
	result := tx.Where("username = ?", username).First(&user)
	return &user, result.Error
}

func (r *UserRepository) FindById(tx *gorm.DB, userID uint) (*models.User, error) {
	if tx == nil {
		tx = r.db
	}
	var user models.User
	result := tx.Where("id = ?", userID).First(&user)
	return &user, result.Error
}

func (r *UserRepository) Save(tx *gorm.DB, user *models.User) error {
	if tx == nil {
		tx = r.db
	}
	return tx.Save(user).Error
}
