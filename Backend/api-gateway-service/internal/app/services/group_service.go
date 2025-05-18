package services

import (
	"context"
	"log"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/durationpb"

	authClient "Rewind-api-gateway-service/clients/auth"
	groupClient "Rewind-api-gateway-service/clients/group"
	pb "Rewind-api-gateway-service/pkg/proto"
)

type ContextKey string

// ContextKeyUserID is the key used to store the user ID in the context.
const ContextKeyUserID ContextKey = "userID"

// GroupServiceInterface определяет методы для взаимодействия с Group-Service
// через сервисный слой API Gateway.
// Методы принимают простые типы данных и возвращают protobuf сообщения от микросервиса.
// ID запрашивающего пользователя извлекается из контекста.
type GroupServiceInterface interface {
	CreateGroup(ctx context.Context, name string, imageURL string) (*pb.CreateGroupResponse, error)
	GetGroup(ctx context.Context, groupID uint64) (*pb.GetGroupResponse, error)
	UpdateGroup(ctx context.Context, groupID uint64, name *string, image *string) (*pb.UpdateGroupResponse, error)
	DeleteGroup(ctx context.Context, groupID uint64) (*pb.DeleteGroupResponse, error)
	ListGroupMembers(ctx context.Context, groupID uint64) (*pb.ListGroupMembersResponse, error)
	RemoveGroupMember(ctx context.Context, groupID uint64, userToRemoveID uint64) (*pb.RemoveGroupMemberResponse, error)
	CreateGroupInvitation(ctx context.Context, groupID uint64, duration *time.Duration) (*pb.CreateGroupInvitationResponse, error)
	AcceptGroupInvitation(ctx context.Context, invitationCode string) (*pb.AcceptGroupInvitationResponse, error)
	ListUserGroups(ctx context.Context) (*pb.ListUserGroupsResponse, error)
}

// GroupService представляет сервис для взаимодействия с Group-Service через gRPC.
type GroupService struct {
	groupClient *groupClient.GroupServiceClient
	authClient  *authClient.AuthServiceClient
}

// NewGroupService создает новый экземпляр GroupService.
// Принимает gRPC клиенты необходимых микросервисов.
func NewGroupService(groupClient *groupClient.GroupServiceClient, authClient *authClient.AuthServiceClient) GroupServiceInterface {
	return &GroupService{
		groupClient: groupClient,
		authClient:  authClient,
	}
}

// getRequestingUserIDFromContext извлекает ID пользователя из контекста.
// Возвращает ID пользователя и ошибку, если ID отсутствует или имеет неверный тип.
func (s *GroupService) getRequestingUserIDFromContext(ctx context.Context) (uint64, error) {
	userID, ok := ctx.Value(ContextKeyUserID).(uint64)
	if !ok || userID == 0 {
		return 0, status.Errorf(codes.Unauthenticated, "user ID not found in context")
	}
	return userID, nil
}

// verifyUserExists проверяет существование пользователя в Auth-Service.
// Может быть использован для дополнительной проверки перед выполнением операций.
// Возвращает ошибку gRPC NotFound, если пользователь не найден, или Internal, если произошла ошибка Auth-Service.
func (s *GroupService) verifyUserExists(ctx context.Context, userID uint64) error {
	req := &pb.GetUserByIDRequest{UserId: userID}
	resp, err := s.authClient.GetUserByID(ctx, req)
	if err != nil {
		log.Printf("API GW GroupService: Failed to call AuthService.GetUserByID for user %d: %v", userID, err)
		return status.Errorf(codes.Internal, "auth service error: %v", status.Convert(err).Message())
	}

	if resp == nil {
		log.Printf("API GW GroupService: User %d not found in AuthService", userID)
		return status.Errorf(codes.NotFound, "user not found")
	}

	return nil
}

// CreateGroup вызывает RPC метод CreateGroup в Group-Service.
func (s *GroupService) CreateGroup(ctx context.Context, name string, imageURL string) (*pb.CreateGroupResponse, error) {
	requestingUserID, err := s.getRequestingUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}
	log.Printf("API GW GroupService: Calling CreateGroup RPC for user %d, group %s", requestingUserID, name)

	if err := s.verifyUserExists(ctx, requestingUserID); err != nil {
		return nil, err
	}

	req := &pb.CreateGroupRequest{
		RequestingUserId: requestingUserID,
		Name:             name,
		Image:            imageURL,
	}

	return s.groupClient.CreateGroup(ctx, req)
}

// GetGroup вызывает RPC метод GetGroup в Group-Service.
func (s *GroupService) GetGroup(ctx context.Context, groupID uint64) (*pb.GetGroupResponse, error) {
	requestingUserID, err := s.getRequestingUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}
	log.Printf("API GW GroupService: Calling GetGroup RPC for user %d, group %d", requestingUserID, groupID)

	if err := s.verifyUserExists(ctx, requestingUserID); err != nil {
		return nil, err
	}

	req := &pb.GetGroupRequest{
		RequestingUserId: requestingUserID,
		GroupId:          groupID,
	}

	return s.groupClient.GetGroup(ctx, req)
}

