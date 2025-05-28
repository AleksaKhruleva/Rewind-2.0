package services

import (
	"context"
	"log"
	"strings"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	authClient "Rewind-api-gateway-service/clients/auth"
	groupClient "Rewind-api-gateway-service/clients/group"
	memoryClient "Rewind-api-gateway-service/clients/memory"
	"Rewind-api-gateway-service/internal/app/requests"
	"Rewind-api-gateway-service/internal/app/responses"
	pb "Rewind-api-gateway-service/pkg/proto"
)

// MemoryServiceInterface defines the methods for interacting with Memory-Service
// through the API Gateway service layer.
// Methods accept simple data types and return protobuf messages from the microservice.
// The requesting user's ID is extracted from the context.
type MemoryServiceInterface interface {
	CreateMemory(ctx context.Context, req *requests.CreateMemoryRequest, mediaFileBytes []byte) (*responses.MemoryResponse, error)
	DeleteMemory(ctx context.Context, req *requests.DeleteMemoryRequest) (*pb.DeleteMemoryResponse, error)
	ListMemoriesByGroup(ctx context.Context, req *requests.ListMemoriesByGroupRequest) ([]responses.DetailedMemoryResponse, error)
	ListMemoriesByGroupWithFilters(ctx context.Context, req *requests.ListMemoriesByGroupWithFiltersRequest) ([]responses.DetailedMemoryResponse, error)
	CreateMemoryTag(ctx context.Context, req *requests.CreateMemoryTagRequest) (*pb.CreateMemoryTagResponse, error)
	DeleteMemoryTag(ctx context.Context, req *requests.DeleteMemoryTagRequest) (*pb.DeleteMemoryTagResponse, error)
	ListMemoryTagsByMemoryID(ctx context.Context, req *requests.ListMemoryTagsByMemoryIDRequest) (*pb.ListMemoryTagsByMemoryIDResponse, error)
	CreateFavourite(ctx context.Context, req *requests.CreateFavouriteRequest) (*pb.CreateFavouriteResponse, error)
	DeleteFavourite(ctx context.Context, req *requests.DeleteFavouriteRequest) (*pb.DeleteFavouriteResponse, error)
}

// MemoryService represents the service for interacting with Memory-Service via gRPC.
type MemoryService struct {
	memoryClient *memoryClient.MemoryServiceClient
	authClient   *authClient.AuthServiceClient
	groupClient  *groupClient.GroupServiceClient
}

// NewMemoryService creates a new instance of MemoryService.
// Accepts gRPC clients of the necessary microservices.
func NewMemoryService(memoryClient *memoryClient.MemoryServiceClient,
	authClient *authClient.AuthServiceClient,
	groupClient *groupClient.GroupServiceClient,
) MemoryServiceInterface {
	return &MemoryService{
		memoryClient: memoryClient,
		authClient:   authClient,
		groupClient:  groupClient,
	}
}

// verifyUserExists checks the existence of the user in Auth-Service.
// Can be used for additional verification before performing operations.
// Returns a gRPC NotFound error if the user is not found, or Internal if an Auth-Service error occurs.
func (s *MemoryService) verifyUserExists(ctx context.Context, userID uint64, groupID *uint64) (bool, error) {
	req := &pb.GetUserByIDRequest{UserId: userID}
	resp, err := s.authClient.GetUserByID(ctx, req)
	if err != nil {
		return false, err
	}

	if resp == nil {
		log.Printf("API GW MemoryService: User %d not found in AuthService", userID)
		return false, status.Errorf(codes.NotFound, "user not found")
	}
	if groupID == nil {
		return false, nil
	}

	respGroup, err := s.groupClient.CheckUserInGroup(ctx, &pb.CheckUserInGroupRequest{GroupId: *groupID, UserId: userID})
	if err != nil {
		return false, err
	}

	if !respGroup.IsInGroup {
		log.Printf("API GW MemoryService: User %d not found in Group", userID)
		return false, status.Errorf(codes.PermissionDenied, "user not found in group")
	}

	return true, nil
}

