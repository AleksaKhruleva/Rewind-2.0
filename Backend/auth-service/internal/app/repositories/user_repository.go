package repositories

import (
	"fmt"
	"time"

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
	UserAddMemory(tx *gorm.DB, userID uint) error
	UserAddMember(tx *gorm.DB, userID uint) error
	UserViewedMemories(tx *gorm.DB, userID, count uint) error
	GetUserAchievements(tx *gorm.DB, userID uint) ([]models.UserRewardDetailed, error)
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

func (r *UserRepository) UserAddMemory(tx *gorm.DB, userID uint) error {
	if tx == nil {
		tx = r.db
	}
	result := tx.Model(&models.User{}).Where("id = ?", userID).Update("memories_added_count", gorm.Expr("memories_added_count + 1"))
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (r *UserRepository) UserAddMember(tx *gorm.DB, userID uint) error {
	if tx == nil {
		tx = r.db
	}
	result := tx.Model(&models.User{}).Where("id = ?", userID).Update("invited_members_count", gorm.Expr("invited_members_count + 1"))
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (r *UserRepository) UserViewedMemories(tx *gorm.DB, userID, count uint) error {
	if tx == nil {
		tx = r.db
	}
	result := tx.Model(&models.User{}).
		Where("id = ?", userID).
		Update("memories_viewed_count", gorm.Expr("memories_viewed_count + ?", count))
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (r *UserRepository) GetUserAchievements(tx *gorm.DB, userID uint) ([]models.UserRewardDetailed, error) {
	if tx == nil {
		tx = r.db
	}

	var user models.User
	if err := tx.First(&user, userID).Error; err != nil {
		return nil, fmt.Errorf("failed to find user: %w", err)
	}

	var allRewards []models.Rewards
	if err := tx.Find(&allRewards).Error; err != nil {
		return nil, fmt.Errorf("failed to fetch rewards: %w", err)
	}

	var userRewards []models.UserRewards
	if err := tx.Where("user_id = ?", userID).Find(&userRewards).Error; err != nil {
		return nil, fmt.Errorf("failed to fetch user rewards: %w", err)
	}

	receivedRewardIDs := make(map[uint]bool)
	for _, ur := range userRewards {
		receivedRewardIDs[ur.RewardID] = true
	}

	var rewardList []models.UserRewardDetailed

	for _, reward := range allRewards {
		var statValue uint

		switch reward.Condition {
		case "memories_added_count":
			statValue = user.MemoriesAddedCount
		case "invited_members_count":
			statValue = user.InvitedMembersCount
		case "memories_viewed_count":
			statValue = user.MemoriesViewedCount
		case "days_count":
			statValue = uint(time.Since(user.CreatedAt).Hours() / 24)
		default:
			continue
		}

		isUnlocked := receivedRewardIDs[reward.ID] || statValue >= reward.ConditionValue

		// Если условие выполнено, но награда ещё не выдана — выдаём
		if statValue >= reward.ConditionValue && !receivedRewardIDs[reward.ID] {
			newUserReward := models.UserRewards{
				UserID:   userID,
				RewardID: reward.ID,
			}
			if err := tx.Create(&newUserReward).Error; err != nil {
				return nil, fmt.Errorf("failed to assign reward to user: %w", err)
			}
			receivedRewardIDs[reward.ID] = true
		}

		rewardList = append(rewardList, models.UserRewardDetailed{
			ID:         reward.ID,
			Name:       reward.Name,
			Icon:       reward.Icon,
			IsUnlocked: isUnlocked,
		})
	}

	return rewardList, nil
}
