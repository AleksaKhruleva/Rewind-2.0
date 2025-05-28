package services

import (
	"context"
	"errors"
	"log"

	"github.com/go-playground/validator/v10"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"
	"gorm.io/gorm"

	"Rewind-memory-service/clients/auth"
	"Rewind-memory-service/clients/media"
	"Rewind-memory-service/internal/app/models"
	"Rewind-memory-service/internal/app/repositories"
	pb "Rewind-memory-service/pkg/proto"
	clients "Rewind-memory-service/pkg/proto/clients"
)

// MemoryService implements the memory.MemoryServiceServer interface
type MemoryService struct {
	pb.UnimplementedMemoryServiceServer
	memoryRepo  repositories.MemoryRepositoryInterface // Corrected type here
	validator   *validator.Validate
	authClient  *auth.AuthServiceClient
	mediaClient *media.MediaServiceClient
}

// NewMemoryService создает новый экземпляр MemoryService
func NewMemoryService(repo repositories.MemoryRepositoryInterface, validate *validator.Validate, authClient *auth.AuthServiceClient, mediaClient *media.MediaServiceClient) *MemoryService {
	return &MemoryService{
		memoryRepo:  repo,
		validator:   validate,
		authClient:  authClient,
		mediaClient: mediaClient,
	}
}

// convertMemoryToProto converts a models.Memory to a pb.Memory
func convertMemoryToProto(m *models.Memory) *pb.Memory {
	if m == nil {
		return nil
	}
	return &pb.Memory{
		Id:        uint64(m.ID),
		GroupId:   uint64(m.GroupID),
		UserId:    uint64(m.UserID),
		MediaType: pb.MediaType(pb.MediaType_value[m.MediaType]),
		MediaUrl:  m.MediaURL,
		Latitude:  m.Latitude,
		Longitude: m.Longitude,
		MusicId:   m.MusicID,
		Offset:    m.Offset,
		Duration:  m.Duration,
		CreatedAt: timestamppb.New(m.CreatedAt),
		UpdatedAt: timestamppb.New(m.UpdatedAt),
	}
}

// convertDetailedMemoryToProto converts a models.MemoryDetailed to a pb.DetailedMemory
func convertDetailedMemoryToProto(md *models.MemoryDetailed) *pb.DetailedMemory {
	if md == nil {
		return nil
	}
	return &pb.DetailedMemory{
		Memory:      convertMemoryToProto(&md.Memory),
		Tags:        md.TagsArray, // Use the processed TagsArray
		IsFavourite: md.IsFavourite,
	}
}

// CreateMemory implements pb.MemoryServiceServer.CreateMemory
func (s *MemoryService) CreateMemory(ctx context.Context, req *pb.CreateMemoryRequest) (*pb.CreateMemoryResponse, error) {
	// Валидация запроса
	if err := s.validator.Struct(req); err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "invalid request: %v", err)
	}

	if len(req.MediaFile) == 0 {
		return nil, status.Errorf(codes.InvalidArgument, "media_file is required")
	}

	mediaTypeValue, ok := pb.MediaType_value[req.MediaType.String()]
	if !ok || mediaTypeValue == int32(pb.MediaType_UNSPECIFIED) {
		return nil, status.Errorf(codes.InvalidArgument, "invalid mediaType: %s", req.MediaType)
	}
	pbMediaType := clients.MediaType(mediaTypeValue)

	// Отправка файла в медиа-сервис
	uploadReq := &clients.UploadMediaRequest{
		MediaType: pbMediaType,
		FileData:  req.MediaFile,
	}

	uploadResp, err := s.mediaClient.UploadMedia(ctx, uploadReq)
	if err != nil {
		log.Printf("MemoryService: Failed to upload media to media service: %v", err)
		return nil, err
	}

	mediaURL := uploadResp.GetFileUrl()
	if mediaURL == "" {
		log.Println("MemoryService: Received empty media URL from media service")
		return nil, status.Errorf(codes.Internal, "media upload failed to return URL")
	}

	memory := &models.Memory{
		GroupID:   uint(req.GroupId),
		UserID:    uint(req.UserId),
		MediaType: req.MediaType.String(),
		MediaURL:  mediaURL,
	}

	if req.Latitude != nil && req.Longitude != nil {
		memory.Latitude = *req.Latitude
		memory.Longitude = *req.Longitude
	}
	if req.MusicId != nil && req.Offset != nil && req.Duration != nil {
		memory.MusicID = *req.MusicId
		memory.Offset = *req.Offset
		memory.Duration = *req.Duration
	}

	tx, err := s.memoryRepo.BeginTx(ctx)
	if err != nil {
		log.Printf("MemoryService: Failed to begin transaction: %v", err)
		return nil, status.Errorf(codes.Internal, "failed to begin transaction: %v", err)
	}
	defer func() {
		if r := recover(); r != nil {
			log.Printf("MemoryService: Recovered from panic in CreateMemory, rolling back: %v", r)
			tx.Rollback()
			panic(r) // Re-throw panic
		} else if err != nil {
			tx.Rollback()
		}
	}()

	if err = s.memoryRepo.CreateMemory(ctx, tx, memory); err != nil {
		log.Printf("MemoryService: Failed to create memory: %v", err)
		return nil, status.Errorf(codes.Internal, "failed to create memory: %v", err)
	}

	// Создание тегов
	for _, tagName := range req.Tags {
		tag := &models.MemoryTag{
			MemoryID: memory.ID,
			Tag:      tagName,
		}
		if err = s.memoryRepo.CreateMemoryTag(ctx, tx, tag); err != nil {
			log.Printf("MemoryService: Failed to create memory tag '%s' for memory %d: %v", tagName, memory.ID, err)
			return nil, status.Errorf(codes.Internal, "failed to create memory tag: %v", err)
		}
	}

	if err = s.memoryRepo.CommitTx(tx); err != nil {
		log.Printf("MemoryService: Failed to commit transaction: %v", err)
		return nil, status.Errorf(codes.Internal, "failed to commit transaction: %v", err)
	}

	return &pb.CreateMemoryResponse{
		Memory: convertMemoryToProto(memory),
	}, nil
}

