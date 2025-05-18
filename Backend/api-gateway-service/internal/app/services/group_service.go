package services

import (
	"context"
	"fmt"
	"log"
	"time"

	"google.golang.org/protobuf/types/known/durationpb"
	"google.golang.org/protobuf/types/known/wrapperspb" // Для Optional string

	authClient "Rewind-api-gateway-service/clients/auth"   // Путь к gRPC клиенту Auth-Service (если нужен для обогащения данных)
	groupClient "Rewind-api-gateway-service/clients/group" // Путь к gRPC клиенту Group-Service
	pb "Rewind-api-gateway-service/pkg/proto"              // Путь к сгенерированным protobuf сообщениям (общие для API GW и микросервисов)
)

// GroupServiceInterface определяет методы для взаимодействия с Group-Service
// через сервисный слой API Gateway.
// Методы принимают простые типы данных и возвращают protobuf сообщения от микросервиса.
type GroupServiceInterface interface {
	CreateGroup(ctx context.Context, requestingUserID uint64, name string, imageURL string) (*pb.CreateGroupResponse, error)

	GetGroup(ctx context.Context, requestingUserID uint64, groupID uint64) (*pb.GetGroupResponse, error)

	UpdateGroup(ctx context.Context, requestingUserID uint64, groupID uint64, name *string, image *string) (*pb.UpdateGroupResponse, error)

	DeleteGroup(ctx context.Context, requestingUserID uint64, groupID uint64) (*pb.DeleteGroupResponse, error)

	ListGroupMembers(ctx context.Context, requestingUserID uint64, groupID uint64) (*pb.ListGroupMembersResponse, error)

	RemoveGroupMember(ctx context.Context, requestingUserID uint64, groupID uint64, userToRemoveID uint64) (*pb.RemoveGroupMemberResponse, error)

	CreateGroupInvitation(ctx context.Context, requestingUserID uint64, groupID uint64, duration *time.Duration) (*pb.CreateGroupInvitationResponse, error)

	AcceptGroupInvitation(ctx context.Context, requestingUserID uint64, invitationCode string) (*pb.AcceptGroupInvitationResponse, error)

	ListUserGroups(ctx context.Context, userID uint64) (*pb.ListUserGroupsResponse, error)
}

// GroupService представляет сервис для взаимодействия с Group-Service через gRPC.
type GroupService struct {
	groupClient *groupClient.GroupServiceClient // gRPC клиент для Group-Service
	authClient  *authClient.AuthServiceClient   // gRPC клиент для Auth-Service
}

// NewGroupService создает новый экземпляр GroupService.
// Принимает gRPC клиенты необходимых микросервисов.
func NewGroupService(groupClient *groupClient.GroupServiceClient, authClient *authClient.AuthServiceClient) GroupServiceInterface {
	return &GroupService{
		groupClient: groupClient,
		authClient:  authClient,
	}
}

// CreateGroup вызывает RPC метод CreateGroup в Group-Service.
func (s *GroupService) CreateGroup(ctx context.Context, requestingUserID uint64, name string, imageURL string) (*pb.CreateGroupResponse, error) {
	log.Printf("API GW GroupService: Calling CreateGroup RPC for user %d, group %s", requestingUserID, name)

	req := &pb.CreateGroupRequest{
		RequestingUserId: requestingUserID,
		Name:             name,
		Image:            imageURL,
	}

	resp, err := s.groupClient.CreateGroup(ctx, req)
	if err != nil {
		log.Printf("API GW GroupService: CreateGroup gRPC error: %v", err)
		return nil, fmt.Errorf("group service error: %w", err)
	}

	return resp, nil
}

// GetGroup вызывает RPC метод GetGroup в Group-Service.
func (s *GroupService) GetGroup(ctx context.Context, requestingUserID uint64, groupID uint64) (*pb.GetGroupResponse, error) {
	log.Printf("API GW GroupService: Calling GetGroup RPC for user %d, group %d", requestingUserID, groupID)
	req := &pb.GetGroupRequest{
		RequestingUserId: requestingUserID,
		GroupId:          groupID,
	}

	resp, err := s.groupClient.GetGroup(ctx, req)
	if err != nil {
		log.Printf("API GW GroupService: GetGroup gRPC error for group %d: %v", groupID, err)
		return nil, fmt.Errorf("group service error: %w", err)
	}

	return resp, nil
}

// UpdateGroup вызывает RPC метод UpdateGroup в Group-Service.
func (s *GroupService) UpdateGroup(ctx context.Context, requestingUserID uint64, groupID uint64, name *string, image *string) (*pb.UpdateGroupResponse, error) {
	log.Printf("API GW GroupService: Calling UpdateGroup RPC for user %d, group %d", requestingUserID, groupID)

	req := &pb.UpdateGroupRequest{
		RequestingUserId: requestingUserID,
		GroupId:          groupID,
	}

	if name != nil {
		req.Name = wrapperspb.String(*name)
	}
	if image != nil {
		req.Image = wrapperspb.String(*image)
	}

	resp, err := s.groupClient.UpdateGroup(ctx, req)
	if err != nil {
		log.Printf("API GW GroupService: UpdateGroup gRPC error for group %d: %v", groupID, err)
		return nil, fmt.Errorf("group service error: %w", err)
	}

	return resp, nil
}

