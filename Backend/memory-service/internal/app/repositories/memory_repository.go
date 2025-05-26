package repositories

import (
	"context"
	"errors"
	"fmt"
	"log"
	"strings"
	"time"

	"gorm.io/gorm"

	"Rewind-memory-service/internal/app/models"
)

// MemoryRepositoryInterface определяет интерфейс для работы с данными воспоминаний.
type MemoryRepositoryInterface interface {
	CreateMemory(ctx context.Context, tx *gorm.DB, memory *models.Memory) error
	GetMemory(ctx context.Context, tx *gorm.DB, memoryId uint) (*models.Memory, error)
	DeleteMemory(ctx context.Context, tx *gorm.DB, memoryID uint) error
	DeleteMemoriesByGroup(ctx context.Context, tx *gorm.DB, groupID uint) error
	ListMemoriesByGroupDetailed(ctx context.Context, tx *gorm.DB, groupID uint, userID uint) ([]models.MemoryDetailed, error)
	ListMemoriesByGroupWithFiltersDetailed(ctx context.Context, tx *gorm.DB, groupID uint, userID uint, filters map[string]string, numberOfMemories uint) ([]models.MemoryDetailed, error)

	CreateMemoryTag(ctx context.Context, tx *gorm.DB, tag *models.MemoryTag) error
	DeleteMemoryTag(ctx context.Context, tx *gorm.DB, memoryID uint, tag string) error
	ListMemoryTagsByMemoryID(ctx context.Context, tx *gorm.DB, memoryID uint) ([]models.MemoryTag, error)

	CreateFavourite(ctx context.Context, tx *gorm.DB, favourite *models.Favourite) error
	DeleteFavourite(ctx context.Context, tx *gorm.DB, favouriteMemoryID uint, favouriteUserID uint) error
	DeleteFavouritesByUserID(ctx context.Context, tx *gorm.DB, userID uint) error

	// Методы для транзакций
	BeginTx(ctx context.Context) (*gorm.DB, error)
	CommitTx(tx *gorm.DB) error
	RollbackTx(tx *gorm.DB) error
}

// MemoryRepository реализует MemoryRepositoryInterface.
type MemoryRepository struct {
	db *gorm.DB
}

// NewMemoryRepository создает новый экземпляр MemoryRepository.
func NewMemoryRepository(db *gorm.DB) *MemoryRepository {
	return &MemoryRepository{db: db}
}

// getDB helper function to use transaction if it exists
func (r *MemoryRepository) getDB(tx *gorm.DB) *gorm.DB {
	if tx != nil {
		return tx
	}
	return r.db
}

// CreateMemory создает новое воспоминание в базе данных.
func (r *MemoryRepository) CreateMemory(ctx context.Context, tx *gorm.DB, memory *models.Memory) error {
	db := r.getDB(tx).WithContext(ctx)
	result := db.Create(memory)
	if result.Error != nil {
		log.Printf("MemoryRepository: Failed to create memory: %v", result.Error)
		return fmt.Errorf("failed to create memory: %w", result.Error)
	}
	return nil
}

// GetMemory получает воспоминание из базы данных по его ID.
func (r *MemoryRepository) GetMemory(ctx context.Context, tx *gorm.DB, memoryID uint) (*models.Memory, error) {
	db := r.getDB(tx).WithContext(ctx)
	var memory models.Memory
	result := db.First(&memory, memoryID) // Находит запись по первичному ключу

	if result.Error != nil {
		if errors.Is(result.Error, gorm.ErrRecordNotFound) {
			// Если запись не найдена, возвращаем nil и специфическую ошибку
			return nil, fmt.Errorf("memory not found: %w", result.Error)
		}
		log.Printf("MemoryRepository: Failed to get memory %d: %v", memoryID, result.Error)
		return nil, fmt.Errorf("failed to get memory: %w", result.Error)
	}

	return &memory, nil
}

