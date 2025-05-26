package services

import (
	"context"
	"errors"
	"log"
	"time"

	"github.com/go-playground/validator/v10"
	"github.com/google/uuid"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"
	"gorm.io/gorm"

	"Rewind-group-service/clients/auth"
	"Rewind-group-service/internal/app/models"
	"Rewind-group-service/internal/app/repositories"
	pb "Rewind-group-service/pkg/proto"
	clients "Rewind-group-service/pkg/proto/clients"
)

// GroupService implements the group.GroupServiceServer interface
type GroupService struct {
	pb.UnimplementedGroupServiceServer
	groupRepo  repositories.Repository
	validator  *validator.Validate
	authClient *auth.AuthServiceClient
	// memoryClient       memory.MemoryServiceClient // TODO: Зависимость от клиента Memory Service
}

// NewGroupService создает новый экземпляр GroupService
func NewGroupService(repo repositories.Repository, validate *validator.Validate, authClient *auth.AuthServiceClient) *GroupService {
	return &GroupService{
		groupRepo:  repo,
		validator:  validate,
		authClient: authClient,
	}
}

// CreateGroup реализует RPC метод создания группы
func (s *GroupService) CreateGroup(ctx context.Context, req *pb.CreateGroupRequest) (*pb.CreateGroupResponse, error) {
	// 1. Валидация входных данных
	if err := s.validator.Var(req.GetName(), "required,min=3,max=100"); err != nil {
		log.Printf("CreateGroup: Invalid argument (Name): %v", err)
		return nil, status.Errorf(codes.InvalidArgument, "Invalid group name: %v", err)
	}
	// Валидация Image, если нужно
	// if req.GetImage() != "" { ... }

	requestingUserID := req.GetRequestingUserId()
	// Мы предполагаем, что API Gateway уже проверил существование этого пользователя.
	// Достаточно просто проверить, что ID передан.
	if requestingUserID <= 0 {
		log.Printf("CreateGroup: requesting_user_id is missing or invalid: %d", requestingUserID)
		// Если API Gateway не передал ID, это проблема аутентификации/авторизации на шлюзе.
		// Возвращаем Unauthenticated, хотя в идеале API Gateway должен был отсечь раньше.
		return nil, status.Errorf(codes.Unauthenticated, "Authenticated user ID is required")
	}

	// 2. Создание группы и записи об администраторе в рамках одной транзакции
	tx, err := s.groupRepo.BeginTx(ctx)
	if err != nil {
		log.Printf("CreateGroup: Failed to start transaction: %v", err)
		return nil, status.Errorf(codes.Internal, "Internal error starting transaction")
	}
	defer func() {
		if r := recover(); r != nil {
			log.Printf("CreateGroup: Panic during transaction, rolling back: %v", r)
			rollbackErr := s.groupRepo.RollbackTx(tx)
			if rollbackErr != nil {
				log.Printf("CreateGroup: Error during rollback after panic: %v", rollbackErr)
			}
			panic(r)
		} else if err != nil {
			log.Printf("CreateGroup: Transaction failed, rolling back: %v", err)
			rollbackErr := s.groupRepo.RollbackTx(tx)
			if rollbackErr != nil {
				log.Printf("CreateGroup: Error during rollback: %v", rollbackErr)
			}
		}
	}()

	groupModel := &models.Group{
		Name:        req.GetName(),
		AdminUserID: uint(requestingUserID),
	}

	err = s.groupRepo.Group().CreateGroup(ctx, tx, groupModel)
	if err != nil {
		if errors.Is(err, gorm.ErrDuplicatedKey) {
			log.Printf("CreateGroup: Duplicate key error creating group: %v", err)
			err = status.Errorf(codes.AlreadyExists, "Group with this name already exists")
			return nil, err
		}
		log.Printf("CreateGroup: Failed to create group in DB: %v", err)
		err = status.Errorf(codes.Internal, "Failed to create group")
		return nil, err
	}

	adminMemberModel := &models.GroupMember{
		GroupID:             groupModel.ID,
		UserID:              uint(requestingUserID),
		IsAdmin:             true,
		MemoriesAddedCount:  0,
		MemoriesViewedCount: 0,
	}

	err = s.groupRepo.GroupMember().CreateMember(ctx, tx, adminMemberModel)
	if err != nil {
		if errors.Is(err, gorm.ErrDuplicatedKey) {
			log.Printf("CreateGroup: Duplicate member error creating admin member: %v", err)
			err = status.Errorf(codes.Internal, "Internal error creating admin member")
			return nil, err
		}
		log.Printf("CreateGroup: Failed to create admin member in DB: %v", err)
		err = status.Errorf(codes.Internal, "Failed to add admin member to group")
		return nil, err
	}

	err = s.groupRepo.CommitTx(tx)
	if err != nil {
		log.Printf("CreateGroup: Failed to commit transaction: %v", err)
		return nil, status.Errorf(codes.Internal, "Internal error finalizing group creation")
	}

	responseGroup := &pb.Group{
		Id:          uint64(groupModel.ID),
		Name:        groupModel.Name,
		Image:       groupModel.Image,
		AdminUserId: uint64(groupModel.AdminUserID),
		CreatedAt:   timestamppb.New(groupModel.CreatedAt),
		UpdatedAt:   timestamppb.New(groupModel.UpdatedAt),
	}

	return &pb.CreateGroupResponse{Group: responseGroup}, nil
}