// CreateMemory calls the CreateMemory RPC method in Memory-Service.
func (s *MemoryService) CreateMemory(ctx context.Context, req *requests.CreateMemoryRequest, mediaFileBytes []byte) (*responses.MemoryResponse, error) {
	userID, err := GetRequestingUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}
	log.Printf("API GW MemoryService: Calling CreateMemory RPC for user %d", userID)

	if _, err := s.verifyUserExists(ctx, userID, &req.GroupID); err != nil {
		return nil, err
	}

	mediaTypeValue, ok := pb.MediaType_value[req.MediaType]
	if !ok || mediaTypeValue == int32(pb.MediaType_UNSPECIFIED) {
		return nil, status.Errorf(codes.InvalidArgument, "invalid mediaType: %s", req.MediaType)
	}
	pbMediaType := pb.MediaType(mediaTypeValue)

	pbReq := &pb.CreateMemoryRequest{
		UserId:    userID,
		GroupId:   req.GroupID,
		MediaType: pbMediaType,
		MediaFile: mediaFileBytes,
		Latitude:  req.Latitude,
		Longitude: req.Longitude,
		MusicId:   req.MusicID,
		Offset:    req.Offset,
		Duration:  req.Duration,
		Tags:      req.Tags,
	}

	resp, err := s.memoryClient.CreateMemory(ctx, pbReq)
	if err != nil {
		return nil, err
	}

	return s.AddUserInfoToMemory(ctx, resp.GetMemory())
}

func (s *MemoryService) AddUserInfoToMemory(ctx context.Context, memory *pb.Memory) (*responses.MemoryResponse, error) {
	userID := memory.UserId
	user, err := s.authClient.GetUserByID(ctx, &pb.GetUserByIDRequest{UserId: userID})
	if err != nil {
		return nil, err
	}
	respMemory := &responses.MemoryResponse{
		Id:        memory.GetId(),
		GroupID:   memory.GetGroupId(),
		UserID:    memory.GetUserId(),
		Username:  user.GetUser().GetUsername(),
		UserImage: user.GetUser().GetImage(),
		MediaType: memory.GetMediaType().String(),
		MediaURL:  memory.GetMediaUrl(),
		Latitude:  memory.GetLatitude(),
		Longitude: memory.GetLongitude(),
		MusicID:   memory.GetMusicId(),
		Offset:    memory.GetOffset(),
		Duration:  memory.GetDuration(),
		CreatedAt: memory.GetCreatedAt().AsTime(),
		UpdatedAt: memory.GetUpdatedAt().AsTime(),
	}
	return respMemory, nil
}

// DeleteMemory calls the DeleteMemory RPC method in Memory-Service.
func (s *MemoryService) DeleteMemory(ctx context.Context, req *requests.DeleteMemoryRequest) (*pb.DeleteMemoryResponse, error) {
	userID, err := GetRequestingUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}
	log.Printf("API GW MemoryService: Calling DeleteMemory RPC for user %d, memory %d", userID, req.MemoryID)

	isAdmin, err := s.verifyUserExists(ctx, userID, &req.GroupID)
	if err != nil {
		return nil, err
	}

	pbReq := &pb.DeleteMemoryRequest{
		UserId:   userID,
		IsAdmin:  isAdmin,
		MemoryId: req.MemoryID,
	}

	return s.memoryClient.DeleteMemory(ctx, pbReq)
}

// ListMemoriesByGroup calls the ListMemoriesByGroup RPC method in Memory-Service.
func (s *MemoryService) ListMemoriesByGroup(ctx context.Context, req *requests.ListMemoriesByGroupRequest) ([]responses.DetailedMemoryResponse, error) {
	userID, err := GetRequestingUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}
	log.Printf("API GW MemoryService: Calling ListMemoriesByGroup RPC for user %d, group %d", userID, req.GroupID)

	_, err = s.verifyUserExists(ctx, userID, &req.GroupID)
	if err != nil {
		return nil, err
	}

	pbReq := &pb.ListMemoriesByGroupRequest{
		UserId:  userID,
		GroupId: req.GroupID,
	}

	resp, err := s.memoryClient.ListMemoriesByGroup(ctx, pbReq)
	if err != nil {
		return nil, err
	}

	return s.AddUserInfoToMemories(ctx, resp.GetMemories())
}