// DeleteMemory implements pb.MemoryServiceServer.DeleteMemory
func (s *MemoryService) DeleteMemory(ctx context.Context, req *pb.DeleteMemoryRequest) (*pb.DeleteMemoryResponse, error) {
	if err := s.validator.Struct(req); err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "invalid request: %v", err)
	}

	memory, err := s.memoryRepo.GetMemory(ctx, nil, uint(req.GetMemoryId()))
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			log.Printf("MemoryService: Failed to get memory %d: %v", req.GetMemoryId(), err)
			return &pb.DeleteMemoryResponse{Success: true}, nil
		}
		log.Printf("MemoryService: Failed to get memory %d: %v", req.GetMemoryId(), err)
		return nil, status.Errorf(codes.Internal, "failed to get memory %d: %v", req.GetMemoryId(), err)
	}

	if memory.UserID != uint(req.UserId) && !req.IsAdmin {
		log.Printf("MemoryService: Failed to delete memory %d: %v", req.GetMemoryId(), memory.UserID)
		return nil, status.Errorf(codes.PermissionDenied, "failed to delete memory %d: %v", req.GetMemoryId(), err)
	}

	tx, err := s.memoryRepo.BeginTx(ctx)
	if err != nil {
		log.Printf("MemoryService: Failed to begin transaction: %v", err)
		return nil, status.Errorf(codes.Internal, "failed to begin transaction: %v", err)
	}
	defer func() {
		if r := recover(); r != nil {
			log.Printf("MemoryService: Recovered from panic in DeleteMemory, rolling back: %v", r)
			tx.Rollback()
			panic(r) // Re-throw panic
		} else if err != nil {
			tx.Rollback()
		}
	}()

	if err = s.memoryRepo.DeleteMemoryTagsByMemoryID(ctx, tx, memory.ID); err != nil {
		if !errors.Is(err, gorm.ErrRecordNotFound) {
			log.Printf("MemoryService: Failed to delete memory tag %d: %v", req.GetMemoryId(), err)
			return nil, status.Errorf(codes.Internal, "failed to delete memory tag %d: %v", req.GetMemoryId(), err)
		}
	}

	if err = s.memoryRepo.DeleteFavouritesByMemoryID(ctx, tx, memory.ID); err != nil {
		if !errors.Is(err, gorm.ErrRecordNotFound) {
			log.Printf("MemoryService: Failed to delete memory %d: %v", req.GetMemoryId(), err)
			return nil, status.Errorf(codes.Internal, "failed to delete memory %d: %v", req.GetMemoryId(), err)
		}
	}

	if err = s.memoryRepo.DeleteMemory(ctx, tx, uint(req.MemoryId)); err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return &pb.DeleteMemoryResponse{Success: true}, nil
		}
		log.Printf("MemoryService: Failed to delete memory %d: %v", req.MemoryId, err)
		return nil, status.Errorf(codes.Internal, "failed to delete memory: %v", err)
	}

	if err = s.memoryRepo.CommitTx(tx); err != nil {
		log.Printf("MemoryService: Failed to commit transaction: %v", err)
		return nil, status.Errorf(codes.Internal, "failed to commit transaction: %v", err)
	}

	return &pb.DeleteMemoryResponse{Success: true}, nil
}