// GetGroup реализует RPC метод получения информации о группе (код из предыдущего ответа)
func (s *GroupService) GetGroup(ctx context.Context, req *pb.GetGroupRequest) (*pb.GetGroupResponse, error) {
	// 1. Валидация входных данных
	groupID := req.GetGroupId()
	if groupID <= 0 {
		log.Printf("GetGroup: Invalid argument: group_id is missing or invalid: %d", groupID)
		return nil, status.Errorf(codes.InvalidArgument, "Invalid group ID")
	}
	requestingUserID := req.GetRequestingUserId()
	if requestingUserID <= 0 {
		log.Printf("GetGroup: requesting_user_id is missing or invalid: %d", requestingUserID)
		return nil, status.Errorf(codes.Unauthenticated, "User ID is required")
	}

	// 2. Проверка прав доступа: является ли запрашивающий пользователь участником группы?
	member, err := s.groupRepo.GroupMember().GetMemberByGroupAndUser(ctx, nil, uint(groupID), uint(requestingUserID))
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			log.Printf("GetGroup: Permission denied - user %d is not a member of group %d", requestingUserID, groupID)
			return nil, status.Errorf(codes.PermissionDenied, "Access denied")
		}
		log.Printf("GetGroup: Failed to check membership for user %d in group %d: %v", requestingUserID, groupID, err)
		return nil, status.Errorf(codes.Internal, "Failed to check user membership")
	}

	isAdmin := member.IsAdmin

	// 3. Получение информации о группе
	groupModel, err := s.groupRepo.Group().GetGroupByID(ctx, nil, uint(groupID))
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			log.Printf("GetGroup: Group %d not found after membership check", groupID)
			return nil, status.Errorf(codes.NotFound, "Group not found")
		}
		log.Printf("GetGroup: Failed to get group %d from DB: %v", groupID, err)
		return nil, status.Errorf(codes.Internal, "Failed to retrieve group information")
	}

	// 4. Формирование успешного ответа
	responseGroup := &pb.Group{
		Id:          uint64(groupModel.ID),
		Name:        groupModel.Name,
		Image:       groupModel.Image,
		AdminUserId: uint64(groupModel.AdminUserID),
		CreatedAt:   timestamppb.New(groupModel.CreatedAt),
		UpdatedAt:   timestamppb.New(groupModel.UpdatedAt),
	}

	return &pb.GetGroupResponse{
		Group:   responseGroup,
		IsAdmin: isAdmin,
	}, nil
}

// UpdateGroup реализует RPC метод обновления информации о группе
func (s *GroupService) UpdateGroup(ctx context.Context, req *pb.UpdateGroupRequest) (*pb.UpdateGroupResponse, error) {
	// 1. Валидация входных данных
	groupID := req.GetGroupId()
	if groupID <= 0 {
		log.Printf("UpdateGroup: Invalid argument: group_id is missing or invalid: %d", groupID)
		return nil, status.Errorf(codes.InvalidArgument, "Invalid group ID")
	}
	requestingUserID := req.GetRequestingUserId()
	if requestingUserID <= 0 {
		log.Printf("UpdateGroup: requesting_user_id is missing or invalid: %d", requestingUserID)
		return nil, status.Errorf(codes.Unauthenticated, "User ID is required")
	}

	// Валидация опциональных полей Name и Image, если они присутствуют в запросе
	if req.Name != nil { // Проверяем, установлено ли поле name в запросе
		if err := s.validator.Var(req.GetName(), "required,min=3,max=100"); err != nil {
			log.Printf("UpdateGroup: Invalid argument (Name): %v", err)
			return nil, status.Errorf(codes.InvalidArgument, "Invalid group name: %v", err)
		}
	}
	// Валидация Image, если присутствует
	// if req.Image != nil { ... } // Проверяем, установлено ли поле image

	// 2. Получение существующей группы
	// Эта операция только чтение, транзакция пока не нужна
	groupModel, err := s.groupRepo.Group().GetGroupByID(ctx, nil, uint(groupID))
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			log.Printf("UpdateGroup: Group not found: %d", groupID)
			return nil, status.Errorf(codes.NotFound, "Group not found")
		}
		log.Printf("UpdateGroup: Failed to get group %d from DB: %v", groupID, err)
		return nil, status.Errorf(codes.Internal, "Failed to retrieve group information")
	}

	// 3. Проверка прав доступа: является ли запрашивающий пользователь администратором группы?
	if groupModel.AdminUserID != uint(requestingUserID) {
		log.Printf("UpdateGroup: Permission denied - user %d is not admin of group %d", requestingUserID, groupID)
		return nil, status.Errorf(codes.PermissionDenied, "Only group administrator can update group information")
	}

	// 4. Обновление полей группы (используем транзакцию для операции записи)
	tx, err := s.groupRepo.BeginTx(ctx)
	if err != nil {
		log.Printf("UpdateGroup: Failed to start transaction: %v", err)
		return nil, status.Errorf(codes.Internal, "Internal error starting transaction")
	}
	defer func() {
		if r := recover(); r != nil {
			log.Printf("UpdateGroup: Panic during transaction, rolling back: %v", r)
			rollbackErr := s.groupRepo.RollbackTx(tx)
			if rollbackErr != nil {
				log.Printf("UpdateGroup: Error during rollback after panic: %v", rollbackErr)
			}
			panic(r)
		} else if err != nil {
			log.Printf("UpdateGroup: Transaction failed, rolling back: %v", err)
			rollbackErr := s.groupRepo.RollbackTx(tx)
			if rollbackErr != nil {
				log.Printf("UpdateGroup: Error during rollback: %v", rollbackErr)
			}
		}
	}()

	// Обновляем поля модели только если они присутствуют в запросе
	if req.Name != nil {
		groupModel.Name = req.GetName()
	}
	if req.Image != nil {

		// TODO send to media-service req.GetImage()

		groupModel.Image = "default"
	}
	// GORM при Save с gorm.Model автоматически обновит UpdatedAt

	// Сохраняем обновленную группу в базе данных (используем транзакционный tx)
	err = s.groupRepo.Group().UpdateGroup(ctx, tx, groupModel)
	if err != nil {
		if errors.Is(err, gorm.ErrDuplicatedKey) {
			log.Printf("UpdateGroup: Duplicate key error updating group: %v", err)
			err = status.Errorf(codes.AlreadyExists, "Group with this name already exists")
			return nil, err
		}
		log.Printf("UpdateGroup: Failed to update group in DB: %v", err)
		err = status.Errorf(codes.Internal, "Failed to update group information")
		return nil, err
	}

	// Если обновление успешно, фиксируем транзакцию
	err = s.groupRepo.CommitTx(tx)
	if err != nil {
		log.Printf("UpdateGroup: Failed to commit transaction: %v", err)
		return nil, status.Errorf(codes.Internal, "Internal error finalizing group update")
	}

	// 5. Формирование успешного ответа
	responseGroup := &pb.Group{
		Id:          uint64(groupModel.ID),
		Name:        groupModel.Name,
		Image:       groupModel.Image,
		AdminUserId: uint64(groupModel.AdminUserID),
		CreatedAt:   timestamppb.New(groupModel.CreatedAt),
		UpdatedAt:   timestamppb.New(groupModel.UpdatedAt),
	}

	return &pb.UpdateGroupResponse{Group: responseGroup}, nil
}