// UpdateGroup вызывает RPC метод UpdateGroup в Group-Service.
func (s *GroupService) UpdateGroup(ctx context.Context, groupID uint64, name *string, image *string) (*pb.UpdateGroupResponse, error) {
	requestingUserID, err := s.getRequestingUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}
	log.Printf("API GW GroupService: Calling UpdateGroup RPC for user %d, group %d", requestingUserID, groupID)

	if err := s.verifyUserExists(ctx, requestingUserID); err != nil {
		return nil, err
	}

	req := &pb.UpdateGroupRequest{
		RequestingUserId: requestingUserID,
		GroupId:          groupID,
	}

	if name != nil {
		req.Name = name
	}
	if image != nil {
		req.Image = image
	}

	return s.groupClient.UpdateGroup(ctx, req)
}

// DeleteGroup вызывает RPC метод DeleteGroup в Group-Service.
func (s *GroupService) DeleteGroup(ctx context.Context, groupID uint64) (*pb.DeleteGroupResponse, error) {
	requestingUserID, err := s.getRequestingUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}
	log.Printf("API GW GroupService: Calling DeleteGroup RPC for user %d, group %d", requestingUserID, groupID)

	if err := s.verifyUserExists(ctx, requestingUserID); err != nil {
		return nil, err
	}

	req := &pb.DeleteGroupRequest{
		RequestingUserId: requestingUserID,
		GroupId:          groupID,
	}

	return s.groupClient.DeleteGroup(ctx, req)
}

// ListGroupMembers вызывает RPC метод ListGroupMembers в Group-Service.
// Group-Service, как предполагается, уже обогащает данные участников информацией о пользователях.
func (s *GroupService) ListGroupMembers(ctx context.Context, groupID uint64) (*pb.ListGroupMembersResponse, error) {
	requestingUserID, err := s.getRequestingUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}
	log.Printf("API GW GroupService: Calling ListGroupMembers RPC for user %d, group %d", requestingUserID, groupID)

	if err := s.verifyUserExists(ctx, requestingUserID); err != nil {
		return nil, err
	}

	req := &pb.ListGroupMembersRequest{
		RequestingUserId: requestingUserID,
		GroupId:          groupID,
	}

	return s.groupClient.ListGroupMembers(ctx, req)
}

// RemoveGroupMember вызывает RPC метод RemoveGroupMember в Group-Service.
func (s *GroupService) RemoveGroupMember(ctx context.Context, groupID uint64, userToRemoveID uint64) (*pb.RemoveGroupMemberResponse, error) {
	requestingUserID, err := s.getRequestingUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}
	log.Printf("API GW GroupService: Calling RemoveGroupMember RPC for user %d, group %d, removing %d", requestingUserID, groupID, userToRemoveID)

	if err := s.verifyUserExists(ctx, requestingUserID); err != nil {
		return nil, err
	}

	if requestingUserID != userToRemoveID {
		if err := s.verifyUserExists(ctx, userToRemoveID); err != nil {
			log.Printf("API GW GroupService: User to remove %d not found or auth service error: %v", userToRemoveID, err)
			return nil, err
		}
	}

	req := &pb.RemoveGroupMemberRequest{
		RequestingUserId: requestingUserID,
		GroupId:          groupID,
		UserIdToRemove:   userToRemoveID,
	}

	return s.groupClient.RemoveGroupMember(ctx, req)
}

// CreateGroupInvitation вызывает RPC метод CreateGroupInvitation в Group-Service.
func (s *GroupService) CreateGroupInvitation(ctx context.Context, groupID uint64, duration *time.Duration) (*pb.CreateGroupInvitationResponse, error) {
	requestingUserID, err := s.getRequestingUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}
	log.Printf("API GW GroupService: Calling CreateGroupInvitation RPC for user %d, group %d", requestingUserID, groupID)

	if err := s.verifyUserExists(ctx, requestingUserID); err != nil {
		return nil, err
	}

	var durationPb *durationpb.Duration
	if duration != nil {
		durationPb = durationpb.New(*duration)
	}

	req := &pb.CreateGroupInvitationRequest{
		RequestingUserId: requestingUserID,
		GroupId:          groupID,
		Duration:         durationPb,
	}

	return s.groupClient.CreateGroupInvitation(ctx, req)
}

// AcceptGroupInvitation вызывает RPC метод AcceptGroupInvitation в Group-Service.
func (s *GroupService) AcceptGroupInvitation(ctx context.Context, invitationCode string) (*pb.AcceptGroupInvitationResponse, error) {
	requestingUserID, err := s.getRequestingUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}
	log.Printf("API GW GroupService: Calling AcceptGroupInvitation RPC for user %d, code %s", requestingUserID, invitationCode)

	if err := s.verifyUserExists(ctx, requestingUserID); err != nil {
		return nil, err
	}

	req := &pb.AcceptGroupInvitationRequest{
		RequestingUserId: requestingUserID,
		InvitationCode:   invitationCode,
	}

	return s.groupClient.AcceptGroupInvitation(ctx, req)
}

// ListUserGroups вызывает RPC метод ListUserGroups в Group-Service.
func (s *GroupService) ListUserGroups(ctx context.Context) (*pb.ListUserGroupsResponse, error) {
	requestingUserID, err := s.getRequestingUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}
	log.Printf("API GW GroupService: Calling ListUserGroups RPC for user %d", requestingUserID)

	if err := s.verifyUserExists(ctx, requestingUserID); err != nil {
		return nil, err
	}

	req := &pb.ListUserGroupsRequest{
		UserId: requestingUserID,
	}

	return s.groupClient.ListUserGroups(ctx, req)
}