func (s *MemoryService) AddUserInfoToMemories(ctx context.Context, detailedMemories []*pb.DetailedMemory) ([]responses.DetailedMemoryResponse, error) {
	userIDs := make([]uint64, len(detailedMemories))
	for i, m := range detailedMemories {
		userIDs[i] = m.GetMemory().GetUserId()
	}
	users, err := s.authClient.GetUsersByIDs(ctx, &pb.GetUsersByIDsRequest{UserIds: userIDs})
	if err != nil {
		return nil, err
	}
	usersMap := make(map[uint64]*pb.User)
	for _, user := range users.GetUsers() {
		usersMap[user.GetId()] = user
	}
	var (
		respMemories        []responses.DetailedMemoryResponse
		username, userImage string
	)
	for _, mem := range detailedMemories {
		user, found := usersMap[mem.GetMemory().GetUserId()]
		if !found {
			username = "unknown"
			userImage = "unknown"
		} else {
			username = user.GetUsername()
			userImage = user.GetImage()
		}
		respMemories = append(respMemories, responses.DetailedMemoryResponse{
			Memory: responses.MemoryResponse{
				Id:        mem.GetMemory().GetId(),
				GroupID:   mem.GetMemory().GetGroupId(),
				UserID:    mem.GetMemory().GetUserId(),
				Username:  username,
				UserImage: userImage,
				MediaType: mem.GetMemory().MediaType.String(),
				MediaURL:  mem.GetMemory().GetMediaUrl(),
				Latitude:  mem.GetMemory().GetLatitude(),
				Longitude: mem.GetMemory().GetLongitude(),
				MusicID:   mem.GetMemory().GetMusicId(),
				Offset:    mem.GetMemory().GetOffset(),
				Duration:  mem.GetMemory().GetDuration(),
				CreatedAt: mem.GetMemory().GetCreatedAt().AsTime(),
				UpdatedAt: mem.GetMemory().GetUpdatedAt().AsTime(),
			},
			Tags:        mem.GetTags(),
			IsFavourite: mem.GetIsFavourite(),
		})
	}
	return respMemories, nil
}

// ListMemoriesByGroupWithFilters calls the ListMemoriesByGroupWithFilters RPC method in Memory-Service.
func (s *MemoryService) ListMemoriesByGroupWithFilters(ctx context.Context, req *requests.ListMemoriesByGroupWithFiltersRequest) ([]responses.DetailedMemoryResponse, error) {
	userID, err := GetRequestingUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}
	log.Printf("API GW MemoryService: Calling ListMemoriesByGroupWithFilters RPC for user %d, group %d", userID, req.GroupID)

	_, err = s.verifyUserExists(ctx, userID, &req.GroupID)
	if err != nil {
		return nil, err
	}

	pbReq := &pb.ListMemoriesByGroupWithFiltersRequest{
		UserId:           userID,
		GroupId:          req.GroupID,
		NumberOfMemories: req.NumberOfMemories,
	}

	mtRaw, found := req.Filters["media_type"]
	if found {
		values := strings.Split(mtRaw, ",")
		for _, v := range values {
			v = strings.TrimSpace(v)
			enumValue, ok := pb.MediaType_value[v]
			if !ok || enumValue == int32(pb.MediaType_UNSPECIFIED) {
				return nil, status.Errorf(codes.InvalidArgument, "invalid media_type value: %s", v)
			}
		}
	}

	if len(req.Filters) > 0 {
		pbReq.Filters = req.Filters
	}

	resp, err := s.memoryClient.ListMemoriesByGroupWithFilters(ctx, pbReq)
	if err != nil {
		return nil, err
	}
	return s.AddUserInfoToMemories(ctx, resp.GetMemories())
}