// DeleteGroup реализует RPC метод удаления группы
func (s *GroupService) DeleteGroup(ctx context.Context, req *pb.DeleteGroupRequest) (*pb.DeleteGroupResponse, error) {
	// 1. Валидация входных данных
	groupID := req.GetGroupId()
	if groupID <= 0 {
		log.Printf("DeleteGroup: Invalid argument: group_id is missing or invalid: %d", groupID)
		return nil, status.Errorf(codes.InvalidArgument, "Invalid group ID")
	}
	requestingUserID := req.GetRequestingUserId()
	if requestingUserID <= 0 {
		log.Printf("DeleteGroup: requesting_user_id is missing or invalid: %d", requestingUserID)
		return nil, status.Errorf(codes.Unauthenticated, "User ID is required")
	}

	// 2. Получение существующей группы для проверки прав доступа
	groupModel, err := s.groupRepo.Group().GetGroupByID(ctx, nil, uint(groupID))
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			log.Printf("DeleteGroup: Group not found: %d", groupID)
			return nil, status.Errorf(codes.NotFound, "Group not found")
		}
		log.Printf("DeleteGroup: Failed to get group %d from DB: %v", groupID, err)
		return nil, status.Errorf(codes.Internal, "Failed to retrieve group information")
	}

	// 3. Проверка прав доступа: является ли запрашивающий пользователь администратором группы?
	if groupModel.AdminUserID != uint(requestingUserID) {
		log.Printf("DeleteGroup: Permission denied - user %d is not admin of group %d", requestingUserID, groupID)
		return nil, status.Errorf(codes.PermissionDenied, "Only group administrator can delete a group")
	}

	// 4. Удаление группы и связанных данных (используем транзакцию)
	tx, err := s.groupRepo.BeginTx(ctx)
	if err != nil {
		log.Printf("DeleteGroup: Failed to start transaction: %v", err)
		return nil, status.Errorf(codes.Internal, "Internal error starting transaction")
	}
	defer func() {
		if r := recover(); r != nil {
			log.Printf("DeleteGroup: Panic during transaction, rolling back: %v", r)
			rollbackErr := s.groupRepo.RollbackTx(tx)
			if rollbackErr != nil {
				log.Printf("DeleteGroup: Error during rollback after panic: %v", rollbackErr)
			}
			panic(r)
		} else if err != nil {
			log.Printf("DeleteGroup: Transaction failed, rolling back: %v", err)
			rollbackErr := s.groupRepo.RollbackTx(tx)
			if rollbackErr != nil {
				log.Printf("DeleteGroup: Error during rollback: %v", rollbackErr)
			}
		}
	}()

	// Удаление связанных участников группы (жесткое)
	err = s.groupRepo.GroupMember().HardDeleteMembersByGroup(ctx, tx, uint(groupID))
	if err != nil {
		// Ошибка при удалении участников - внутренняя ошибка
		log.Printf("DeleteGroup: Failed to hard delete members for group %d: %v", groupID, err)
		err = status.Errorf(codes.Internal, "Failed to delete group members")
		return nil, err
	}

	err = s.groupRepo.GroupInvitation().HardDeleteInvitationsByGroup(ctx, tx, uint(groupID))
	if err != nil {
		log.Printf("DeleteGroup: Failed to hard delete invitations for group %d: %v", groupID, err)
		err = status.Errorf(codes.Internal, "Failed to delete group invitations")
		return nil, err
	}

	// TODO: Обработка воспоминаний:
	//   Уведомить memory-service о жестком удалении группы, чтобы он
	//   обработал связанные воспоминания (например, удалил их или пометил).
	//   Понадобится вызов метода MemoryClient.DeleteMemoriesByGroup(ctx, &memory.DeleteMemoriesByGroupRequest{GroupId: groupID})
	//   Обработка ошибок от MemoryClient.

	// Удаление самой группы (жесткое удаление)
	err = s.groupRepo.Group().DeleteGroup(ctx, tx, uint(groupID))
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			log.Printf("DeleteGroup: Group %d not found during deletion after fetch", groupID)
			err = status.Errorf(codes.NotFound, "Group not found")
			return nil, err
		}
		log.Printf("DeleteGroup: Failed to delete group %d from DB: %v", groupID, err)
		err = status.Errorf(codes.Internal, "Failed to delete group")
		return nil, err
	}

	// Если все операции удаления успешны, фиксируем транзакцию
	err = s.groupRepo.CommitTx(tx)
	if err != nil {
		log.Printf("DeleteGroup: Failed to commit transaction: %v", err)
		return nil, status.Errorf(codes.Internal, "Internal error finalizing group deletion")
	}

	// 5. Формирование успешного ответа
	return &pb.DeleteGroupResponse{Success: true}, nil
}

