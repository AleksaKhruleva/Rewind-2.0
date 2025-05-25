package repositories

import (
	"context"
	"errors"
	"time"

	"Rewind-group-service/internal/app/models"
	"gorm.io/gorm"
)

// gormRepository реализует интерфейс Repository с использованием GORM
type gormRepository struct {
	db *gorm.DB // Основное соединение с базой данных
}

// NewRepository создает новый экземпляр gormRepository
func NewRepository(db *gorm.DB) Repository {
	return &gormRepository{db: db}
}

// Group возвращает реализацию репозитория для групп
func (r *gormRepository) Group() GroupRepository {
	return &gormGroupRepository{db: r.db}
}

// GroupMember возвращает реализацию репозитория для участников групп
func (r *gormRepository) GroupMember() GroupMemberRepository {
	return &gormGroupMemberRepository{db: r.db}
}

// GroupInvitation возвращает реализацию репозитория для приглашений
func (r *gormRepository) GroupInvitation() GroupInvitationRepository {
	return &gormGroupInvitationRepository{db: r.db}
}

// BeginTx начинает новую транзакцию.
func (r *gormRepository) BeginTx(ctx context.Context) (*gorm.DB, error) {
	tx := r.db.WithContext(ctx).Begin()
	if tx.Error != nil {
		return nil, tx.Error
	}
	return tx, nil
}

// CommitTx завершает транзакцию.
func (r *gormRepository) CommitTx(tx *gorm.DB) error {
	// Проверяем, что tx не nil, хотя при правильном использовании BeginTx он не должен быть nil
	if tx == nil {
		return errors.New("cannot commit nil transaction")
	}
	return tx.Commit().Error
}

// RollbackTx откатывает транзакцию. Безопасно для вызова даже после успешного коммита или другого отката.
func (r *gormRepository) RollbackTx(tx *gorm.DB) error {
	// Проверяем, что tx не nil
	if tx == nil {
		return nil // Откатывать нечего
	}
	return tx.Rollback().Error
}

// --- Реализации конкретных репозиториев ---

type gormGroupRepository struct {
	db *gorm.DB
}

func (r *gormGroupRepository) getDB(tx *gorm.DB) *gorm.DB {
	if tx != nil {
		return tx
	}
	return r.db
}

func (r *gormGroupRepository) CreateGroup(ctx context.Context, tx *gorm.DB, group *models.Group) error {
	db := r.getDB(tx).WithContext(ctx)
	return db.Create(group).Error
}

func (r *gormGroupRepository) GetGroupByID(ctx context.Context, tx *gorm.DB, groupID uint) (*models.Group, error) {
	db := r.getDB(tx).WithContext(ctx)
	var group models.Group
	result := db.First(&group, groupID)
	if result.Error != nil {
		return nil, result.Error
	}
	return &group, nil
}

func (r *gormGroupRepository) UpdateGroup(ctx context.Context, tx *gorm.DB, group *models.Group) error {
	db := r.getDB(tx).WithContext(ctx)
	return db.Save(group).Error
}

