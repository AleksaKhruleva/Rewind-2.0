package memory

import (
	pb "Rewind-api-gateway-service/pkg/proto"
	"context"
	"fmt"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"log"
	"os"
)

// MemoryServiceClient представляет собой gRPC-клиент для сервиса воспоминаний.
type MemoryServiceClient struct {
	client pb.MemoryServiceClient
	conn   *grpc.ClientConn
}

// NewMemoryServiceClient создает новый клиент сервиса воспоминаний.
func NewMemoryServiceClient() (*MemoryServiceClient, error) {
	memoryServiceAddress := os.Getenv("MEMORY_SERVICE_GRPC_ADDRESS")
	if memoryServiceAddress == "" {
		memoryServiceAddress = "localhost:50053" // Значение по умолчанию
		log.Println("Warning: MEMORY_SERVICE_GRPC_ADDRESS environment variable not set, using default.")
	}

	conn, err := grpc.Dial(memoryServiceAddress, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		return nil, fmt.Errorf("failed to connect to memory-service: %w", err)
	}

	client := pb.NewMemoryServiceClient(conn)

	return &MemoryServiceClient{
		client: client,
		conn:   conn,
	}, nil
}

// Close закрывает соединение с gRPC сервером.
func (c *MemoryServiceClient) Close() error {
	if c.conn != nil {
		return c.conn.Close()
	}
	return nil
}

// CreateMemory вызывает RPC метод CreateMemory в Memory-Service.
func (c *MemoryServiceClient) CreateMemory(ctx context.Context, in *pb.CreateMemoryRequest, opts ...grpc.CallOption) (*pb.CreateMemoryResponse, error) {
	return c.client.CreateMemory(ctx, in, opts...)
}

// DeleteMemory вызывает RPC метод DeleteMemory в Memory-Service.
func (c *MemoryServiceClient) DeleteMemory(ctx context.Context, in *pb.DeleteMemoryRequest, opts ...grpc.CallOption) (*pb.DeleteMemoryResponse, error) {
	return c.client.DeleteMemory(ctx, in, opts...)
}

// DeleteMemoriesByGroup вызывает RPC метод DeleteMemoriesByGroup в Memory-Service.
func (c *MemoryServiceClient) DeleteMemoriesByGroup(ctx context.Context, in *pb.DeleteMemoriesByGroupRequest, opts ...grpc.CallOption) (*pb.DeleteMemoriesByGroupResponse, error) {
	return c.client.DeleteMemoriesByGroup(ctx, in, opts...)
}

// ListMemoriesByGroup вызывает RPC метод ListMemoriesByGroup в Memory-Service.
func (c *MemoryServiceClient) ListMemoriesByGroup(ctx context.Context, in *pb.ListMemoriesByGroupRequest, opts ...grpc.CallOption) (*pb.ListMemoriesByGroupResponse, error) {
	return c.client.ListMemoriesByGroup(ctx, in, opts...)
}

// ListMemoriesByGroupWithFilters вызывает RPC метод ListMemoriesByGroupWithFilters в Memory-Service.
func (c *MemoryServiceClient) ListMemoriesByGroupWithFilters(ctx context.Context, in *pb.ListMemoriesByGroupWithFiltersRequest, opts ...grpc.CallOption) (*pb.ListMemoriesByGroupWithFiltersResponse, error) {
	return c.client.ListMemoriesByGroupWithFilters(ctx, in, opts...)
}

// CreateMemoryTag вызывает RPC метод CreateMemoryTag в Memory-Service.
func (c *MemoryServiceClient) CreateMemoryTag(ctx context.Context, in *pb.CreateMemoryTagRequest, opts ...grpc.CallOption) (*pb.CreateMemoryTagResponse, error) {
	return c.client.CreateMemoryTag(ctx, in, opts...)
}

// DeleteMemoryTag вызывает RPC метод DeleteMemoryTag в Memory-Service.
func (c *MemoryServiceClient) DeleteMemoryTag(ctx context.Context, in *pb.DeleteMemoryTagRequest, opts ...grpc.CallOption) (*pb.DeleteMemoryTagResponse, error) {
	return c.client.DeleteMemoryTag(ctx, in, opts...)
}

// ListMemoryTagsByMemoryID вызывает RPC метод ListMemoryTagsByMemoryID в Memory-Service.
func (c *MemoryServiceClient) ListMemoryTagsByMemoryID(ctx context.Context, in *pb.ListMemoryTagsByMemoryIDRequest, opts ...grpc.CallOption) (*pb.ListMemoryTagsByMemoryIDResponse, error) {
	return c.client.ListMemoryTagsByMemoryID(ctx, in, opts...)
}

// CreateFavourite вызывает RPC метод CreateFavourite в Memory-Service.
func (c *MemoryServiceClient) CreateFavourite(ctx context.Context, in *pb.CreateFavouriteRequest, opts ...grpc.CallOption) (*pb.CreateFavouriteResponse, error) {
	return c.client.CreateFavourite(ctx, in, opts...)
}

// DeleteFavourite вызывает RPC метод DeleteFavourite в Memory-Service.
func (c *MemoryServiceClient) DeleteFavourite(ctx context.Context, in *pb.DeleteFavouriteRequest, opts ...grpc.CallOption) (*pb.DeleteFavouriteResponse, error) {
	return c.client.DeleteFavourite(ctx, in, opts...)
}

// DeleteFavouritesByUserID вызывает RPC метод DeleteFavouritesByUserID в Memory-Service.
func (c *MemoryServiceClient) DeleteFavouritesByUserID(ctx context.Context, in *pb.DeleteFavouritedByUserIDRequest, opts ...grpc.CallOption) (*pb.DeleteFavouritedByUserIDResponse, error) {
	return c.client.DeleteFavouritesByUserID(ctx, in, opts...)
}