// DeleteMemory удаляет воспоминание по его ID.
func (r *MemoryRepository) DeleteMemory(ctx context.Context, tx *gorm.DB, memoryID uint) error {
	db := r.getDB(tx).WithContext(ctx)
	result := db.Unscoped().Delete(&models.Memory{}, memoryID)
	if result.Error != nil {
		log.Printf("MemoryRepository: Failed to delete memory: %v", result.Error)
		return fmt.Errorf("failed to delete memory: %w", result.Error)
	}
	return nil
}

// DeleteMemoriesByGroup удаляет все воспоминания в заданной группе.
func (r *MemoryRepository) DeleteMemoriesByGroup(ctx context.Context, tx *gorm.DB, groupID uint) error {
	db := r.getDB(tx).WithContext(ctx)
	result := db.Unscoped().Where("group_id = ?", groupID).Delete(&models.Memory{})
	if result.Error != nil {
		log.Printf("MemoryRepository: Failed to delete memories by group: %v", result.Error)
		return fmt.Errorf("failed to delete memories by group: %w", result.Error)
	}
	return nil
}

// ListMemoriesByGroupDetailed получает список воспоминаний в заданной группе, включая теги и информацию о том, добавлено ли воспоминание в избранное текущим пользователем.
func (r *MemoryRepository) ListMemoriesByGroupDetailed(ctx context.Context, tx *gorm.DB, groupID uint, userID uint) ([]models.MemoryDetailed, error) {
	db := r.getDB(tx).WithContext(ctx)
	var memories []models.MemoryDetailed

	// Используем string_agg для агрегации тегов и CASE WHEN для определения, добавлено ли в избранное (PostgreSQL)
	query := `
        SELECT
            m.*,
            COALESCE(string_agg(DISTINCT mt.tag, ','), '') as tags,
            CASE
                WHEN EXISTS (SELECT 1 FROM favourites f WHERE f.memory_id = m.id AND f.user_id = ?) THEN TRUE
                ELSE FALSE
            END as is_favourite
        FROM memories m
        LEFT JOIN memory_tags mt ON mt.memory_id = m.id
        LEFT JOIN favourites f ON f.memory_id = m.id AND f.user_id = ?
        WHERE m.group_id = ?
        GROUP BY m.id
        ORDER BY m.created_at DESC 
    `

	result := db.Raw(query, userID, userID, groupID).Scan(&memories)
	if result.Error != nil {
		log.Printf("MemoryRepository: Failed to list detailed memories by group: %v", result.Error)
		return nil, fmt.Errorf("failed to list detailed memories by group: %w", result.Error)
	}

	// Post-process the results to split the comma-separated strings into slices
	for i := range memories {
		if memories[i].Tags != "" {
			memories[i].TagsArray = strings.Split(memories[i].Tags, ",")
		} else {
			memories[i].TagsArray = []string{}
		}
	}

	return memories, nil
}