// ListGroupMembers реализует RPC метод получения списка участников группы
func (s *GroupService) ListGroupMembers(ctx context.Context, req *pb.ListGroupMembersRequest) (*pb.ListGroupMembersResponse, error) {
	// 1. Валидация входных данных
	groupID := req.GetGroupId()
	if groupID <= 0 {
		log.Printf("ListGroupMembers: Invalid argument: group_id is missing or invalid: %d", groupID)
		return nil, status.Errorf(codes.InvalidArgument, "Invalid group ID")
	}
	requestingUserID := req.GetRequestingUserId()
	if requestingUserID <= 0 {
		log.Printf("ListGroupMembers: requesting_user_id is missing or invalid: %d", requestingUserID)
		return nil, status.Errorf(codes.Unauthenticated, "User ID is required")
	}

	// 2. Проверка прав доступа: является ли запрашивающий пользователь участником группы?
	// Только участники могут видеть список других участников.
	_, err := s.groupRepo.GroupMember().GetMemberByGroupAndUser(ctx, nil, uint(groupID), uint(requestingUserID))
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			log.Printf("ListGroupMembers: Permission denied - user %d is not a member of group %d", requestingUserID, groupID)
			return nil, status.Errorf(codes.PermissionDenied, "Access denied")
		}
		log.Printf("ListGroupMembers: Failed to check membership for user %d in group %d: %v", requestingUserID, groupID, err)
		return nil, status.Errorf(codes.Internal, "Failed to check user membership")
	}

	// 3. Получение списка участников группы из репозитория
	// Эта операция только чтение, транзакция не нужна
	memberModels, err := s.groupRepo.GroupMember().ListMembersByGroup(ctx, nil, uint(groupID))
	if err != nil {
		log.Printf("ListGroupMembers: Failed to get members for group %d from DB: %v", groupID, err)
		return nil, status.Errorf(codes.Internal, "Failed to retrieve group members list")
	}

	// 4. Получение информации о пользователях-участниках из Auth-Service
	// Собираем все user_id участников
	userIds := make([]uint64, 0, len(memberModels))
	// Маппинг memberModel по user_id для быстрого доступа
	membersMap := make(map[uint]*models.GroupMember)
	for _, memberModel := range memberModels {
		userIds = append(userIds, uint64(memberModel.UserID))
		membersMap[memberModel.UserID] = &memberModel
	}

	// Пропускаем вызов AuthClient, если нет участников (например, пустая группа)
	if len(userIds) == 0 {
		return &pb.ListGroupMembersResponse{Members: []*pb.ListGroupMembersResponse_MemberDetails{}}, nil
	}

	getUsersReq := &clients.GetUsersByIDsRequest{UserIds: userIds}
	getUsersResp, err := s.authClient.GetUsersByIDs(ctx, getUsersReq)
	if err != nil {
		st, ok := status.FromError(err)
		if ok {
			if st.Code() == codes.NotFound {
				log.Printf("ListGroupMembers: User ID from group member not found in Auth-Service: %v", st.Message())
				return nil, status.Errorf(codes.Internal, "Failed to retrieve some user details")
			}
			log.Printf("ListGroupMembers: Error from Auth-Service GetUsersByIDs: %v", st.Message())
			return nil, status.Errorf(codes.Internal, "Failed to retrieve user details")
		}
		log.Printf("ListGroupMembers: Non-gRPC error calling Auth-Service GetUsersByIDs: %v", err)
		return nil, status.Errorf(codes.Internal, "Failed to communicate with authentication service")
	}

	userDetailsMap := make(map[uint64]*clients.User)
	if getUsersResp != nil {
		for _, user := range getUsersResp.GetUsers() {
			userDetailsMap[user.GetId()] = user
		}
	}

	responseMembers := make([]*pb.ListGroupMembersResponse_MemberDetails, 0, len(memberModels))
	for _, memberModel := range memberModels {
		userId := memberModel.UserID
		userDetails, found := userDetailsMap[uint64(userId)]

		username := "unknown"
		userImage := ""
		if !found {
			log.Printf("ListGroupMembers: User details not found in Auth-Service for member user ID %d in group %d", memberModel.UserID, groupID)
		} else {
			username = userDetails.GetUsername()
			userImage = userDetails.GetImage()
		}

		responseMembers = append(responseMembers, &pb.ListGroupMembersResponse_MemberDetails{
			UserId:              uint64(userId),
			Username:            username,
			UserImage:           userImage,
			IsAdmin:             memberModel.IsAdmin,
			MemoriesAddedCount:  uint64(memberModel.MemoriesAddedCount),
			MemoriesViewedCount: uint64(memberModel.MemoriesViewedCount),
			JoinedAt:            timestamppb.New(memberModel.CreatedAt),
		})
	}

	return &pb.ListGroupMembersResponse{Members: responseMembers}, nil
}

