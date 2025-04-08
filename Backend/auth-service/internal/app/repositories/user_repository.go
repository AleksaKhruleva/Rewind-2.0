package repositories

import (
	"Rewind/auth-service/internal/app/models"
	"fmt"
	"gorm.io/gorm"
)

type UserRepositoryInterface interface {
	GetUserByUsername(tx *gorm.DB, username string) (*models.User, error)
	GetUserByEmail(tx *gorm.DB, email string) (*models.User, error)
	GetUserByID(tx *gorm.DB, userID uint) (*models.User, error)
	AddSession(tx *gorm.DB, userID uint, token string) error
	CreateUser(tx *gorm.DB, user *models.User) error
	Save(tx *gorm.DB, user *models.User) error
	GetRefreshToken(tx *gorm.DB, refreshToken string) (*models.RefreshToken, error)
}

type UserRepository struct {
	db *gorm.DB
}

func NewUserRepository(db *gorm.DB) UserRepositoryInterface {
	return &UserRepository{db: db}
}

func (r *UserRepository) GetUserByUsername(tx *gorm.DB, username string) (*models.User, error) {
	if tx == nil {
		tx = r.db
	}
	var user models.User
	result := tx.Where("username = ?", username).First(&user)
	return &user, result.Error
}
func (r *UserRepository) GetUserByEmail(tx *gorm.DB, email string) (*models.User, error) {
	if tx == nil {
		tx = r.db
	}
	var user models.User
	result := tx.Where("email = ?", email).First(&user)
	return &user, result.Error
}

func (r *UserRepository) GetUserByID(tx *gorm.DB, userID uint) (*models.User, error) {
	if tx == nil {
		tx = r.db
	}
	var user models.User
	result := tx.Where("id = ?", userID).First(&user)
	return &user, result.Error
}

func (r *UserRepository) AddSession(tx *gorm.DB, userID uint, token string) error {
	if tx == nil {
		tx = r.db
	}
	if token == "" {
		return fmt.Errorf("token is required")
	}

	refreshToken := models.RefreshToken{
		UserID: userID,
		Token:  token,
	}
	return tx.Create(&refreshToken).Error
}

func (r *UserRepository) CreateUser(tx *gorm.DB, user *models.User) error {
	if tx == nil {
		tx = r.db
	}
	return tx.Create(user).Error
}

func (r *UserRepository) Save(tx *gorm.DB, user *models.User) error {
	if tx == nil {
		tx = r.db
	}
	return tx.Save(user).Error
}

func (r *UserRepository) GetRefreshToken(tx *gorm.DB, refreshToken string) (*models.RefreshToken, error) {
	if tx == nil {
		tx = r.db
	}
	var token models.RefreshToken
	result := tx.Where("refresh_token = ?", refreshToken).First(&token)
	return &token, result.Error
}