func (r *gormGroupRepository) DeleteGroup(ctx context.Context, tx *gorm.DB, groupID uint) error {
	db := r.getDB(tx).WithContext(ctx)
	result := db.Unscoped().Delete(&models.Group{}, groupID)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (r *gormGroupRepository) ListGroups(ctx context.Context, tx *gorm.DB) ([]models.Group, error) {
	db := r.getDB(tx).WithContext(ctx)
	var groups []models.Group
	result := db.Find(&groups)
	if result.Error != nil {
		return nil, result.Error
	}
	return groups, nil
}

func (r *gormGroupRepository) CheckGroupExists(ctx context.Context, tx *gorm.DB, groupID uint) (bool, error) {
	db := r.getDB(tx).WithContext(ctx)
	var count int64
	result := db.Model(&models.Group{}).Where("id = ?", groupID).Count(&count)
	if result.Error != nil {
		return false, result.Error
	}
	return count > 0, nil
}

type gormGroupMemberRepository struct {
	db *gorm.DB
}

func (r *gormGroupMemberRepository) getDB(tx *gorm.DB) *gorm.DB {
	if tx != nil {
		return tx
	}
	return r.db
}

func (r *gormGroupMemberRepository) CreateMember(ctx context.Context, tx *gorm.DB, member *models.GroupMember) error {
	db := r.getDB(tx).WithContext(ctx)
	return db.Create(member).Error
}

func (r *gormGroupMemberRepository) GetMemberByID(ctx context.Context, tx *gorm.DB, memberID uint) (*models.GroupMember, error) {
	db := r.getDB(tx).WithContext(ctx)
	var member models.GroupMember
	result := db.First(&member, memberID)
	if result.Error != nil {
		return nil, result.Error
	}
	return &member, nil
}

func (r *gormGroupMemberRepository) GetMemberByGroupAndUser(ctx context.Context, tx *gorm.DB, groupID uint, userID uint) (*models.GroupMember, error) {
	db := r.getDB(tx).WithContext(ctx)
	var member models.GroupMember
	result := db.Where("group_id = ? AND user_id = ?", groupID, userID).First(&member)
	if result.Error != nil {
		return nil, result.Error
	}
	return &member, nil
}

func (r *gormGroupMemberRepository) ListMembersByGroup(ctx context.Context, tx *gorm.DB, groupID uint) ([]models.GroupMember, error) {
	db := r.getDB(tx).WithContext(ctx)
	var members []models.GroupMember
	result := db.Where("group_id = ?", groupID).Find(&members)
	if result.Error != nil {
		return nil, result.Error
	}
	return members, nil
}

func (r *gormGroupMemberRepository) DeleteMember(ctx context.Context, tx *gorm.DB, memberID uint) error {
	db := r.getDB(tx).WithContext(ctx)
	result := db.Delete(&models.GroupMember{}, memberID)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (r *gormGroupMemberRepository) DeleteMemberByGroupAndUser(ctx context.Context, tx *gorm.DB, groupID uint, userID uint) error {
	db := r.getDB(tx).WithContext(ctx)
	result := db.Where("group_id = ? AND user_id = ?", groupID, userID).Delete(&models.GroupMember{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (r *gormGroupMemberRepository) UpdateMemberIsAdmin(ctx context.Context, tx *gorm.DB, memberID uint, isAdmin bool) error {
	db := r.getDB(tx).WithContext(ctx)
	result := db.Model(&models.GroupMember{}).Where("id = ?", memberID).Update("is_admin", isAdmin)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (r *gormGroupMemberRepository) ListGroupsByUserID(ctx context.Context, tx *gorm.DB, userID uint) ([]models.Group, error) {
	db := r.getDB(tx).WithContext(ctx)
	var groups []models.Group
	result := db.
		Joins("JOIN group_members ON groups.id = group_members.group_id").
		Where("group_members.user_id = ?", userID).
		Find(&groups)
	if result.Error != nil {
		return nil, result.Error
	}
	return groups, nil
}

func (r *gormGroupMemberRepository) CheckMemberExists(ctx context.Context, tx *gorm.DB, groupID uint, userID uint) (bool, error) {
	db := r.getDB(tx).WithContext(ctx)
	var count int64
	result := db.Model(&models.GroupMember{}).Where("group_id = ? AND user_id = ?", groupID, userID).Count(&count)
	if result.Error != nil {
		return false, result.Error
	}
	return count > 0, nil
}

func (r *gormGroupMemberRepository) HardDeleteMembersByGroup(ctx context.Context, tx *gorm.DB, groupID uint) error {
	db := r.getDB(tx).WithContext(ctx)
	result := db.Unscoped().Where("group_id = ?", groupID).Delete(&models.GroupMember{})
	if result.Error != nil {
		return result.Error
	}
	return nil
}

func (r *gormGroupMemberRepository) CountMembersByGroup(ctx context.Context, tx *gorm.DB, groupID uint) (int64, error) {
	db := r.getDB(tx).WithContext(ctx)
	var count int64
	// Count только активных участников (deleted_at IS NULL)
	result := db.Model(&models.GroupMember{}).Where("group_id = ?", groupID).Count(&count)
	if result.Error != nil {
		return 0, result.Error
	}
	return count, nil
}

func (r *gormGroupMemberRepository) FindAnyOtherMemberByGroup(ctx context.Context, tx *gorm.DB, groupID uint, excludeUserID uint) (*models.GroupMember, error) {
	db := r.getDB(tx).WithContext(ctx)
	var member models.GroupMember
	result := db.Where("group_id = ? AND user_id != ?", groupID, excludeUserID).First(&member)
	if result.Error != nil {
		return nil, result.Error
	}
	return &member, nil
}

func (r *gormGroupMemberRepository) CheckUserInGroup(ctx context.Context, tx *gorm.DB, userID uint, groupID uint) (bool, bool, error) {
	db := r.getDB(tx).WithContext(ctx)
	var groupMember models.GroupMember
	result := db.
		Where("user_id = ? AND group_id = ?", userID, groupID).
		First(&groupMember)

	if result.Error != nil {
		if errors.Is(result.Error, gorm.ErrRecordNotFound) {
			return false, false, nil // Пользователь не найден в группе
		}
		return false, false, result.Error
	}

	return true, groupMember.IsAdmin, nil
}

type gormGroupInvitationRepository struct {
	db *gorm.DB
}

func (r *gormGroupInvitationRepository) getDB(tx *gorm.DB) *gorm.DB {
	if tx != nil {
		return tx
	}
	return r.db
}

func (r *gormGroupInvitationRepository) CreateInvitation(ctx context.Context, tx *gorm.DB, invitation *models.GroupInvitation) error {
	db := r.getDB(tx).WithContext(ctx)
	return db.Create(invitation).Error
}

func (r *gormGroupInvitationRepository) GetInvitationByCode(ctx context.Context, tx *gorm.DB, invitationCode string) (*models.GroupInvitation, error) {
	db := r.getDB(tx).WithContext(ctx)
	var invitation models.GroupInvitation
	result := db.Where("invitation_code = ?", invitationCode).First(&invitation)
	if result.Error != nil {
		return nil, result.Error
	}
	return &invitation, nil
}

func (r *gormGroupInvitationRepository) DeleteInvitation(ctx context.Context, tx *gorm.DB, invitationID uint) error {
	db := r.getDB(tx).WithContext(ctx)
	result := db.Delete(&models.GroupInvitation{}, invitationID)
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (r *gormGroupInvitationRepository) DeleteInvitationByCode(ctx context.Context, tx *gorm.DB, invitationCode string) error {
	db := r.getDB(tx).WithContext(ctx)
	result := db.Where("invitation_code = ?", invitationCode).Delete(&models.GroupInvitation{})
	if result.Error != nil {
		return result.Error
	}
	if result.RowsAffected == 0 {
		return gorm.ErrRecordNotFound
	}
	return nil
}

func (r *gormGroupInvitationRepository) ListInvitationsByGroup(ctx context.Context, tx *gorm.DB, groupID uint) ([]models.GroupInvitation, error) {
	db := r.getDB(tx).WithContext(ctx)
	var invitations []models.GroupInvitation
	result := db.Where("group_id = ? AND expires_at > ?", groupID, time.Now()).Find(&invitations)
	if result.Error != nil {
		return nil, result.Error
	}
	return invitations, nil
}

func (r *gormGroupInvitationRepository) CheckInvitationExistsByCode(ctx context.Context, tx *gorm.DB, invitationCode string) (bool, error) {
	db := r.getDB(tx).WithContext(ctx)
	var count int64
	result := db.Model(&models.GroupInvitation{}).Where("invitation_code = ? AND expires_at > ?", invitationCode, time.Now()).Count(&count)
	if result.Error != nil {
		return false, result.Error
	}
	return count > 0, nil
}

func (r *gormGroupInvitationRepository) HardDeleteInvitationsByGroup(ctx context.Context, tx *gorm.DB, groupID uint) error {
	db := r.getDB(tx).WithContext(ctx)
	// Unscoped() для жесткого удаления, Where по group_id
	result := db.Unscoped().Where("group_id = ?", groupID).Delete(&models.GroupInvitation{})
	if result.Error != nil {
		return result.Error
	}
	return nil
}