// RemoveGroupMember реализует RPC метод удаления участника из группы
func (s *GroupService) RemoveGroupMember(ctx context.Context, req *pb.RemoveGroupMemberRequest) (*pb.RemoveGroupMemberResponse, error) {
	// 1. Валидация входных данных
	groupID := req.GetGroupId()
	if groupID <= 0 {
		log.Printf("RemoveGroupMember: Invalid argument: group_id is missing or invalid: %d", groupID)
		return nil, status.Errorf(codes.InvalidArgument, "Invalid group ID")
	}
	requestingUserID := req.GetRequestingUserId()
	if requestingUserID <= 0 {
		log.Printf("RemoveGroupMember: requesting_user_id is missing or invalid: %d", requestingUserID)
		return nil, status.Errorf(codes.Unauthenticated, "User ID is required")
	}
	userIDToRemove := req.GetUserIdToRemove()
	if userIDToRemove <= 0 {
		log.Printf("RemoveGroupMember: Invalid argument: user_id_to_remove is missing or invalid: %d", userIDToRemove)
		return nil, status.Errorf(codes.InvalidArgument, "Invalid user ID to remove")
	}

	// 2. Проверка прав доступа: является ли запрашивающий пользователь участником группы и имеет ли право удалять?
	// Сначала убедимся, что запрашивающий пользователь является участником.
	requestingMember, err := s.groupRepo.GroupMember().GetMemberByGroupAndUser(ctx, nil, uint(groupID), uint(requestingUserID))
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			log.Printf("RemoveGroupMember: Permission denied - user %d is not a member of group %d", requestingUserID, groupID)
			// Возвращаем NotFound, чтобы не раскрывать существование группы не-участникам
			return nil, status.Errorf(codes.NotFound, "Group not found or access denied")
		}
		log.Printf("RemoveGroupMember: Failed to check membership for user %d in group %d: %v", requestingUserID, groupID, err)
		return nil, status.Errorf(codes.Internal, "Failed to check user membership")
	}

	isRequestingUserAdmin := requestingMember.IsAdmin
	isRemovingSelf := requestingUserID == userIDToRemove

	// Логика прав:
	// - Если запрашивающий пользователь НЕ администратор, он может удалить ТОЛЬКО себя.
	// - Если запрашивающий пользователь АДМИНИСТРАТОР, он может удалить любого (включая себя).
	if !isRequestingUserAdmin && !isRemovingSelf {
		log.Printf("RemoveGroupMember: Permission denied - user %d tried to remove user %d from group %d without being admin", requestingUserID, userIDToRemove, groupID)
		return nil, status.Errorf(codes.PermissionDenied, "Only group administrator can remove other members")
	}

	// 3. Находим запись об участии пользователя, которого нужно удалить
	// Эта операция только чтение, транзакция пока не нужна
	memberToRemove, err := s.groupRepo.GroupMember().GetMemberByGroupAndUser(ctx, nil, uint(groupID), uint(userIDToRemove))
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Пользователь, которого пытаются удалить, не является участником этой группы
			log.Printf("RemoveGroupMember: User %d is not a member of group %d", userIDToRemove, groupID)
			return nil, status.Errorf(codes.NotFound, "User is not a member of this group")
		}
		// Другая ошибка БД при поиске участника - внутренняя
		log.Printf("RemoveGroupMember: Failed to get member %d in group %d: %v", userIDToRemove, groupID, err)
		return nil, status.Errorf(codes.Internal, "Failed to retrieve member information")
	}

	// 4. Логика удаления в зависимости от того, кто удаляется и является ли он админом
	tx, err := s.groupRepo.BeginTx(ctx)
	if err != nil {
		log.Printf("RemoveGroupMember: Failed to start transaction: %v", err)
		return nil, status.Errorf(codes.Internal, "Internal error starting transaction")
	}
	defer func() {
		if r := recover(); r != nil {
			log.Printf("RemoveGroupMember: Panic during transaction, rolling back: %v", r)
			rollbackErr := s.groupRepo.RollbackTx(tx)
			if rollbackErr != nil {
				log.Printf("RemoveGroupMember: Error during rollback after panic: %v", rollbackErr)
			}
			panic(r)
		} else if err != nil {
			log.Printf("RemoveGroupMember: Transaction failed, rolling back: %v", err)
			rollbackErr := s.groupRepo.RollbackTx(tx)
			if rollbackErr != nil {
				log.Printf("RemoveGroupMember: Error during rollback: %v", rollbackErr)
			}
		}
	}()

	// Сценарий: Администратор удаляет себя
	if isRequestingUserAdmin && isRemovingSelf {
		// Проверяем количество участников в группе
		memberCount, countErr := s.groupRepo.GroupMember().CountMembersByGroup(ctx, tx, uint(groupID))
		if countErr != nil {
			log.Printf("RemoveGroupMember: Failed to count members for group %d: %v", groupID, countErr)
			err = status.Errorf(codes.Internal, "Failed to check member count")
			return nil, err
		}

		if memberCount == 1 {
			// Если администратор единственный участник, жестко удаляем группу
			log.Printf("RemoveGroupMember: Admin user %d is the only member of group %d, hard deleting group.", requestingUserID, groupID)

			// Жесткое удаление связанных участников (должен удалить только текущего админа)
			hardDeleteMembersErr := s.groupRepo.GroupMember().HardDeleteMembersByGroup(ctx, tx, uint(groupID))
			if hardDeleteMembersErr != nil {
				log.Printf("DeleteGroup: Failed to hard delete members for group %d: %v", groupID, hardDeleteMembersErr)
				err = status.Errorf(codes.Internal, "Failed to delete group members during hard delete")
				return nil, err
			}

			// Жесткое удаление связанных приглашений
			hardDeleteInvitationsErr := s.groupRepo.GroupInvitation().HardDeleteInvitationsByGroup(ctx, tx, uint(groupID))
			if hardDeleteInvitationsErr != nil {
				log.Printf("DeleteGroup: Failed to hard delete invitations for group %d: %v", groupID, hardDeleteInvitationsErr)
				err = status.Errorf(codes.Internal, "Failed to delete group invitations during hard delete")
				return nil, err
			}

			// TODO: Уведомить memory-service о жестком удалении группы (delete group ID)

			// Жесткое удаление самой группы
			hardDeleteGroupErr := s.groupRepo.Group().DeleteGroup(ctx, tx, uint(groupID))
			if hardDeleteGroupErr != nil {
				if errors.Is(hardDeleteGroupErr, gorm.ErrRecordNotFound) {
					log.Printf("DeleteGroup: Group %d not found during hard deletion after fetch", groupID)
					err = status.Errorf(codes.NotFound, "Group not found")
					return nil, err
				}
				log.Printf("DeleteGroup: Failed to hard delete group %d from DB: %v", groupID, hardDeleteGroupErr)
				err = status.Errorf(codes.Internal, "Failed to hard delete group")
				return nil, err
			}

			// Если все жесткие удаления успешны, коммитим
			err = s.groupRepo.CommitTx(tx)
			if err != nil {
				log.Printf("RemoveGroupMember: Failed to commit transaction during hard delete: %v", err)
				return nil, status.Errorf(codes.Internal, "Internal error finalizing group deletion")
			}

			// Успешно жестко удалили группу
			return &pb.RemoveGroupMemberResponse{Success: true}, nil

		} else {
			// Администратор не единственный участник, назначаем нового админа
			log.Printf("RemoveGroupMember: Admin user %d leaving group %d. Assigning new admin.", requestingUserID, groupID)

			// Находим любого другого участника, кроме текущего администратора
			newAdminMember, findErr := s.groupRepo.GroupMember().FindAnyOtherMemberByGroup(ctx, tx, uint(groupID), uint(requestingUserID))
			if findErr != nil {
				if errors.Is(findErr, gorm.ErrRecordNotFound) {
					log.Printf("RemoveGroupMember: Failed to find another member in group %d to assign as admin.", groupID)
					err = status.Errorf(codes.Internal, "Failed to find another member to assign as administrator")
					return nil, err
				}
				log.Printf("RemoveGroupMember: Failed to find another member in group %d: %v", groupID, findErr)
				err = status.Errorf(codes.Internal, "Failed to select new administrator")
				return nil, err
			}

			newAdminUserID := newAdminMember.UserID

			// Обновляем группу, назначая нового администратора
			// Сначала получаем текущую модель группы (нужна для UpdateGroup)
			// Важно: Получаем в рамках той же транзакции tx!
			groupModelForUpdate, getGroupErr := s.groupRepo.Group().GetGroupByID(ctx, tx, uint(groupID))
			if getGroupErr != nil {
				// Этого не должно случиться
				log.Printf("RemoveGroupMember: Failed to get group %d during admin assignment update: %v", groupID, getGroupErr)
				err = status.Errorf(codes.Internal, "Internal error retrieving group for admin update")
				return nil, err
			}

			groupModelForUpdate.AdminUserID = newAdminUserID // Устанавливаем нового админа

			updateGroupErr := s.groupRepo.Group().UpdateGroup(ctx, tx, groupModelForUpdate)
			if updateGroupErr != nil {
				log.Printf("RemoveGroupMember: Failed to update group %d with new admin %d: %v", groupID, newAdminUserID, updateGroupErr)
				err = status.Errorf(codes.Internal, "Failed to update group administrator")
				return nil, err
			}

			// Мягкое удаление записи участника (текущего админа)
			softDeleteMemberErr := s.groupRepo.GroupMember().DeleteMember(ctx, tx, memberToRemove.ID)
			if softDeleteMemberErr != nil {
				if errors.Is(softDeleteMemberErr, gorm.ErrRecordNotFound) {
					log.Printf("RemoveGroupMember: Member record %d not found during soft deletion after fetch", memberToRemove.ID)
					err = status.Errorf(codes.Internal, "Internal error deleting member")
					return nil, err
				}
				log.Printf("RemoveGroupMember: Failed to soft delete member %d from DB: %v", memberToRemove.ID, softDeleteMemberErr)
				err = status.Errorf(codes.Internal, "Failed to remove group member")
				return nil, err
			}

			// TODO: Уведомить memory-service о выходе участника (delete member ID)

			// Если все операции успешны, коммитим
			err = s.groupRepo.CommitTx(tx)
			if err != nil {
				log.Printf("RemoveGroupMember: Failed to commit transaction during admin leave: %v", err)
				return nil, status.Errorf(codes.Internal, "Internal error finalizing admin leave")
			}

			// Успешно удалили админа и назначили нового
			return &pb.RemoveGroupMemberResponse{Success: true}, nil
		}
	} else {
		// Сценарий: Не-администратор удаляет себя ИЛИ Администратор удаляет другого участника.
		// В этом случае просто мягко удаляем запись участника.

		// Мягкое удаление записи GroupMember
		err = s.groupRepo.GroupMember().DeleteMember(ctx, tx, memberToRemove.ID)
		if err != nil {
			if errors.Is(err, gorm.ErrRecordNotFound) {
				log.Printf("RemoveGroupMember: Member record %d not found during deletion after fetch", memberToRemove.ID)
				err = status.Errorf(codes.Internal, "Internal error deleting member")
				return nil, err
			}
			log.Printf("RemoveGroupMember: Failed to delete member %d from DB: %v", memberToRemove.ID, err)
			err = status.Errorf(codes.Internal, "Failed to remove group member")
			return nil, err
		}

		// TODO: Уведомить memory-service о выходе участника (delete member ID)

		// Если удаление успешно, фиксируем транзакцию
		err = s.groupRepo.CommitTx(tx)
		if err != nil {
			log.Printf("RemoveGroupMember: Failed to commit transaction: %v", err)
			return nil, status.Errorf(codes.Internal, "Internal error finalizing member removal")
		}

		// 5. Формирование успешного ответа
		return &pb.RemoveGroupMemberResponse{Success: true}, nil
	}
}

