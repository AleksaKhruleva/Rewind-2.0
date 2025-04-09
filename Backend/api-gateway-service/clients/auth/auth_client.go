package auth

import (
	"fmt"
	"log"
	"os"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	pb "Rewind-api-gateway-service/pkg/proto"
)

// AuthServiceClient представляет собой gRPC-клиент для сервиса аутентификации.
type AuthServiceClient struct {
	client pb.AuthServiceClient
	conn   *grpc.ClientConn
}

// NewAuthServiceClient создает новый клиент сервиса аутентификации.
func NewAuthServiceClient() (*AuthServiceClient, error) {
	authServiceAddress := os.Getenv("AUTH_SERVICE_GRPC_ADDRESS")
	if authServiceAddress == "" {
		authServiceAddress = "localhost:50051" // Значение по умолчанию
		log.Println("Warning: AUTH_SERVICE_GRPC_ADDRESS environment variable not set, using default.")
	}

	conn, err := grpc.NewClient(authServiceAddress, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		return nil, fmt.Errorf("failed to connect to auth-service: %w", err)
	}

	client := pb.NewAuthServiceClient(conn)

	return &AuthServiceClient{
		client: client,
		conn:   conn,
	}, nil
}

// Close закрывает gRPC соединение.
func (c *AuthServiceClient) Close() error {
	return c.conn.Close()
}

// // Пример вызова метода Register (закомментировано, вы раскомментируете и реализуете нужные методы)
// func (c *AuthServiceClient) Register(ctx context.Context, req *pb.RegisterRequest) (*pb.RegisterResponse, error) {
// 	return c.client.Register(ctx, req)
// }

// // Добавьте здесь методы для остальных эндпоинтов auth-service, которые вам нужны
// // Например, Login, Refresh, VerifyEmail и т.д.