// GetMemory implements pb.MemoryServiceServer.GetMemory
func (s *MemoryService) GetMemory(ctx context.Context, req *pb.GetMemoryRequest) (*pb.GetMemoryResponse, error) {
	if err := s.validator.Struct(req); err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "invalid request: %v", err)
	}

	memory, err := s.memoryRepo.GetMemoryDetailedByID(ctx, nil, uint(req.GetMemoryId()), uint(req.GetUserId()))
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			log.Printf("MemoryService: Failed to get memory %d: %v", req.GetMemoryId(), err)
			return nil, status.Errorf(codes.NotFound, "failed to get memory %d: %v", req.GetMemoryId(), err)
		}
		log.Printf("MemoryService: Failed to get memory %d: %v", req.GetMemoryId(), err)
		return nil, status.Errorf(codes.Internal, "failed to get memory %d: %v", req.GetMemoryId(), err)
	}

	return &pb.GetMemoryResponse{Memory: convertDetailedMemoryToProto(memory)}, nil
}

// DeleteMemoriesByGroup implements pb.MemoryServiceServer.DeleteMemoriesByGroup
func (s *MemoryService) DeleteMemoriesByGroup(ctx context.Context, req *pb.DeleteMemoriesByGroupRequest) (*pb.DeleteMemoriesByGroupResponse, error) {
	if err := s.validator.Struct(req); err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "invalid request: %v", err)
	}

	tx, err := s.memoryRepo.BeginTx(ctx)
	if err != nil {
		log.Printf("MemoryService: Failed to begin transaction: %v", err)
		return nil, status.Errorf(codes.Internal, "failed to begin transaction: %v", err)
	}
	defer func() {
		if r := recover(); r != nil {
			log.Printf("MemoryService: Recovered from panic in DeleteMemoriesByGroup, rolling back: %v", r)
			tx.Rollback()
			panic(r) // Re-throw panic
		} else if err != nil {
			tx.Rollback()
		}
	}()

	if err = s.memoryRepo.DeleteMemoryTagsByGroupID(ctx, tx, uint(req.GetGroupId())); err != nil {
		if !errors.Is(err, gorm.ErrRecordNotFound) {
			log.Printf("MemoryService: Failed to delete memory tag %d: %v", req.GetGroupId(), err)
		} else {
			return nil, status.Errorf(codes.Internal, "failed to delete memory tag %d: %v", req.GetGroupId(), err)
		}
	}

	if err = s.memoryRepo.DeleteMemoriesByGroup(ctx, tx, uint(req.GroupId)); err != nil {
		log.Printf("MemoryService: Failed to delete memories for group %d: %v", req.GroupId, err)
		return nil, status.Errorf(codes.Internal, "failed to delete memories by group: %v", err)
	}

	if err = s.memoryRepo.CommitTx(tx); err != nil {
		log.Printf("MemoryService: Failed to commit transaction: %v", err)
		return nil, status.Errorf(codes.Internal, "failed to commit transaction: %v", err)
	}

	return &pb.DeleteMemoriesByGroupResponse{Success: true}, nil
}

// ListMemoriesByGroup implements pb.MemoryServiceServer.ListMemoriesByGroup
func (s *MemoryService) ListMemoriesByGroup(ctx context.Context, req *pb.ListMemoriesByGroupRequest) (*pb.ListMemoriesByGroupResponse, error) {
	if err := s.validator.Struct(req); err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "invalid request: %v", err)
	}

	// Pass nil for transaction as this is a read-only operation
	memoriesDetailed, err := s.memoryRepo.ListMemoriesByGroupDetailed(ctx, nil, uint(req.GroupId), uint(req.UserId))
	if err != nil {
		log.Printf("MemoryService: Failed to list memories by group %d for user %d: %v", req.GroupId, req.UserId, err)
		return nil, status.Errorf(codes.Internal, "failed to list memories by group: %v", err)
	}

	var respMemories []*pb.DetailedMemory
	for _, md := range memoriesDetailed {
		respMemories = append(respMemories, convertDetailedMemoryToProto(&md))
	}

	return &pb.ListMemoriesByGroupResponse{Memories: respMemories}, nil
}

