package repositories

import (
	"context"

	"gorm.io/gorm"

	"Rewind-group-service/internal/app/models"
)

// GroupRepository определяет методы для работы с группами в базе данных.
// Методы, принимающие *gorm.DB tx, могут выполняться как в рамках транзакции, так и вне ее (если tx == nil).
type GroupRepository interface {
	// CreateGroup создает новую группу в базе данных.
	CreateGroup(ctx context.Context, tx *gorm.DB, group *models.Group) error

	// GetGroupByID находит группу по её уникальному идентификатору.
	// Возвращает ErrRecordNotFound если группа не найдена.
	GetGroupByID(ctx context.Context, tx *gorm.DB, groupID uint) (*models.Group, error)

	// UpdateGroup обновляет информацию о существующей группе.
	UpdateGroup(ctx context.Context, tx *gorm.DB, group *models.Group) error

	// DeleteGroup жестко удаляет группу по её уникальному идентификатору.
	// Возвращает ErrRecordNotFound если группа не найдена.
	DeleteGroup(ctx context.Context, tx *gorm.DB, groupID uint) error

	// ListGroups возвращает список групп.
	// TODO: Добавить параметры для фильтрации (например, по admin_user_id), пагинации и сортировки.
	ListGroups(ctx context.Context, tx *gorm.DB) ([]models.Group, error)

	// CheckGroupExists проверяет существование активной группы по ID.
	CheckGroupExists(ctx context.Context, tx *gorm.DB, groupID uint) (bool, error)
}

// GroupMemberRepository определяет методы для работы с участниками групп в базе данных.
// Методы, принимающие *gorm.DB tx, могут выполняться как в рамках транзакции, так и вне ее (если tx == nil).
type GroupMemberRepository interface {
	// CreateMember добавляет нового участника в группу.
	CreateMember(ctx context.Context, tx *gorm.DB, member *models.GroupMember) error

	// GetMemberByID находит запись об участнике группы по её уникальному идентификатору.
	// Возвращает ErrRecordNotFound если запись не найдена.
	GetMemberByID(ctx context.Context, tx *gorm.DB, memberID uint) (*models.GroupMember, error)

	// GetMemberByGroupAndUser находит запись об участии пользователя в конкретной группе.
	// Возвращает ErrRecordNotFound если пользователь не является участником группы.
	GetMemberByGroupAndUser(ctx context.Context, tx *gorm.DB, groupID uint, userID uint) (*models.GroupMember, error)

	// ListMembersByGroup возвращает список всех участников конкретной группы.
	// TODO: Добавить параметры для пагинации и сортировки.
	ListMembersByGroup(ctx context.Context, tx *gorm.DB, groupID uint) ([]models.GroupMember, error)

	// DeleteMember удаляет запись об участии пользователя в группе по её уникальному идентификатору.
	// Возвращает ErrRecordNotFound если запись не найдена.
	DeleteMember(ctx context.Context, tx *gorm.DB, memberID uint) error

	// DeleteMemberByGroupAndUser мягко удаляет запись об участии пользователя в группе по ID группы и пользователя.
	// Возвращает ErrRecordNotFound если запись не найдена.
	DeleteMemberByGroupAndUser(ctx context.Context, tx *gorm.DB, groupID uint, userID uint) error

	// UpdateMemberIsAdmin обновляет статус администратора участника группы.
	// Возвращает ErrRecordNotFound если запись об участии не найдена.
	UpdateMemberIsAdmin(ctx context.Context, tx *gorm.DB, memberID uint, isAdmin bool) error

	// ListGroupsByUserID возвращает список групп, в которых состоит пользователь.
	// TODO: Добавить параметры для пагинации и сортировки.
	ListGroupsByUserID(ctx context.Context, tx *gorm.DB, userID uint) ([]models.Group, error)

	// CheckMemberExists проверяет существование активного участия пользователя в группе.
	CheckMemberExists(ctx context.Context, tx *gorm.DB, groupID uint, userID uint) (bool, error)

	// HardDeleteMembersByGroup жестко удаляет все записи участников для указанной группы.
	HardDeleteMembersByGroup(ctx context.Context, tx *gorm.DB, groupID uint) error

	// CountMembersByGroup подсчитывает количество активных участников в указанной группе.
	CountMembersByGroup(ctx context.Context, tx *gorm.DB, groupID uint) (int64, error)

	// FindAnyOtherMemberByGroup находит любого другого активного участника в группе, исключая указанного.
	// Возвращает ErrRecordNotFound если других участников нет.
	FindAnyOtherMemberByGroup(ctx context.Context, tx *gorm.DB, groupID uint, excludeUserID uint) (*models.GroupMember, error)

	// CheckUserInGroup проверяет есть ли пользователь в группе и является ли он админом
	CheckUserInGroup(ctx context.Context, tx *gorm.DB, userID uint, groupID uint) (bool, bool, error)
}

// GroupInvitationRepository определяет методы для работы с приглашениями в группы в базе данных.
// Методы, принимающие *gorm.DB tx, могут выполняться как в рамках транзакции, так и вне ее (если tx == nil).
type GroupInvitationRepository interface {
	// CreateInvitation создает новое приглашение в группу.
	CreateInvitation(ctx context.Context, tx *gorm.DB, invitation *models.GroupInvitation) error

	// GetInvitationByCode находит приглашение по его уникальному коду.
	// Возвращает ErrRecordNotFound если приглашение не найдено.
	GetInvitationByCode(ctx context.Context, tx *gorm.DB, invitationCode string) (*models.GroupInvitation, error)

	// DeleteInvitation удаляет приглашение по его уникальному идентификатору.
	// Обычно используется после принятия приглашения или истечения срока.
	// Возвращает ErrRecordNotFound если приглашение не найдено.
	DeleteInvitation(ctx context.Context, tx *gorm.DB, invitationID uint) error

	// DeleteInvitationByCode удаляет приглашение по его уникальному коду.
	// Возвращает ErrRecordNotFound если приглашение не найдено.
	DeleteInvitationByCode(ctx context.Context, tx *gorm.DB, invitationCode string) error

	// ListInvitationsByGroup возвращает список активных приглашений для конкретной группы.
	// TODO: Добавить параметры для пагинации и сортировки.
	ListInvitationsByGroup(ctx context.Context, tx *gorm.DB, groupID uint) ([]models.GroupInvitation, error)

	// CheckInvitationExistsByCode проверяет существование активного приглашения по коду.
	CheckInvitationExistsByCode(ctx context.Context, tx *gorm.DB, invitationCode string) (bool, error)

	HardDeleteInvitationsByGroup(ctx context.Context, tx *gorm.DB, groupID uint) error
	HardDeleteInvitationsByUserID(ctx context.Context, tx *gorm.DB, userID uint) error
}

// Repository объединяет все репозитории для Group Service и предоставляет методы управления транзакциями.
type Repository interface {
	Group() GroupRepository
	GroupMember() GroupMemberRepository
	GroupInvitation() GroupInvitationRepository

	// BeginTx начинает новую транзакцию и возвращает объект *gorm.DB для использования в ней.
	BeginTx(ctx context.Context) (*gorm.DB, error)
	// CommitTx завершает транзакцию.
	CommitTx(tx *gorm.DB) error
	// RollbackTx откатывает транзакцию. Безопасно для вызова даже после успешного коммита или другого отката.
	RollbackTx(tx *gorm.DB) error
}