// CheckUserInGroup реализует RPC метод для проверки, состоит ли пользователь в группе и является ли он админом.
func (s *GroupService) CheckUserInGroup(ctx context.Context, req *pb.CheckUserInGroupRequest) (*pb.CheckUserInGroupResponse, error) {
	// 1. Валидация входных данных
	userID := req.GetUserId()
	groupID := req.GetGroupId()
	if userID <= 0 || groupID <= 0 {
		log.Printf("CheckUserInGroup: Invalid argument: user_id (%d) or group_id (%d) is missing or invalid", userID, groupID)
		return nil, status.Errorf(codes.InvalidArgument, "Invalid user or group ID")
	}

	// 2. Проверка членства пользователя в группе и роли (админ) через репозиторий
	isInGroup, isAdmin, err := s.groupRepo.GroupMember().CheckUserInGroup(ctx, nil, uint(userID), uint(groupID))
	if err != nil {
		log.Printf("CheckUserInGroup: Failed to check user %d in group %d in DB: %v", userID, groupID, err)
		return nil, status.Errorf(codes.Internal, "Failed to check user group membership")
	}

	// 3. Формирование успешного ответа
	return &pb.CheckUserInGroupResponse{
		IsInGroup: isInGroup,
		IsAdmin:   isAdmin,
	}, nil
}