// ListMemoriesByGroupWithFilters получает список воспоминаний в заданной группе с применением фильтров и детальной информацией.
func (r *MemoryRepository) ListMemoriesByGroupWithFiltersDetailed(ctx context.Context, tx *gorm.DB, groupID uint, userID uint, filters map[string]string, numberOfMemories uint) ([]models.MemoryDetailed, error) {
	db := r.getDB(tx).WithContext(ctx)
	var memoriesDetailed []models.MemoryDetailed

	query := `
        SELECT
            m.*,
            COALESCE(string_agg(DISTINCT mt.tag, ','), '') as tags,
            CASE
                WHEN EXISTS (SELECT 1 FROM favourites f WHERE f.memory_id = m.id AND f.user_id = ?) THEN TRUE
                ELSE FALSE
            END as is_favourite
        FROM memories m
        LEFT JOIN memory_tags mt ON mt.memory_id = m.id
        LEFT JOIN favourites f ON f.memory_id = m.id AND f.user_id = ?
        WHERE m.group_id = ?
    `

	var args []interface{}
	args = append(args, userID, userID, groupID)
	whereClauses := []string{}
	havingClauses := []string{}

	for key, value := range filters {
		switch key {
		case "media_type":
			if value != "" {
				whereClauses = append(whereClauses, "m.media_type = ?")
				args = append(args, value)
			}
		case "is_favourite":
			if value == "true" {
				havingClauses = append(havingClauses,
					"EXISTS (SELECT 1 FROM favourites f2 WHERE f2.memory_id = m.id AND f2.user_id = ?)")
				args = append(args, userID)
			} else if value == "false" {
				havingClauses = append(havingClauses,
					"NOT EXISTS (SELECT 1 FROM favourites f2 WHERE f2.memory_id = m.id AND f2.user_id = ?)")
				args = append(args, userID)
			}
		case "start_time":
			if parsedTime, err := time.Parse(time.RFC3339, value); err == nil && value != "" {
				whereClauses = append(whereClauses, "m.created_at >= ?")
				args = append(args, parsedTime)
			} else if value != "" {
				log.Printf("MemoryRepository: Failed to parse start_time: %v", err)
			}
		case "end_time":
			if parsedTime, err := time.Parse(time.RFC3339, value); err == nil && value != "" {
				whereClauses = append(whereClauses, "m.created_at <= ?")
				args = append(args, parsedTime)
			} else if value != "" {
				log.Printf("MemoryRepository: Failed to parse end_time: %v", err)
			}
		case "has_geo":
			if value == "true" {
				whereClauses = append(whereClauses, "m.latitude IS NOT NULL AND m.longitude IS NOT NULL AND m.latitude != '0' AND m.longitude != '0'")
			}
		case "has_music":
			if value == "true" {
				whereClauses = append(whereClauses, "m.music_id IS NOT NULL AND m.music_id != '' AND m.offset IS NOT NULL AND m.duration IS NOT NULL AND m.duration != '0'")
			}
		case "tags":
			if value != "" {
				tags := strings.Split(value, ",")
				if len(tags) > 0 {
					placeholders := strings.Repeat("?,", len(tags)-1) + "?"
					whereClauses = append(whereClauses,
						`EXISTS (
							SELECT 1 FROM memory_tags filter_mt
							WHERE filter_mt.memory_id = m.id AND filter_mt.tag IN (`+placeholders+`)
						)`)
					for _, tag := range tags {
						args = append(args, tag)
					}
				}
			}
		default:
			log.Printf("MemoryRepository: Unknown filter key: %s", key)
		}
	}

	if len(whereClauses) > 0 {
		query += " AND " + strings.Join(whereClauses, " AND ")
	}

	query += " GROUP BY m.id"

	if len(havingClauses) > 0 {
		query += " HAVING " + strings.Join(havingClauses, " AND ")
	}

	query += " ORDER BY RANDOM() LIMIT ?"
	args = append(args, numberOfMemories)

	result := db.Raw(query, args...).Scan(&memoriesDetailed)
	if result.Error != nil {
		log.Printf("MemoryRepository: Failed to list detailed memories by group with custom filters: %v", result.Error)
		return nil, fmt.Errorf("failed to list detailed memories by group with custom filters: %w", result.Error)
	}

	// Post-process the results to split the comma-separated strings into slices
	for i := range memoriesDetailed {
		if memoriesDetailed[i].Tags != "" {
			memoriesDetailed[i].TagsArray = strings.Split(memoriesDetailed[i].Tags, ",")
		} else {
			memoriesDetailed[i].TagsArray = []string{}
		}
	}

	return memoriesDetailed, nil
}

// Методы для работы с тегами

func (r *MemoryRepository) CreateMemoryTag(ctx context.Context, tx *gorm.DB, tag *models.MemoryTag) error {
	db := r.getDB(tx).WithContext(ctx)
	result := db.Create(tag)
	if result.Error != nil {
		log.Printf("MemoryRepository: Failed to create memory tag: %v", result.Error)
		return fmt.Errorf("failed to create memory tag: %w", result.Error)
	}
	return nil
}