// CreateMemoryTag calls the CreateMemoryTag RPC method in Memory-Service.
func (s *MemoryService) CreateMemoryTag(ctx context.Context, req *requests.CreateMemoryTagRequest) (*pb.CreateMemoryTagResponse, error) {
	userID, err := GetRequestingUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}
	log.Printf("API GW MemoryService: Calling CreateMemoryTag RPC for user %d, memory %d, tag %s", userID, req.MemoryID, req.Tag)

	_, err = s.verifyUserExists(ctx, userID, &req.GroupID)
	if err != nil {
		return nil, err
	}

	pbReq := &pb.CreateMemoryTagRequest{
		MemoryId: req.MemoryID,
		GroupId:  req.GroupID,
		Name:     req.Tag,
	}

	return s.memoryClient.CreateMemoryTag(ctx, pbReq)
}

// DeleteMemoryTag calls the DeleteMemoryTag RPC method in Memory-Service.
func (s *MemoryService) DeleteMemoryTag(ctx context.Context, req *requests.DeleteMemoryTagRequest) (*pb.DeleteMemoryTagResponse, error) {
	userID, err := GetRequestingUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}
	log.Printf("API GW MemoryService: Calling DeleteMemoryTag RPC for user %d, memory %d, tag %s", userID, req.MemoryID, req.Tag)

	_, err = s.verifyUserExists(ctx, userID, &req.GroupID)
	if err != nil {
		return nil, err
	}

	pbReq := &pb.DeleteMemoryTagRequest{
		MemoryId: req.MemoryID,
		GroupId:  req.GroupID,
		Tag:      req.Tag,
	}

	return s.memoryClient.DeleteMemoryTag(ctx, pbReq)
}

// ListMemoryTagsByMemoryID calls the ListMemoryTagsByMemoryID RPC method in Memory-Service.
func (s *MemoryService) ListMemoryTagsByMemoryID(ctx context.Context, req *requests.ListMemoryTagsByMemoryIDRequest) (*pb.ListMemoryTagsByMemoryIDResponse, error) {
	userID, err := GetRequestingUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}
	log.Printf("API GW MemoryService: Calling ListMemoryTagsByMemoryID RPC for user %d, memory %d", userID, req.MemoryID)

	_, err = s.verifyUserExists(ctx, userID, &req.GroupID)
	if err != nil {
		return nil, err
	}

	pbReq := &pb.ListMemoryTagsByMemoryIDRequest{
		MemoryId: req.MemoryID,
		GroupId:  req.GroupID,
	}

	return s.memoryClient.ListMemoryTagsByMemoryID(ctx, pbReq)
}

// CreateFavourite calls the CreateFavourite RPC method in Memory-Service.
func (s *MemoryService) CreateFavourite(ctx context.Context, req *requests.CreateFavouriteRequest) (*pb.CreateFavouriteResponse, error) {
	userID, err := GetRequestingUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}
	log.Printf("API GW MemoryService: Calling CreateFavourite RPC for user %d, memory %d", userID, req.MemoryID)

	_, err = s.verifyUserExists(ctx, userID, &req.GroupID)
	if err != nil {
		return nil, err
	}

	pbReq := &pb.CreateFavouriteRequest{
		UserId:   userID,
		MemoryId: req.MemoryID,
	}

	return s.memoryClient.CreateFavourite(ctx, pbReq)
}

// DeleteFavourite calls the DeleteFavourite RPC method in Memory-Service.
func (s *MemoryService) DeleteFavourite(ctx context.Context, req *requests.DeleteFavouriteRequest) (*pb.DeleteFavouriteResponse, error) {
	userID, err := GetRequestingUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}
	log.Printf("API GW MemoryService: Calling DeleteFavourite RPC for user %d, memory %d", userID, req.MemoryID)

	_, err = s.verifyUserExists(ctx, userID, &req.GroupID)
	if err != nil {
		return nil, err
	}

	pbReq := &pb.DeleteFavouriteRequest{
		UserId:   userID,
		MemoryId: req.MemoryID,
	}

	return s.memoryClient.DeleteFavourite(ctx, pbReq)
}
