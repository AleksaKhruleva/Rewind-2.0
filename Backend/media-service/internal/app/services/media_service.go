package services

import (
	"bytes"
	"context"
	"fmt"
	"log"
	"math/rand"
	"strings"
	"time"

	"github.com/aws/aws-sdk-go/aws"
	"github.com/aws/aws-sdk-go/aws/credentials"
	"github.com/aws/aws-sdk-go/aws/session"
	"github.com/aws/aws-sdk-go/service/s3"
	"github.com/gabriel-vasile/mimetype" // For better MIME detection
	"github.com/go-playground/validator/v10"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	pb "Rewind-media-service/pkg/proto"
)

// MediaService implements the media.MediaServiceServer interface
type MediaService struct {
	pb.UnimplementedMediaServiceServer
	validator         *validator.Validate
	s3Client          *s3.S3
	endpointURL       string                    // URL эндпоинта Yandex Object Storage
	bucketNames       map[pb.MediaType]string   // Map для хранения имен бакетов по MediaType
	allowedExtensions map[pb.MediaType][]string // Map для допустимых расширений
}

// NewMediaService создает новый экземпляр MediaService
func NewMediaService(
	validate *validator.Validate,
	endpointURL string,
	bucketNames map[pb.MediaType]string,
	allowedExtensions map[pb.MediaType][]string,
) (*MediaService, error) {
	cfg := &aws.Config{
		Endpoint:         aws.String(endpointURL),
		Region:           aws.String("ru-central1"),
		S3ForcePathStyle: aws.Bool(true), // важно для Yandex
		Credentials:      credentials.NewEnvCredentials(),
	}

	sess, err := session.NewSession(cfg)
	if err != nil {
		return nil, fmt.Errorf("failed to create S3 session: %w", err)
	}

	s3Client := s3.New(sess)

	return &MediaService{
		validator:         validate,
		s3Client:          s3Client,
		endpointURL:       endpointURL,
		bucketNames:       bucketNames,
		allowedExtensions: allowedExtensions,
	}, nil
}

// UploadMedia обрабатывает запрос на загрузку медиа файла
func (s *MediaService) UploadMedia(ctx context.Context, req *pb.UploadMediaRequest) (*pb.UploadMediaResponse, error) {
	if err := s.validator.Struct(req); err != nil {
		log.Printf("MediaService.UploadMedia: invalid request: %v", err)
		return nil, status.Errorf(codes.InvalidArgument, "invalid request: %v", err)
	}

	mediaType := req.GetMediaType()
	fileData := req.GetFileData()

	if len(fileData) == 0 {
		log.Println("MediaService.UploadMedia: empty file data")
		return nil, status.Error(codes.InvalidArgument, "empty file data")
	}

	// Получаем имя бакета для данного типа медиа
	bucketName, ok := s.bucketNames[mediaType]
	if !ok {
		log.Printf("MediaService.UploadMedia: no bucket configured for media type: %v", mediaType)
		return nil, status.Errorf(codes.InvalidArgument, "no bucket configured for media type: %v", mediaType)
	}

	// Определяем MIME type и расширение файла
	mimeType, err := getMIMEType(fileData)
	if err != nil {
		log.Printf("MediaService.UploadMedia: failed to determine MIME type: %v", err)
		return nil, status.Errorf(codes.InvalidArgument, "invalid file data")
	}

	fileExt := getExtensionFromMIMEType(mimeType)

	// Валидация расширения
	if !isExtensionAllowed(fileExt, mediaType, s.allowedExtensions) {
		log.Printf("MediaService.UploadMedia: disallowed file extension: %s for media type: %v", fileExt, mediaType)
		return nil, status.Errorf(codes.InvalidArgument, "disallowed file extension: %s", fileExt)
	}

	// Генерируем уникальное имя файла для S3
	timestamp := time.Now().Format("20060102150405")
	randomStr := generateRandomString(8)
	objectKey := fmt.Sprintf("%s_%s%s", timestamp, randomStr, fileExt)

	// Загрузка файла в Yandex Object Storage
	_, err = s.s3Client.PutObjectWithContext(ctx, &s3.PutObjectInput{
		Bucket:      aws.String(bucketName), // Используем bucketName, полученный из map
		Key:         aws.String(objectKey),
		Body:        bytes.NewReader(fileData),
		ContentType: aws.String(mimeType), // Use the detected MIME type
	})
	if err != nil {
		log.Printf("MediaService.UploadMedia: failed to upload to S3: %v", err)
		return nil, status.Errorf(codes.Internal, "failed to upload media")
	}

	fileURL := fmt.Sprintf("%s/%s/%s", s.endpointURL, bucketName, objectKey)

	return &pb.UploadMediaResponse{
		FileUrl: fileURL,
		FileKey: objectKey,
	}, nil
}

// Вспомогательная функция для генерации случайной строки
func generateRandomString(length int) string {
	const charset = "abcdefghijklmnopqrstuvwxyz0123456789"
	b := make([]byte, length)
	for i := range b {
		b[i] = charset[seededRand.Intn(len(charset))]
	}
	return string(b)
}

var seededRand = rand.New(rand.NewSource(time.Now().UnixNano()))

// getMIMEType determines the MIME type of the file data.
func getMIMEType(fileData []byte) (string, error) {
	kind, err := mimetype.DetectReader(bytes.NewReader(fileData))
	if err != nil {
		return "", fmt.Errorf("failed to detect MIME type: %w", err)
	}
	if kind == nil {
		return "application/octet-stream", nil // Default to binary if not detected
	}
	return kind.String(), nil
}

// getExtensionFromMIMEType determines the file extension from the MIME type.
func getExtensionFromMIMEType(mimeType string) string {
	switch mimeType {
	case "image/jpeg":
		return ".jpg"
	case "image/png":
		return ".png"
	case "video/mp4":
		return ".mp4"
	case "video/quicktime":
		return ".mov"
	case "image/heic":
		return ".heic"
	default:
		return ".bin" // Generic binary extension
	}
}

// isExtensionAllowed checks if the given file extension is allowed for the media type.
func isExtensionAllowed(ext string, mediaType pb.MediaType, allowedExtensions map[pb.MediaType][]string) bool {
	allowed, ok := allowedExtensions[mediaType]
	if !ok {
		return false // No allowed extensions defined for this media type
	}

	for _, allowedExt := range allowed {
		if strings.EqualFold(ext, allowedExt) {
			return true
		}
	}
	return false
}