// CreateGroupInvitation реализует RPC метод создания приглашения в группу
func (s *GroupService) CreateGroupInvitation(ctx context.Context, req *pb.CreateGroupInvitationRequest) (*pb.CreateGroupInvitationResponse, error) {
	// 1. Валидация входных данных
	groupID := req.GetGroupId()
	if groupID <= 0 {
		log.Printf("CreateGroupInvitation: Invalid argument: group_id is missing or invalid: %d", groupID)
		return nil, status.Errorf(codes.InvalidArgument, "Invalid group ID")
	}
	requestingUserID := req.GetRequestingUserId()
	if requestingUserID <= 0 {
		log.Printf("CreateGroupInvitation: requesting_user_id is missing or invalid: %d", requestingUserID)
		return nil, status.Errorf(codes.Unauthenticated, "User ID is required")
	}

	if req.Duration != nil && req.GetDuration().AsDuration() < 0 {
		log.Printf("CreateGroupInvitation: Invalid argument: Duration cannot be negative for group %d", groupID)
		return nil, status.Errorf(codes.InvalidArgument, "Duration cannot be negative")
	}

	// 2. Проверка прав доступа: запрашивающий пользователь должен быть участником группы
	_, err := s.groupRepo.GroupMember().GetMemberByGroupAndUser(ctx, nil, uint(groupID), uint(requestingUserID))
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			log.Printf("CreateGroupInvitation: Permission denied - user %d is not a member of group %d", requestingUserID, groupID)
			return nil, status.Errorf(codes.NotFound, "Group not found or access denied") // Скрываем существование группы
		}
		log.Printf("CreateGroupInvitation: Failed to check membership for user %d in group %d: %v", requestingUserID, groupID, err)
		return nil, status.Errorf(codes.Internal, "Failed to check user membership")
	}

	// 3. Определяем срок действия приглашения
	var expiresAt time.Time
	if req.Duration != nil {
		// Если установлен duration, рассчитываем expires_at от текущего времени
		expiresAt = time.Now().Add(req.GetDuration().AsDuration())
	} else {
		defaultDuration := 24 * time.Hour
		expiresAt = time.Now().Add(defaultDuration)
		log.Printf("CreateGroupInvitation: No expiry set for group %d, using default duration %v", groupID, defaultDuration)
	}

	// Проверяем, что срок действия в будущем
	if expiresAt.Before(time.Now()) {
		log.Printf("CreateGroupInvitation: Invalid argument: Expiration time is in the past for group %d", groupID)
		return nil, status.Errorf(codes.InvalidArgument, "Expiration time cannot be in the past")
	}

	// 4. Генерируем уникальный код приглашения и создаем запись в базе данных
	// Используем транзакцию, т.к. это операция записи.
	tx, err := s.groupRepo.BeginTx(ctx)
	if err != nil {
		log.Printf("CreateGroupInvitation: Failed to start transaction: %v", err)
		return nil, status.Errorf(codes.Internal, "Internal error starting transaction")
	}
	defer func() {
		if r := recover(); r != nil {
			log.Printf("CreateGroupInvitation: Panic during transaction, rolling back: %v", r)
			rollbackErr := s.groupRepo.RollbackTx(tx)
			if rollbackErr != nil {
				log.Printf("CreateGroupInvitation: Error during rollback after panic: %v", rollbackErr)
			}
			panic(r)
		} else if err != nil {
			log.Printf("CreateGroupInvitation: Transaction failed, rolling back: %v", err)
			rollbackErr := s.groupRepo.RollbackTx(tx)
			if rollbackErr != nil {
				log.Printf("CreateGroupInvitation: Error during rollback: %v", rollbackErr)
			}
		}
	}()

	const maxAttempts = 5
	var invitationCode string
	var isUnique bool

	for i := 0; i < maxAttempts; i++ {
		invitationCode = uuid.New().String()

		isUnique, err = s.groupRepo.GroupInvitation().CheckInvitationExistsByCode(ctx, tx, invitationCode)
		if err != nil {
			log.Printf("CreateGroupInvitation: Failed to check invitation code uniqueness: %v", err)
			err = status.Errorf(codes.Internal, "Failed to generate unique invitation code")
			return nil, err
		}
		if !isUnique {
			break
		}
		log.Printf("CreateGroupInvitation: Generated invitation code %s is not unique, retrying...", invitationCode)
		time.Sleep(50 * time.Millisecond)
	}

	if isUnique {
		log.Printf("CreateGroupInvitation: Failed to generate unique invitation code after %d attempts", maxAttempts)
		err = status.Errorf(codes.Internal, "Failed to generate unique invitation code")
		return nil, err
	}

	invitationModel := &models.GroupInvitation{
		GroupID:         uint(groupID),
		InvitationCode:  invitationCode,
		CreatedByUserID: uint(requestingUserID),
		ExpiresAt:       expiresAt,
	}

	err = s.groupRepo.GroupInvitation().CreateInvitation(ctx, tx, invitationModel)
	if err != nil {
		if errors.Is(err, gorm.ErrDuplicatedKey) {
			log.Printf("CreateGroupInvitation: Duplicate key error creating invitation (should not happen): %v", err)
			err = status.Errorf(codes.Internal, "Failed to create invitation code (unique constraint violated)")
			return nil, err
		}
		log.Printf("CreateGroupInvitation: Failed to create invitation in DB: %v", err)
		err = status.Errorf(codes.Internal, "Failed to create group invitation")
		return nil, err
	}

	// **Если создание успешно, фиксируем транзакцию**
	err = s.groupRepo.CommitTx(tx)
	if err != nil {
		log.Printf("CreateGroupInvitation: Failed to commit transaction: %v", err)
		return nil, status.Errorf(codes.Internal, "Internal error finalizing invitation creation")
	}

	// 5. Формирование успешного ответа
	// Преобразуем модель БД в protobuf сообщение
	responseInvitation := &pb.GroupInvitation{
		Id:              uint64(invitationModel.ID),
		GroupId:         uint64(invitationModel.GroupID),
		InvitationCode:  invitationModel.InvitationCode,
		CreatedByUserId: uint64(invitationModel.CreatedByUserID),
		CreatedAt:       timestamppb.New(invitationModel.CreatedAt),
		ExpiresAt:       timestamppb.New(invitationModel.ExpiresAt),
	}

	log.Printf("CreateGroupInvitation: Successfully created invitation %s for group %d by user %d", invitationCode, groupID, requestingUserID)

	return &pb.CreateGroupInvitationResponse{Invitation: responseInvitation}, nil
}

