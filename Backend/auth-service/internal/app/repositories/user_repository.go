package repositories

import (
	"fmt"

	"golang.org/x/crypto/bcrypt"

	"gorm.io/gorm"

	"Rewind-auth-service/internal/app/models"
)

type UserRepositoryInterface interface {
	GetUserByUsername(tx *gorm.DB, username string) (*models.User, error)
	GetUserByEmail(tx *gorm.DB, email string) (*models.User, error)
	GetUserByID(tx *gorm.DB, userID uint) (*models.User, error)
	AddSession(tx *gorm.DB, userID uint, token string) error
	CreateUser(tx *gorm.DB, user *models.User) error
	Save(tx *gorm.DB, user *models.User) error
	GetRefreshToken(tx *gorm.DB, refreshToken string) (*models.RefreshToken, error)
	DeleteRefreshToken(tx *gorm.DB, id uint) error
	DeleteUserRefreshTokens(tx *gorm.DB, userID uint) error
	GetDeletedUserByEmail(tx *gorm.DB, email string) (*models.User, error)
	SaveDeleted(tx *gorm.DB, user *models.User) error
	DeleteUser(tx *gorm.DB, email string) error
	ListUsersByIDs(tx *gorm.DB, userIDs []uint) ([]*models.User, error)
	UpdateUsername(tx *gorm.DB, userID uint, newUsername string) error
	UpdateEmail(tx *gorm.DB, userID uint, newEmail string) error
	UpdatePassword(tx *gorm.DB, userID uint, newPassword string) error
	UpdateAvatar(tx *gorm.DB, userID uint, image string) error
	CheckPassword(tx *gorm.DB, userID uint, password string) error
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
	result := tx.Where("token = ?", refreshToken).First(&token)
	return &token, result.Error
}

func (r *UserRepository) DeleteRefreshToken(tx *gorm.DB, id uint) error {
	if tx == nil {
		tx = r.db
	}
	return tx.Unscoped().Delete(&models.RefreshToken{}, "id = ?", id).Error
}

func (r *UserRepository) DeleteUserRefreshTokens(tx *gorm.DB, userID uint) error {
	if tx == nil {
		tx = r.db
	}
	return tx.Unscoped().Delete(&models.RefreshToken{}, "user_id = ?", userID).Error
}

func (r *UserRepository) GetDeletedUserByEmail(tx *gorm.DB, email string) (*models.User, error) {
	if tx == nil {
		tx = r.db
	}
	var user models.User
	result := tx.Unscoped().Where("email = ?", email).First(&user)
	return &user, result.Error
}

func (r *UserRepository) SaveDeleted(tx *gorm.DB, user *models.User) error {
	if tx == nil {
		tx = r.db
	}
	return tx.Unscoped().Save(user).Error
}

func (r *UserRepository) DeleteUser(tx *gorm.DB, email string) error {
	if tx == nil {
		tx = r.db
	}
	return tx.Delete(&models.User{}, "email = ?", email).Error
}

func (r *UserRepository) ListUsersByIDs(tx *gorm.DB, userIDs []uint) ([]*models.User, error) {
	if tx == nil {
		tx = r.db
	}
	var users []*models.User
	result := tx.Unscoped().Where("id IN (?)", userIDs).Find(&users)
	return users, result.Error
}

func (r *UserRepository) UpdateUsername(tx *gorm.DB, userID uint, newUsername string) error {
	if tx == nil {
		tx = r.db
	}
	return tx.Model(&models.User{}).Where("id = ?", userID).Update("username", newUsername).Error
}

func (r *UserRepository) CheckPassword(tx *gorm.DB, userID uint, password string) error {
	if tx == nil {
		tx = r.db
	}
	var user models.User
	err := tx.Where("id = ?", userID).First(&user).Error
	if err != nil {
		return err
	}

	err = bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password))
	return err
}

func (r *UserRepository) UpdateEmail(tx *gorm.DB, userID uint, newEmail string) error {
	if tx == nil {
		tx = r.db
	}
	return tx.Model(&models.User{}).Where("id = ?", userID).Update("email", newEmail).Error
}

func (r *UserRepository) UpdatePassword(tx *gorm.DB, userID uint, newPassword string) error {
	if tx == nil {
		tx = r.db
	}
	return tx.Model(&models.User{}).Where("id = ?", userID).Update("password", newPassword).Error
}

func (r *UserRepository) UpdateAvatar(tx *gorm.DB, userID uint, image string) error {
	if tx == nil {
		tx = r.db
	}
	return tx.Model(&models.User{}).Where("id = ?", userID).Update("image", image).Error
}