// ListMemoriesByGroupWithFilters implements pb.MemoryServiceServer.ListMemoriesByGroupWithFilters
func (s *MemoryService) ListMemoriesByGroupWithFilters(ctx context.Context, req *pb.ListMemoriesByGroupWithFiltersRequest) (*pb.ListMemoriesByGroupWithFiltersResponse, error) {
	if err := s.validator.Struct(req); err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "invalid request: %v", err)
	}

	// Pass nil for transaction as this is a read-only operation
	memoriesDetailed, err := s.memoryRepo.ListMemoriesByGroupWithFiltersDetailed(ctx, nil, uint(req.GroupId), uint(req.UserId), req.Filters, uint(req.NumberOfMemories))
	if err != nil {
		log.Printf("MemoryService: Failed to list memories by group %d with filters for user %d: %v", req.GroupId, req.UserId, err)
		return nil, status.Errorf(codes.Internal, "failed to list memories by group with filters: %v", err)
	}

	var respMemories []*pb.DetailedMemory
	for _, md := range memoriesDetailed {
		respMemories = append(respMemories, convertDetailedMemoryToProto(&md))
	}

	return &pb.ListMemoriesByGroupWithFiltersResponse{Memories: respMemories}, nil
}

// CreateMemoryTag implements pb.MemoryServiceServer.CreateMemoryTag
func (s *MemoryService) CreateMemoryTag(ctx context.Context, req *pb.CreateMemoryTagRequest) (*pb.CreateMemoryTagResponse, error) {
	if err := s.validator.Struct(req); err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "invalid request: %v", err)
	}

	exists, err := s.memoryRepo.ExistsMemoryByIDAndGroupID(ctx, nil, uint(req.MemoryId), uint(req.GroupId))
	if err != nil {
		log.Printf("MemoryService: Failed to check if memory %d exists in group %d: %v", req.MemoryId, req.GroupId, err)
		return nil, status.Errorf(codes.Internal, "failed to check if memory exists: %v", err)
	}
	if !exists {
		return nil, status.Errorf(codes.NotFound, "memory %d does not exist in group %d", req.MemoryId, req.GroupId)
	}

	tag := &models.MemoryTag{
		MemoryID: uint(req.MemoryId),
		Tag:      req.Name,
	}

	tx, err := s.memoryRepo.BeginTx(ctx)
	if err != nil {
		log.Printf("MemoryService: Failed to begin transaction: %v", err)
		return nil, status.Errorf(codes.Internal, "failed to begin transaction: %v", err)
	}
	defer func() {
		if r := recover(); r != nil {
			log.Printf("MemoryService: Recovered from panic in CreateMemoryTag, rolling back: %v", r)
			tx.Rollback()
			panic(r) // Re-throw panic
		} else if err != nil {
			tx.Rollback()
		}
	}()

	if err = s.memoryRepo.CreateMemoryTag(ctx, tx, tag); err != nil {
		log.Printf("MemoryService: Failed to create memory tag '%s' for memory %d: %v", req.Name, req.MemoryId, err)
		return nil, status.Errorf(codes.Internal, "failed to create memory tag: %v", err)
	}

	if err = s.memoryRepo.CommitTx(tx); err != nil {
		log.Printf("MemoryService: Failed to commit transaction: %v", err)
		return nil, status.Errorf(codes.Internal, "failed to commit transaction: %v", err)
	}

	return &pb.CreateMemoryTagResponse{
		Tag: &pb.MemoryTag{
			Id:        uint64(tag.ID),
			MemoryId:  uint64(tag.MemoryID),
			Name:      tag.Tag,
			CreatedAt: timestamppb.New(tag.CreatedAt),
			UpdatedAt: timestamppb.New(tag.UpdatedAt),
		},
	}, nil
}

