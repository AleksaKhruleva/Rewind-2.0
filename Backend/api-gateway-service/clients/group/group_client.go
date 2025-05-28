package group

import (
	"context"
	"fmt"
	"log"
	"os"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	pb "Rewind-api-gateway-service/pkg/proto"
)

// GroupServiceClient представляет собой gRPC-клиент для сервиса аутентификации.
type GroupServiceClient struct {
	client pb.GroupServiceClient
	conn   *grpc.ClientConn
}

// NewGroupServiceClient создает новый клиент сервиса аутентификации.
func NewGroupServiceClient() (*GroupServiceClient, error) {
	groupServiceAddress := os.Getenv("GROUP_SERVICE_GRPC_ADDRESS")
	if groupServiceAddress == "" {
		groupServiceAddress = "localhost:50052" // Значение по умолчанию
		log.Println("Warning: GROUP_SERVICE_GRPC_ADDRESS environment variable not set, using default.")
	}

	conn, err := grpc.NewClient(groupServiceAddress, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		return nil, fmt.Errorf("failed to connect to group-service: %w", err)
	}

	client := pb.NewGroupServiceClient(conn)

	return &GroupServiceClient{
		client: client,
		conn:   conn,
	}, nil
}

// Close закрывает соединение с gRPC сервером.
func (c *GroupServiceClient) Close() error {
	if c.conn != nil {
		return c.conn.Close()
	}
	return nil
}

// CreateGroup вызывает RPC метод CreateGroup в Group-Service.
func (c *GroupServiceClient) CreateGroup(ctx context.Context, in *pb.CreateGroupRequest, opts ...grpc.CallOption) (*pb.CreateGroupResponse, error) {
	return c.client.CreateGroup(ctx, in, opts...)
}

// GetGroup вызывает RPC метод GetGroup в Group-Service.
func (c *GroupServiceClient) GetGroup(ctx context.Context, in *pb.GetGroupRequest, opts ...grpc.CallOption) (*pb.GetGroupResponse, error) {
	return c.client.GetGroup(ctx, in, opts...)
}

// UpdateGroup вызывает RPC метод UpdateGroup в Group-Service.
func (c *GroupServiceClient) UpdateGroup(ctx context.Context, in *pb.UpdateGroupRequest, opts ...grpc.CallOption) (*pb.UpdateGroupResponse, error) {
	return c.client.UpdateGroup(ctx, in, opts...)
}

// DeleteGroup вызывает RPC метод DeleteGroup в Group-Service.
func (c *GroupServiceClient) DeleteGroup(ctx context.Context, in *pb.DeleteGroupRequest, opts ...grpc.CallOption) (*pb.DeleteGroupResponse, error) {
	return c.client.DeleteGroup(ctx, in, opts...)
}

// DeleteGroupAvatar вызывает RPC метод DeleteGroupAvatar в Group-Service.
func (c *GroupServiceClient) DeleteGroupAvatar(ctx context.Context, in *pb.DeleteGroupAvatarRequest, opts ...grpc.CallOption) (*pb.DeleteGroupAvatarResponse, error) {
	return c.client.DeleteGroupAvatar(ctx, in, opts...)
}

// ListGroupMembers вызывает RPC метод ListGroupMembers в Group-Service.
func (c *GroupServiceClient) ListGroupMembers(ctx context.Context, in *pb.ListGroupMembersRequest, opts ...grpc.CallOption) (*pb.ListGroupMembersResponse, error) {
	return c.client.ListGroupMembers(ctx, in, opts...)
}

// RemoveGroupMember вызывает RPC метод RemoveGroupMember в Group-Service.
func (c *GroupServiceClient) RemoveGroupMember(ctx context.Context, in *pb.RemoveGroupMemberRequest, opts ...grpc.CallOption) (*pb.RemoveGroupMemberResponse, error) {
	return c.client.RemoveGroupMember(ctx, in, opts...)
}

// CreateGroupInvitation вызывает RPC метод CreateGroupInvitation в Group-Service.
func (c *GroupServiceClient) CreateGroupInvitation(ctx context.Context, in *pb.CreateGroupInvitationRequest, opts ...grpc.CallOption) (*pb.CreateGroupInvitationResponse, error) {
	return c.client.CreateGroupInvitation(ctx, in, opts...)
}

// AcceptGroupInvitation вызывает RPC метод AcceptGroupInvitation в Group-Service.
func (c *GroupServiceClient) AcceptGroupInvitation(ctx context.Context, in *pb.AcceptGroupInvitationRequest, opts ...grpc.CallOption) (*pb.AcceptGroupInvitationResponse, error) {
	return c.client.AcceptGroupInvitation(ctx, in, opts...)
}

// ListUserGroups вызывает RPC метод ListUserGroups в Group-Service.
func (c *GroupServiceClient) ListUserGroups(ctx context.Context, in *pb.ListUserGroupsRequest, opts ...grpc.CallOption) (*pb.ListUserGroupsResponse, error) {
	return c.client.ListUserGroups(ctx, in, opts...)
}

// CheckUserInGroup вызывает RPC метод CheckUserInGroup в Group-Service
func (c *GroupServiceClient) CheckUserInGroup(ctx context.Context, in *pb.CheckUserInGroupRequest, opts ...grpc.CallOption) (*pb.CheckUserInGroupResponse, error) {
	return c.client.CheckUserInGroup(ctx, in, opts...)
}