// DeleteGroup вызывает RPC метод DeleteGroup в Group-Service.
func (s *GroupService) DeleteGroup(ctx context.Context, requestingUserID uint64, groupID uint64) (*pb.DeleteGroupResponse, error) {
	log.Printf("API GW GroupService: Calling DeleteGroup RPC for user %d, group %d", requestingUserID, groupID)

	req := &pb.DeleteGroupRequest{
		RequestingUserId: requestingUserID,
		GroupId:          groupID,
	}

	resp, err := s.groupClient.DeleteGroup(ctx, req)
	if err != nil {
		log.Printf("API GW GroupService: DeleteGroup gRPC error for group %d: %v", groupID, err)
		return nil, fmt.Errorf("group service error: %w", err)
	}

	return resp, nil
}

// ListGroupMembers вызывает RPC метод ListGroupMembers в Group-Service.
// Group-Service, как предполагается, уже обогащает данные участников информацией о пользователях.
func (s *GroupService) ListGroupMembers(ctx context.Context, requestingUserID uint64, groupID uint64) (*pb.ListGroupMembersResponse, error) {
	log.Printf("API GW GroupService: Calling ListGroupMembers RPC for user %d, group %d", requestingUserID, groupID)

	req := &pb.ListGroupMembersRequest{
		RequestingUserId: requestingUserID,
		GroupId:          groupID,
	}

	resp, err := s.groupClient.ListGroupMembers(ctx, req)
	if err != nil {
		log.Printf("API GW GroupService: ListGroupMembers gRPC error for group %d: %v", groupID, err)
		return nil, fmt.Errorf("group service error: %w", err)
	}

	// Group-Service, как предполагается, уже вернул MemberDetails с UserDetails.
	// Если бы Group-Service возвращал только GroupMember, то здесь нужно было бы
	// вызвать Auth-Service.GetUsersByIDs для каждого участника и обогатить данные.
	return resp, nil
}

// RemoveGroupMember вызывает RPC метод RemoveGroupMember в Group-Service.
func (s *GroupService) RemoveGroupMember(ctx context.Context, requestingUserID uint64, groupID uint64, userToRemoveID uint64) (*pb.RemoveGroupMemberResponse, error) {
	log.Printf("API GW GroupService: Calling RemoveGroupMember RPC for user %d, group %d, removing %d", requestingUserID, groupID, userToRemoveID)

	req := &pb.RemoveGroupMemberRequest{
		RequestingUserId: requestingUserID,
		GroupId:          groupID,
		UserIdToRemove:   userToRemoveID,
	}

	resp, err := s.groupClient.RemoveGroupMember(ctx, req)
	if err != nil {
		log.Printf("API GW GroupService: RemoveGroupMember gRPC error for group %d: %v", groupID, err)
		return nil, fmt.Errorf("group service error: %w", err)
	}

	return resp, nil
}

// CreateGroupInvitation вызывает RPC метод CreateGroupInvitation в Group-Service.
func (s *GroupService) CreateGroupInvitation(ctx context.Context, requestingUserID uint64, groupID uint64, duration *time.Duration) (*pb.CreateGroupInvitationResponse, error) {
	log.Printf("API GW GroupService: Calling CreateGroupInvitation RPC for user %d, group %d", requestingUserID, groupID)

	var durationPb *durationpb.Duration
	if duration != nil {
		durationPb = durationpb.New(*duration)
	}

	req := &pb.CreateGroupInvitationRequest{
		RequestingUserId: requestingUserID,
		GroupId:          groupID,
		Duration:         durationPb,
	}

	resp, err := s.groupClient.CreateGroupInvitation(ctx, req)
	if err != nil {
		log.Printf("API GW GroupService: CreateGroupInvitation gRPC error for group %d: %v", groupID, err)
		return nil, fmt.Errorf("group service error: %w", err)
	}

	return resp, nil
}

// AcceptGroupInvitation вызывает RPC метод AcceptGroupInvitation в Group-Service.
func (s *GroupService) AcceptGroupInvitation(ctx context.Context, requestingUserID uint64, invitationCode string) (*pb.AcceptGroupInvitationResponse, error) {
	log.Printf("API GW GroupService: Calling AcceptGroupInvitation RPC for user %d, code %s", requestingUserID, invitationCode)

	req := &pb.AcceptGroupInvitationRequest{
		RequestingUserId: requestingUserID,
		InvitationCode:   invitationCode,
	}

	resp, err := s.groupClient.AcceptGroupInvitation(ctx, req)
	if err != nil {
		log.Printf("API GW GroupService: AcceptGroupInvitation gRPC error for code %s: %v", invitationCode, err)
		return nil, fmt.Errorf("group service error: %w", err)
	}

	return resp, nil
}

// ListUserGroups вызывает RPC метод ListUserGroups в Group-Service.
func (s *GroupService) ListUserGroups(ctx context.Context, userID uint64) (*pb.ListUserGroupsResponse, error) {
	log.Printf("API GW GroupService: Calling ListUserGroups RPC for user %d", userID)

	req := &pb.ListUserGroupsRequest{
		UserId: userID,
	}

	resp, err := s.groupClient.ListUserGroups(ctx, req)
	if err != nil {
		log.Printf("API GW GroupService: ListUserGroups gRPC error for user %d: %v", userID, err)
		return nil, fmt.Errorf("group service error: %w", err)
	}

	return resp, nil
}