// DeleteMemoryTag implements pb.MemoryServiceServer.DeleteMemoryTag
func (s *MemoryService) DeleteMemoryTag(ctx context.Context, req *pb.DeleteMemoryTagRequest) (*pb.DeleteMemoryTagResponse, error) {
	if err := s.validator.Struct(req); err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "invalid request: %v", err)
	}

	exists, err := s.memoryRepo.ExistsMemoryByIDAndGroupID(ctx, nil, uint(req.MemoryId), uint(req.GroupId))
	if err != nil {
		return &pb.DeleteMemoryTagResponse{Success: true}, nil
	}
	if !exists {
		return &pb.DeleteMemoryTagResponse{Success: true}, nil
	}

	tx, err := s.memoryRepo.BeginTx(ctx)
	if err != nil {
		log.Printf("MemoryService: Failed to begin transaction: %v", err)
		return nil, status.Errorf(codes.Internal, "failed to begin transaction: %v", err)
	}
	defer func() {
		if r := recover(); r != nil {
			log.Printf("MemoryService: Recovered from panic in DeleteMemoryTag, rolling back: %v", r)
			tx.Rollback()
			panic(r) // Re-throw panic
		} else if err != nil {
			tx.Rollback()
		}
	}()

	if err = s.memoryRepo.DeleteMemoryTag(ctx, tx, uint(req.MemoryId), req.Tag); err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return &pb.DeleteMemoryTagResponse{Success: true}, nil
		}
		log.Printf("MemoryService: Failed to delete memory tag %d: %v", req.Tag, err)
		return nil, status.Errorf(codes.Internal, "failed to delete memory tag: %v", err)
	}

	if err = s.memoryRepo.CommitTx(tx); err != nil {
		log.Printf("MemoryService: Failed to commit transaction: %v", err)
		return nil, status.Errorf(codes.Internal, "failed to commit transaction: %v", err)
	}

	return &pb.DeleteMemoryTagResponse{Success: true}, nil
}

// ListMemoryTagsByMemoryID implements pb.MemoryServiceServer.ListMemoryTagsByMemoryID
func (s *MemoryService) ListMemoryTagsByMemoryID(ctx context.Context, req *pb.ListMemoryTagsByMemoryIDRequest) (*pb.ListMemoryTagsByMemoryIDResponse, error) {
	if err := s.validator.Struct(req); err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "invalid request: %v", err)
	}

	exists, err := s.memoryRepo.ExistsMemoryByIDAndGroupID(ctx, nil, uint(req.MemoryId), uint(req.GroupId))
	if err != nil {
		log.Printf("MemoryService: Failed to check if memory %d exists in group %d: %v", req.MemoryId, req.GroupId, err)
		return nil, status.Errorf(codes.Internal, "failed to check if memory exists: %v", err)
	}
	if !exists {
		return nil, status.Errorf(codes.NotFound, "memory %d does not exist in group %d", req.MemoryId, req.GroupId)
	}

	tags, err := s.memoryRepo.ListMemoryTagsByMemoryID(ctx, nil, uint(req.MemoryId))
	if err != nil {
		log.Printf("MemoryService: Failed to list memory tags for memory %d: %v", req.MemoryId, err)
		return nil, status.Errorf(codes.Internal, "failed to list memory tags by memory ID: %v", err)
	}

	var respTags []*pb.MemoryTag
	for _, tag := range tags {
		respTags = append(respTags, &pb.MemoryTag{
			Id:        uint64(tag.ID),
			MemoryId:  uint64(tag.MemoryID),
			Name:      tag.Tag,
			CreatedAt: timestamppb.New(tag.CreatedAt),
			UpdatedAt: timestamppb.New(tag.UpdatedAt),
		})
	}

	return &pb.ListMemoryTagsByMemoryIDResponse{Tags: respTags}, nil
}

