package media

import (
	"context"
	"fmt"
	"log"
	"os"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	pb "Rewind-group-service/pkg/proto/clients"
)

// MediaServiceClient представляет собой gRPC-клиент для сервиса аутентификации.
type MediaServiceClient struct {
	client pb.MediaServiceClient
	conn   *grpc.ClientConn
}

// NewMediaServiceClient создает новый клиент сервиса аутентификации.
func NewMediaServiceClient() (*MediaServiceClient, error) {
	mediaServiceAddress := os.Getenv("MEDIA_SERVICE_GRPC_ADDRESS")
	if mediaServiceAddress == "" {
		mediaServiceAddress = "localhost:50055" // Значение по умолчанию
		log.Println("Warning: MEDIA_SERVICE_GRPC_ADDRESS environment variable not set, using default.")
	}

	conn, err := grpc.NewClient(mediaServiceAddress, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		return nil, fmt.Errorf("failed to connect to media-service: %w", err)
	}

	client := pb.NewMediaServiceClient(conn)

	return &MediaServiceClient{
		client: client,
		conn:   conn,
	}, nil
}

// Close закрывает gRPC соединение.
func (c *MediaServiceClient) Close() error {
	return c.conn.Close()
}

// UploadMedia вызывает метод UploadMedia сервиса аутентификации.
func (c *MediaServiceClient) UploadMedia(ctx context.Context, req *pb.UploadMediaRequest) (*pb.UploadMediaResponse, error) {
	return c.client.UploadMedia(ctx, req)
}