// AcceptGroupInvitation реализует RPC метод принятия приглашения в группу
func (s *GroupService) AcceptGroupInvitation(ctx context.Context, req *pb.AcceptGroupInvitationRequest) (*pb.AcceptGroupInvitationResponse, error) {
	// 1. Валидация входных данных
	invitationCode := req.GetInvitationCode()
	if invitationCode == "" {
		log.Printf("AcceptGroupInvitation: Invalid argument: invitation_code is missing")
		return nil, status.Errorf(codes.InvalidArgument, "Invitation code is required")
	}
	requestingUserID := req.GetRequestingUserId()
	if requestingUserID <= 0 {
		log.Printf("AcceptGroupInvitation: requesting_user_id is missing or invalid: %d", requestingUserID)
		return nil, status.Errorf(codes.Unauthenticated, "User ID is required")
	}

	// 2. Получение информации о приглашении по коду
	// Эта операция только чтение, транзакция пока не нужна.
	// Репозиторий должен вернуть только активные приглашения (не истекшие, не удаленные).
	invitationModel, err := s.groupRepo.GroupInvitation().GetInvitationByCode(ctx, nil, invitationCode)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			// Приглашение не найдено или истекло
			log.Printf("AcceptGroupInvitation: Invitation not found or expired: %s", invitationCode)
			return nil, status.Errorf(codes.NotFound, "Invitation not found or expired")
		}
		// Другая ошибка БД - внутренняя
		log.Printf("AcceptGroupInvitation: Failed to get invitation by code %s from DB: %v", invitationCode, err)
		return nil, status.Errorf(codes.Internal, "Failed to retrieve invitation information")
	}

	// Убедимся, что пользователь, принимающий приглашение, еще не является участником этой группы.
	// Этот запрос только чтение, транзакция пока не нужна.
	_, err = s.groupRepo.GroupMember().GetMemberByGroupAndUser(ctx, nil, invitationModel.GroupID, uint(requestingUserID))
	if err == nil {
		// Пользователь УЖЕ является участником этой группы.
		log.Printf("AcceptGroupInvitation: User %d is already a member of group %d", requestingUserID, invitationModel.GroupID)
		// Возвращаем ошибку, указывающую на конфликт.
		// Можно вернуть информацию о существующем участии в ответе, если нужно.
		// responseMember := &pb.GroupMember{... из existingMember ...}
		return nil, status.Errorf(codes.AlreadyExists, "You are already a member of this group")
	} else if !errors.Is(err, gorm.ErrRecordNotFound) {
		// Другая ошибка БД при проверке членства - внутренняя
		log.Printf("AcceptGroupInvitation: Failed to check existing membership for user %d in group %d: %v", requestingUserID, invitationModel.GroupID, err)
		return nil, status.Errorf(codes.Internal, "Failed to check existing membership")
	}

	// 3. Создаем запись об участии пользователя в группе
	tx, err := s.groupRepo.BeginTx(ctx)
	if err != nil {
		log.Printf("AcceptGroupInvitation: Failed to start transaction: %v", err)
		return nil, status.Errorf(codes.Internal, "Internal error starting transaction")
	}
	defer func() {
		if r := recover(); r != nil {
			log.Printf("AcceptGroupInvitation: Panic during transaction, rolling back: %v", r)
			rollbackErr := s.groupRepo.RollbackTx(tx)
			if rollbackErr != nil {
				log.Printf("AcceptGroupInvitation: Error during rollback after panic: %v", rollbackErr)
			}
			panic(r)
		} else if err != nil {
			log.Printf("AcceptGroupInvitation: Transaction failed, rolling back: %v", err)
			rollbackErr := s.groupRepo.RollbackTx(tx)
			if rollbackErr != nil {
				log.Printf("AcceptGroupInvitation: Error during rollback: %v", rollbackErr)
			}
		}
	}()

	// Создаем модель участника
	newMemberModel := &models.GroupMember{
		GroupID:             invitationModel.GroupID, // ID группы из приглашения
		UserID:              uint(requestingUserID),  // ID пользователя, принимающего приглашение
		IsAdmin:             false,                   // Новый участник по умолчанию не администратор
		MemoriesAddedCount:  0,
		MemoriesViewedCount: 0,
	}

	// Создаем запись участника в базе данных (используем транзакционный tx)
	err = s.groupRepo.GroupMember().CreateMember(ctx, tx, newMemberModel)
	if err != nil {
		// Обработка ошибки дубликата - хотя мы уже проверили выше,
		// возможна race condition, если два запроса придут почти одновременно.
		if errors.Is(err, gorm.ErrDuplicatedKey) {
			log.Printf("AcceptGroupInvitation: Duplicate member error creating member: User %d already in group %d (race condition?)", requestingUserID, invitationModel.GroupID)
			err = status.Errorf(codes.AlreadyExists, "You are already a member of this group") // Сообщаем клиенту, что он уже участник
			return nil, err
		}
		// Другие ошибки БД - внутренние
		log.Printf("AcceptGroupInvitation: Failed to create new member in DB: %v", err)
		err = status.Errorf(codes.Internal, "Failed to join group")
		return nil, err
	}

	// TODO: Отправить уведомление остальным участникам группы

	// **Если операции успешны, фиксируем транзакцию**
	err = s.groupRepo.CommitTx(tx)
	if err != nil {
		log.Printf("AcceptGroupInvitation: Failed to commit transaction: %v", err)
		return nil, status.Errorf(codes.Internal, "Internal error finalizing invitation acceptance")
	}

	// 4. Формирование успешного ответа
	// Получаем модель группы для возврата в ответе (если требуется)
	groupModel, err := s.groupRepo.Group().GetGroupByID(ctx, nil, newMemberModel.GroupID)
	if err != nil {
		// Группа не найдена после принятия - неконсистентность данных.
		log.Printf("AcceptGroupInvitation: Group %d not found after member creation %d: %v", newMemberModel.GroupID, newMemberModel.ID, err)
		// Можем вернуть частичный ответ или ошибку. Возвращаем ошибку.
		return nil, status.Errorf(codes.Internal, "Internal error retrieving group details after joining")
	}

	responseMember := &pb.GroupMember{ // Используем структуру pb.GroupMember
		Id:                  uint64(newMemberModel.ID),
		GroupId:             uint64(newMemberModel.GroupID),
		UserId:              uint64(newMemberModel.UserID),
		IsAdmin:             newMemberModel.IsAdmin,
		MemoriesAddedCount:  uint64(newMemberModel.MemoriesAddedCount),
		MemoriesViewedCount: uint64(newMemberModel.MemoriesViewedCount),
		CreatedAt:           timestamppb.New(newMemberModel.CreatedAt),
		UpdatedAt:           timestamppb.New(newMemberModel.UpdatedAt),
	}
	responseGroup := &pb.Group{ // Используем структуру pb.Group
		Id:          uint64(groupModel.ID),
		Name:        groupModel.Name,
		Image:       groupModel.Image,
		AdminUserId: uint64(groupModel.AdminUserID),
		CreatedAt:   timestamppb.New(groupModel.CreatedAt),
		UpdatedAt:   timestamppb.New(groupModel.UpdatedAt),
	}

	return &pb.AcceptGroupInvitationResponse{
		GroupMember: responseMember,
		Group:       responseGroup,
	}, nil
}

// ListUserGroups реализует RPC метод получения списка групп пользователя
func (s *GroupService) ListUserGroups(ctx context.Context, req *pb.ListUserGroupsRequest) (*pb.ListUserGroupsResponse, error) {
	// 1. Валидация входных данных
	userID := req.GetUserId()
	if userID <= 0 {
		log.Printf("ListUserGroups: Invalid argument: user_id is missing or invalid: %d", userID)
		return nil, status.Errorf(codes.InvalidArgument, "Invalid user ID")
	}

	// 2. Получение списка групп пользователя из репозитория
	groupModels, err := s.groupRepo.GroupMember().ListGroupsByUserID(ctx, nil, uint(userID))
	if err != nil {
		log.Printf("ListUserGroups: Failed to get groups for user %d from DB: %v", userID, err)
		return nil, status.Errorf(codes.Internal, "Failed to retrieve user groups")
	}

	// 3. Формирование успешного ответа
	responseGroups := make([]*pb.Group, 0, len(groupModels))
	for _, groupModel := range groupModels {
		responseGroups = append(responseGroups, &pb.Group{
			Id:          uint64(groupModel.ID),
			Name:        groupModel.Name,
			Image:       groupModel.Image,
			AdminUserId: uint64(groupModel.AdminUserID),
			CreatedAt:   timestamppb.New(groupModel.CreatedAt),
			UpdatedAt:   timestamppb.New(groupModel.UpdatedAt),
		})
	}

	return &pb.ListUserGroupsResponse{Groups: responseGroups}, nil
}