// CreateFavourite implements pb.MemoryServiceServer.CreateFavourite
func (s *MemoryService) CreateFavourite(ctx context.Context, req *pb.CreateFavouriteRequest) (*pb.CreateFavouriteResponse, error) {
	if err := s.validator.Struct(req); err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "invalid request: %v", err)
	}

	favourite := &models.Favourite{
		MemoryID: uint(req.MemoryId),
		UserID:   uint(req.UserId),
	}

	tx, err := s.memoryRepo.BeginTx(ctx)
	if err != nil {
		log.Printf("MemoryService: Failed to begin transaction: %v", err)
		return nil, status.Errorf(codes.Internal, "failed to begin transaction: %v", err)
	}
	defer func() {
		if r := recover(); r != nil {
			log.Printf("MemoryService: Recovered from panic in CreateFavourite, rolling back: %v", r)
			tx.Rollback()
			panic(r) // Re-throw panic
		} else if err != nil {
			tx.Rollback()
		}
	}()

	if err = s.memoryRepo.CreateFavourite(ctx, tx, favourite); err != nil {
		log.Printf("MemoryService: Failed to create favourite for memory %d by user %d: %v", req.MemoryId, req.UserId, err)
		return nil, status.Errorf(codes.Internal, "failed to create favourite: %v", err)
	}

	if err = s.memoryRepo.CommitTx(tx); err != nil {
		log.Printf("MemoryService: Failed to commit transaction: %v", err)
		return nil, status.Errorf(codes.Internal, "failed to commit transaction: %v", err)
	}

	return &pb.CreateFavouriteResponse{
		Favourite: &pb.Favourite{
			MemoryId:  uint64(favourite.MemoryID),
			UserId:    uint64(favourite.UserID),
			CreatedAt: timestamppb.New(favourite.CreatedAt),
		},
	}, nil
}

// DeleteFavourite implements pb.MemoryServiceServer.DeleteFavourite
func (s *MemoryService) DeleteFavourite(ctx context.Context, req *pb.DeleteFavouriteRequest) (*pb.DeleteFavouriteResponse, error) {
	if err := s.validator.Struct(req); err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "invalid request: %v", err)
	}

	tx, err := s.memoryRepo.BeginTx(ctx)
	if err != nil {
		log.Printf("MemoryService: Failed to begin transaction: %v", err)
		return nil, status.Errorf(codes.Internal, "failed to begin transaction: %v", err)
	}
	defer func() {
		if r := recover(); r != nil {
			log.Printf("MemoryService: Recovered from panic in DeleteFavourite, rolling back: %v", r)
			tx.Rollback()
			panic(r) // Re-throw panic
		} else if err != nil {
			tx.Rollback()
		}
	}()

	if err = s.memoryRepo.DeleteFavourite(ctx, tx, uint(req.MemoryId), uint(req.UserId)); err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return &pb.DeleteFavouriteResponse{Success: true}, nil
		}
		log.Printf("MemoryService: Failed to delete favourite for memory %d by user %d: %v", req.MemoryId, req.UserId, err)
		return nil, status.Errorf(codes.Internal, "failed to delete favourite: %v", err)
	}

	if err = s.memoryRepo.CommitTx(tx); err != nil {
		log.Printf("MemoryService: Failed to commit transaction: %v", err)
		return nil, status.Errorf(codes.Internal, "failed to commit transaction: %v", err)
	}

	return &pb.DeleteFavouriteResponse{Success: true}, nil
}

// DeleteFavouritesByUserID implements pb.MemoryServiceServer.DeleteFavouritesByUserID
func (s *MemoryService) DeleteFavouritesByUserID(ctx context.Context, req *pb.DeleteFavouritedByUserIDRequest) (*pb.DeleteFavouritedByUserIDResponse, error) {
	if err := s.validator.Struct(req); err != nil {
		return nil, status.Errorf(codes.InvalidArgument, "invalid request: %v", err)
	}

	tx, err := s.memoryRepo.BeginTx(ctx)
	if err != nil {
		log.Printf("MemoryService: Failed to begin transaction: %v", err)
		return nil, status.Errorf(codes.Internal, "failed to begin transaction: %v", err)
	}
	defer func() {
		if r := recover(); r != nil {
			log.Printf("MemoryService: Recovered from panic in DeleteFavouritesByUserID, rolling back: %v", r)
			tx.Rollback()
			panic(r) // Re-throw panic
		} else if err != nil {
			tx.Rollback()
		}
	}()

	if err = s.memoryRepo.DeleteFavouritesByUserID(ctx, tx, uint(req.UserId)); err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return &pb.DeleteFavouritedByUserIDResponse{Success: true}, nil
		}
		log.Printf("MemoryService: Failed to delete all favourites for user %d: %v", req.UserId, err)
		return nil, status.Errorf(codes.Internal, "failed to delete favourites by user ID: %v", err)
	}

	if err = s.memoryRepo.CommitTx(tx); err != nil {
		log.Printf("MemoryService: Failed to commit transaction: %v", err)
		return nil, status.Errorf(codes.Internal, "failed to commit transaction: %v", err)
	}

	return &pb.DeleteFavouritedByUserIDResponse{Success: true}, nil
}