func (r *MemoryRepository) DeleteMemoryTag(ctx context.Context, tx *gorm.DB, memoryID uint, tag string) error {
	db := r.getDB(tx).WithContext(ctx)
	var memoryTag models.MemoryTag

	// Находим первый тег с заданным значением для указанного memoryID
	result := db.Where("memory_id = ? AND tag = ?", memoryID, tag).First(&memoryTag)
	if result.Error != nil {
		if errors.Is(result.Error, gorm.ErrRecordNotFound) {
			log.Printf("MemoryRepository: Memory tag with value '%s' not found for memory ID %d", tag, memoryID)
			return nil // Тег не найден, ошибки нет
		}
		log.Printf("MemoryRepository: Failed to find memory tag by value: %v", result.Error)
		return fmt.Errorf("failed to find memory tag by value: %w", result.Error)
	}

	// Удаляем найденный тег
	deleteResult := db.Delete(&memoryTag)
	if deleteResult.Error != nil {
		log.Printf("MemoryRepository: Failed to delete memory tag with value '%s': %v", tag, deleteResult.Error)
		return fmt.Errorf("failed to delete memory tag: %w", deleteResult.Error)
	}

	return nil
}

func (r *MemoryRepository) ListMemoryTagsByMemoryID(ctx context.Context, tx *gorm.DB, memoryID uint) ([]models.MemoryTag, error) {
	db := r.getDB(tx).WithContext(ctx)
	var tags []models.MemoryTag
	result := db.Where("memory_id = ?", memoryID).Find(&tags)
	if result.Error != nil {
		log.Printf("MemoryRepository: Failed to list memory tags by memory ID: %v", result.Error)
		return nil, fmt.Errorf("failed to list memory tags by memory ID: %w", result.Error)
	}
	return tags, nil
}

// Методы для работы с избранным

func (r *MemoryRepository) CreateFavourite(ctx context.Context, tx *gorm.DB, favourite *models.Favourite) error {
	db := r.getDB(tx).WithContext(ctx)
	result := db.Create(favourite)
	if result.Error != nil {
		log.Printf("MemoryRepository: Failed to create favourite: %v", result.Error)
		return fmt.Errorf("failed to create favourite: %w", result.Error)
	}
	return nil
}

func (r *MemoryRepository) DeleteFavourite(ctx context.Context, tx *gorm.DB, favouriteMemoryID uint, favouriteUserID uint) error {
	db := r.getDB(tx).WithContext(ctx)
	result := db.Unscoped().Where("memory_id = ? AND user_id = ?", favouriteMemoryID, favouriteUserID).Delete(&models.Favourite{})
	if result.Error != nil {
		log.Printf("MemoryRepository: Failed to delete favourite: %v", result.Error)
		return fmt.Errorf("failed to delete favourite: %w", result.Error)
	}
	return nil
}

func (r *MemoryRepository) DeleteFavouritesByUserID(ctx context.Context, tx *gorm.DB, userID uint) error {
	db := r.getDB(tx).WithContext(ctx)
	result := db.Unscoped().Where("user_id = ?", userID).Delete(&models.Favourite{})
	if result.Error != nil {
		log.Printf("MemoryRepository: Failed to delete favourites by user ID: %v", result.Error)
		return fmt.Errorf("failed to delete favourites by user ID: %w", result.Error)
	}
	return nil
}

// BeginTx начинает новую транзакцию.
func (r *MemoryRepository) BeginTx(ctx context.Context) (*gorm.DB, error) {
	tx := r.db.WithContext(ctx).Begin()
	if tx.Error != nil {
		return nil, tx.Error
	}
	return tx, nil
}

// CommitTx завершает транзакцию.
func (r *MemoryRepository) CommitTx(tx *gorm.DB) error {
	// Проверяем, что tx не nil, хотя при правильном использовании BeginTx он не должен быть nil
	if tx == nil {
		return errors.New("cannot commit nil transaction")
	}
	return tx.Commit().Error
}

// RollbackTx откатывает транзакцию. Безопасно для вызова даже после успешного коммита или другого отката.
func (r *MemoryRepository) RollbackTx(tx *gorm.DB) error {
	// Проверяем, что tx не nil
	if tx == nil {
		return nil // Откатывать нечего
	}
	return tx.Rollback().Error
}
