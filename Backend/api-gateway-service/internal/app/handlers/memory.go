package handlers

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"strconv"
	"strings"

	"Rewind-api-gateway-service/internal/app/requests"
	"Rewind-api-gateway-service/internal/app/responses"
	"Rewind-api-gateway-service/internal/app/services"

	"github.com/go-chi/chi/v5"
)

// MemoryHandler handles HTTP requests related to memories.
type MemoryHandler struct {
	memoryService services.MemoryServiceInterface
}

// NewMemoryHandler creates a new MemoryHandler.
func NewMemoryHandler(memoryService services.MemoryServiceInterface) *MemoryHandler {
	return &MemoryHandler{
		memoryService: memoryService,
	}
}

// CreateMemory handles POST /api/groups/{groupId}/memories
// @Summary Create a new memory
// @Tags memories
// @Accept multipart/form-data
// @Produce json
// @Param groupId path int true "Group ID"
// @Param mediaType formData string true "Media Type (image/video/quote)"
// @Param mediaFile formData file true "Media file to upload"
// @Param latitude formData number false "Latitude (optional)"
// @Param longitude formData number false "Longitude (optional)"
// @Param musicId formData string false "Music ID (optional)"
// @Param offset formData number false "Offset (optional)"
// @Param duration formData number false "Duration (optional)"
// @Param tags formData string false "Comma-separated tags (optional)"
// @Success 200 {object} responses.MemoryResponse "Successfully created memory"
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid request data"
// @Failure 401 {object} responses.ErrorResponse "Unauthorized - User not authenticated"
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error"
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable"
// @Security ApiKeyAuth
// @Router /api/groups/{groupId}/memories [post]
func (h *MemoryHandler) CreateMemory(w http.ResponseWriter, r *http.Request) {
	groupIDStr := chi.URLParam(r, "groupId")
	// Устанавливаем лимит на размер тела запроса (например, 100MB)
	err := r.ParseMultipartForm(100 << 20)
	if err != nil {
		log.Println("Error parsing multipart form", err)
		respondError(w, http.StatusBadRequest, "Error parsing multipart form")
	} // 100 MB

	// Извлечение полей из multipart/form-data
	mediaType := r.FormValue("mediaType")
	latitudeStr := r.FormValue("latitude")
	longitudeStr := r.FormValue("longitude")
	musicIDStr := r.FormValue("musicId")
	offsetStr := r.FormValue("offset")
	durationStr := r.FormValue("duration")
	tagsStr := r.FormValue("tags") // Ожидаем теги как одну строку, разделенную запятыми

	// Валидация и преобразование типов
	groupID, err := strconv.ParseUint(groupIDStr, 10, 64)
	if err != nil {
		respondError(w, http.StatusBadRequest, "Invalid groupId")
		return
	}
	if mediaType == "" {
		respondError(w, http.StatusBadRequest, "mediaType is required")
		return
	}

	var latitude *float64
	if latitudeStr != "" {
		val, err := strconv.ParseFloat(latitudeStr, 64)
		if err != nil {
			respondError(w, http.StatusBadRequest, "Invalid latitude format")
			return
		}
		latitude = &val
	}

	var longitude *float64
	if longitudeStr != "" {
		val, err := strconv.ParseFloat(longitudeStr, 64)
		if err != nil {
			respondError(w, http.StatusBadRequest, "Invalid longitude format")
			return
		}
		longitude = &val
	}

	var musicID *string
	if musicIDStr != "" {
		musicID = &musicIDStr
	}

	var offset *float64
	if offsetStr != "" {
		val, err := strconv.ParseFloat(offsetStr, 64)
		if err != nil {
			respondError(w, http.StatusBadRequest, "Invalid offset format")
			return
		}
		offset = &val
	}

	var duration *float64
	if durationStr != "" {
		val, err := strconv.ParseFloat(durationStr, 64)
		if err != nil {
			respondError(w, http.StatusBadRequest, "Invalid duration format")
			return
		}
		duration = &val
	}

	var tags []string
	if tagsStr != "" {
		tags = strings.Split(tagsStr, ",")
		// Очистка пробелов вокруг тегов, если они могут быть
		for i, tag := range tags {
			tags[i] = strings.TrimSpace(tag)
		}
	}

	// Извлечение файла
	file, _, err := r.FormFile("mediaFile")
	if err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Failed to get mediaFile from form: %v", err))
		return
	}
	defer file.Close()

	mediaFileBytes, err := io.ReadAll(file)
	if err != nil {
		respondError(w, http.StatusInternalServerError, fmt.Sprintf("Failed to read mediaFile: %v", err))
		return
	}

	if len(mediaFileBytes) == 0 {
		respondError(w, http.StatusBadRequest, "mediaFile is empty")
		return
	}

	req := requests.CreateMemoryRequest{
		GroupID:   groupID,
		MediaType: mediaType,
		Latitude:  latitude,
		Longitude: longitude,
		MusicID:   musicID,
		Offset:    offset,
		Duration:  duration,
		Tags:      tags,
	}

	resp, err := h.memoryService.CreateMemory(r.Context(), &req, mediaFileBytes)
	if err != nil {
		handleServiceError(w, err, "CreateMemory")
		return
	}

	memory := resp.GetMemory()
	if memory == nil {
		log.Println("MemoryHandler.CreateMemory: Service returned success but memory is nil")
		respondError(w, http.StatusInternalServerError, "Failed to create memory: unexpected service response")
		return
	}

	responseBody := responses.MemoryResponse{
		Id:        memory.GetId(),
		GroupID:   memory.GetGroupId(),
		UserID:    memory.GetUserId(),
		MediaType: memory.MediaType.String(),
		MediaURL:  memory.GetMediaUrl(),
		Latitude:  memory.GetLatitude(),
		Longitude: memory.GetLongitude(),
		MusicID:   memory.GetMusicId(),
		Offset:    memory.GetOffset(),
		Duration:  memory.GetDuration(),
		CreatedAt: memory.GetCreatedAt().AsTime(),
		UpdatedAt: memory.GetUpdatedAt().AsTime(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// DeleteMemory handles DELETE /api/groups/{groupId}/memories/{memoryId}
// @Summary Delete a memory by ID
// @Tags memories
// @Accept json
// @Produce json
// @Param memoryId path int true "Memory ID"
// @Param groupId path int true "Group ID"
// @Success 200 {object} responses.DeleteMemoryResponse "Successfully deleted memory"
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid memory ID"
// @Failure 401 {object} responses.ErrorResponse "Unauthorized - User not authenticated"
// @Failure 403 {object} responses.ErrorResponse "Forbidden - Permission denied by service"
// @Failure 404 {object} responses.ErrorResponse "Not Found - Memory not found"
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error"
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable"
// @Security ApiKeyAuth
// @Router /api/groups/{groupId}/memories/{memoryId} [delete]
func (h *MemoryHandler) DeleteMemory(w http.ResponseWriter, r *http.Request) {
	groupIDStr := chi.URLParam(r, "groupId")
	groupID, err := strconv.ParseUint(groupIDStr, 10, 64)
	if err != nil {
		respondError(w, http.StatusBadRequest, "Invalid memory ID")
		return
	}
	memoryIDStr := chi.URLParam(r, "memoryId")
	memoryID, err := strconv.ParseUint(memoryIDStr, 10, 64)
	if err != nil {
		respondError(w, http.StatusBadRequest, "Invalid memory ID")
		return
	}

	req := requests.DeleteMemoryRequest{
		GroupID:  groupID,
		MemoryID: memoryID,
	}

	resp, err := h.memoryService.DeleteMemory(r.Context(), &req)
	if err != nil {
		handleServiceError(w, err, "DeleteMemory")
		return
	}

	if !resp.GetSuccess() {
		log.Printf("MemoryHandler.DeleteMemory: Service reported failure for memory %d", memoryID)
		respondError(w, http.StatusInternalServerError, "Failed to delete memory: unexpected service response")
		return
	}

	responseBody := responses.DeleteMemoryResponse{
		Success: resp.GetSuccess(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// ListMemoriesByGroup handles GET /api/groups/{groupId}/memories
// @Summary List memories by group
// @Tags memories
// @Accept json
// @Produce json
// @Param groupId path int true "Group ID"
// @Success 200 {object} responses.ListMemoriesResponse "Successfully listed memories"
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid group ID"
// @Failure 401 {object} responses.ErrorResponse "Unauthorized - User not authenticated"
// @Failure 403 {object} responses.ErrorResponse "Forbidden - Permission denied by service"
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error"
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable"
// @Security ApiKeyAuth
// @Router /api/groups/{groupId}/memories [get]
func (h *MemoryHandler) ListMemoriesByGroup(w http.ResponseWriter, r *http.Request) {
	groupIDStr := chi.URLParam(r, "groupId")
	groupID, err := strconv.ParseUint(groupIDStr, 10, 64)
	if err != nil {
		respondError(w, http.StatusBadRequest, "Invalid group ID")
		return
	}

	req := requests.ListMemoriesByGroupRequest{
		GroupID: groupID,
	}

	resp, err := h.memoryService.ListMemoriesByGroup(r.Context(), &req)
	if err != nil {
		handleServiceError(w, err, "ListMemoriesByGroup")
		return
	}

	var respMemories []responses.DetailedMemoryResponse
	for _, mem := range resp.GetMemories() {
		respMemories = append(respMemories, responses.DetailedMemoryResponse{
			Memory: responses.MemoryResponse{
				Id:        mem.GetMemory().GetId(),
				GroupID:   mem.GetMemory().GetGroupId(),
				UserID:    mem.GetMemory().GetUserId(),
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

	respondJSON(w, http.StatusOK, responses.ListMemoriesResponse{Memories: respMemories})
}

// ListMemoriesByGroupWithFilters handles GET /api/groups/{groupId}/memories/random
// @Summary List memories by group with filters
// @Tags memories
// @Accept json
// @Produce json
// @Param groupId path int true "Group ID"
// @Param media_type query string false "Filter by media type (image, video, quote)"
// @Param is_favourite query string false "Filter by favourite status (true, false)"
// @Param start_time query string false "Filter by start time (ISO 8601 format)"
// @Param end_time query string false "Filter by end time (ISO 8601 format)"
// @Param has_geo query string false "Filter by geolocation data (true)"
// @Param has_music query string false "Filter by music data (true)"
// @Param tags query string false "Filter by tags (comma-separated)"
// @Param numberOfMemories query int false "Number of memories to return (for random selection)" default(10)
// @Success 200 {object} responses.ListMemoriesResponse "Successfully listed memories"
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid input"
// @Failure 401 {object} responses.ErrorResponse "Unauthorized - User not authenticated"
// @Failure 403 {object} responses.ErrorResponse "Forbidden - Permission denied by service"
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error"
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable"
// @Security ApiKeyAuth
// @Router /api/groups/{groupId}/memories/random [get]
func (h *MemoryHandler) ListMemoriesByGroupWithFilters(w http.ResponseWriter, r *http.Request) {
	groupIDStr := chi.URLParam(r, "groupId")
	groupID, err := strconv.ParseUint(groupIDStr, 10, 64)
	if err != nil {
		respondError(w, http.StatusBadRequest, "Invalid group ID")
		return
	}

	// Get filter values from query parameters
	mediaType := r.URL.Query().Get("media_type")
	isFavourite := r.URL.Query().Get("is_favourite")
	startTime := r.URL.Query().Get("start_time")
	endTime := r.URL.Query().Get("end_time")
	hasGeo := r.URL.Query().Get("has_geo")
	hasMusic := r.URL.Query().Get("has_music")
	tags := r.URL.Query().Get("tags")

	numberOfMemoriesStr := r.URL.Query().Get("numberOfMemories")
	numberOfMemories := uint64(10) // Default value
	if numberOfMemoriesStr != "" {
		parsedNumberOfMemories, err := strconv.ParseUint(numberOfMemoriesStr, 10, 64)
		if err != nil {
			respondError(w, http.StatusBadRequest, "Invalid numberOfMemories")
			return
		}
		numberOfMemories = parsedNumberOfMemories
	}

	req := requests.ListMemoriesByGroupWithFiltersRequest{
		GroupID:          groupID,
		Filters:          make(map[string]string), // Initialize the map
		NumberOfMemories: numberOfMemories,
	}

	if mediaType != "" {
		req.Filters["media_type"] = mediaType
	}
	if isFavourite != "" {
		req.Filters["is_favourite"] = isFavourite
	}
	if startTime != "" {
		req.Filters["start_time"] = startTime
	}
	if endTime != "" {
		req.Filters["end_time"] = endTime
	}
	if hasGeo != "" {
		req.Filters["has_geo"] = hasGeo
	}
	if hasMusic != "" {
		req.Filters["has_music"] = hasMusic
	}
	if tags != "" {
		req.Filters["tags"] = tags
	}

	resp, err := h.memoryService.ListMemoriesByGroupWithFilters(r.Context(), &req)
	if err != nil {
		handleServiceError(w, err, "ListMemoriesByGroupWithFilters")
		return
	}

	var respMemories []responses.DetailedMemoryResponse
	for _, mem := range resp.GetMemories() {
		respMemories = append(respMemories, responses.DetailedMemoryResponse{
			Memory: responses.MemoryResponse{
				Id:        mem.GetMemory().GetId(),
				GroupID:   mem.GetMemory().GetGroupId(),
				UserID:    mem.GetMemory().GetUserId(),
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

	respondJSON(w, http.StatusOK, responses.ListMemoriesResponse{Memories: respMemories})
}

// CreateMemoryTag handles POST /api/groups/{groupId}/memories/{memoryId}/tags/{tag}
// @Summary Create a new tag for a memory
// @Tags memories
// @Accept json
// @Produce json
// @Param groupId path int true "Group ID"
// @Param memoryId path int true "Memory ID"
// @Param tag path string true "Tag to add"
// @Success 200 {object} responses.MemoryTagResponse "Successfully created tag"
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid input"
// @Failure 401 {object} responses.ErrorResponse "Unauthorized - User not authenticated"
// @Failure 404 {object} responses.ErrorResponse "Not Found - Memory not found"
// @Failure 403 {object} responses.ErrorResponse "Forbidden - Permission denied by service"
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error"
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable"
// @Security ApiKeyAuth
// @Router /api/groups/{groupId}/memories/{memoryId}/tags/{tag} [post]
func (h *MemoryHandler) CreateMemoryTag(w http.ResponseWriter, r *http.Request) {
	groupIDStr := chi.URLParam(r, "groupId")
	memoryIDStr := chi.URLParam(r, "memoryId")
	tag := chi.URLParam(r, "tag")
	memoryID, err := strconv.ParseUint(memoryIDStr, 10, 64)
	if err != nil {
		respondError(w, http.StatusBadRequest, "Invalid memory ID")
		return
	}
	groupID, err := strconv.ParseUint(groupIDStr, 10, 64)
	if err != nil {
		respondError(w, http.StatusBadRequest, "Invalid group ID")
		return
	}

	req := requests.CreateMemoryTagRequest{
		MemoryID: memoryID,
		GroupID:  groupID,
		Tag:      tag,
	}

	resp, err := h.memoryService.CreateMemoryTag(r.Context(), &req)
	if err != nil {
		handleServiceError(w, err, "CreateMemoryTag")
		return
	}

	responseBody := responses.MemoryTagResponse{
		Tag: resp.Tag.Name,
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// DeleteMemoryTag handles DELETE /api/groups/{groupId}/memories/{memoryId}/tags/{tag}
// @Summary Delete a tag from a memory
// @Tags memories
// @Accept json
// @Produce json
// @Param groupId path int true "Group ID"
// @Param memoryId path int true "Memory ID"
// @Param tag path string true "Tag to delete"
// @Success 200 {object} responses.DeleteMemoryTagResponse "Successfully deleted tag"
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid input"
// @Failure 401 {object} responses.ErrorResponse "Unauthorized - User not authenticated"
// @Failure 404 {object} responses.ErrorResponse "Not Found - Memory or tag not found"
// @Failure 403 {object} responses.ErrorResponse "Forbidden - Permission denied by service"
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error"
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable"
// @Security ApiKeyAuth
// @Router /api/groups/{groupId}/memories/{memoryId}/tags/{tag} [delete]
func (h *MemoryHandler) DeleteMemoryTag(w http.ResponseWriter, r *http.Request) {
	groupIDStr := chi.URLParam(r, "groupId")
	memoryIDStr := chi.URLParam(r, "memoryId")
	tag := chi.URLParam(r, "tag")

	memoryID, err := strconv.ParseUint(memoryIDStr, 10, 64)
	if err != nil {
		respondError(w, http.StatusBadRequest, "Invalid memory ID")
		return
	}

	groupID, err := strconv.ParseUint(groupIDStr, 10, 64)
	if err != nil {
		respondError(w, http.StatusBadRequest, "Invalid group ID")
		return
	}

	req := requests.DeleteMemoryTagRequest{
		MemoryID: memoryID,
		GroupID:  groupID,
		Tag:      tag,
	}

	resp, err := h.memoryService.DeleteMemoryTag(r.Context(), &req)
	if err != nil {
		handleServiceError(w, err, "DeleteMemoryTag")
		return
	}

	if !resp.GetSuccess() {
		log.Printf("MemoryHandler.DeleteMemoryTag: Service reported failure for memory %d", memoryID)
		respondError(w, http.StatusInternalServerError, "Failed to delete memory tag: unexpected service response")
		return
	}

	responseBody := responses.DeleteMemoryTagResponse{
		Success: resp.GetSuccess(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// ListMemoryTagsByMemoryID handles GET /api/groups/{groupId}/memories/{memoryId}/tags
// @Summary List tags for a memory
// @Tags memories
// @Accept json
// @Produce json
// @Param groupId path int true "Group ID"
// @Param memoryId path int true "Memory ID"
// @Success 200 {object} responses.ListMemoryTagsResponse "Successfully listed tags"
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid memory ID"
// @Failure 401 {object} responses.ErrorResponse "Unauthorized - User not authenticated"
// @Failure 403 {object} responses.ErrorResponse "Forbidden - Permission denied by service"
// @Failure 404 {object} responses.ErrorResponse "Not Found - Memory not found"
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error"
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable"
// @Security ApiKeyAuth
// @Router /api/groups/{groupId}/memories/{memoryId}/tags [get]
func (h *MemoryHandler) ListMemoryTagsByMemoryID(w http.ResponseWriter, r *http.Request) {
	groupIDStr := chi.URLParam(r, "groupId")
	memoryIDStr := chi.URLParam(r, "memoryId")
	memoryID, err := strconv.ParseUint(memoryIDStr, 10, 64)
	if err != nil {
		respondError(w, http.StatusBadRequest, "Invalid memory ID")
		return
	}

	groupID, err := strconv.ParseUint(groupIDStr, 10, 64)
	if err != nil {
		respondError(w, http.StatusBadRequest, "Invalid group ID")
		return
	}

	req := requests.ListMemoryTagsByMemoryIDRequest{
		MemoryID: memoryID,
		GroupID:  groupID,
	}

	resp, err := h.memoryService.ListMemoryTagsByMemoryID(r.Context(), &req)
	if err != nil {
		handleServiceError(w, err, "ListMemoryTagsByMemoryID")
		return
	}
	tags := make([]responses.MemoryTagResponse, 0)
	for _, tag := range resp.GetTags() {
		tags = append(tags, responses.MemoryTagResponse{Tag: tag.Name})
	}
	responseBody := responses.ListMemoryTagsResponse{
		Tags: tags,
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// CreateFavourite handles POST /api/groups/{groupId}/memories/{memoryId}/favourite
// @Summary Mark a memory as favourite
// @Tags memories
// @Accept json
// @Produce json
// @Param groupId path int true "Group ID"
// @Param memoryId path int true "Memory ID"
// @Success 200 {object} responses.FavouriteResponse "Successfully marked as favourite"
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid memory ID"
// @Failure 401 {object} responses.ErrorResponse "Unauthorized - User not authenticated"
// @Failure 403 {object} responses.ErrorResponse "Forbidden - Permission denied by service"
// @Failure 404 {object} responses.ErrorResponse "Not Found - Memory not found"
// @Failure 409 {object} responses.ErrorResponse "Conflict - Memory is already a favourite"
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error"
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable"
// @Security ApiKeyAuth
// @Router /api/groups/{groupId}/memories/{memoryId}/favourite [post]
func (h *MemoryHandler) CreateFavourite(w http.ResponseWriter, r *http.Request) {
	groupIDStr := chi.URLParam(r, "groupId")
	memoryIDStr := chi.URLParam(r, "memoryId")
	memoryID, err := strconv.ParseUint(memoryIDStr, 10, 64)
	if err != nil {
		respondError(w, http.StatusBadRequest, "Invalid memory ID")
		return
	}

	groupID, err := strconv.ParseUint(groupIDStr, 10, 64)
	if err != nil {
		respondError(w, http.StatusBadRequest, "Invalid group ID")
		return
	}

	req := requests.CreateFavouriteRequest{
		GroupID:  groupID,
		MemoryID: memoryID,
	}

	resp, err := h.memoryService.CreateFavourite(r.Context(), &req)
	if err != nil {
		handleServiceError(w, err, "CreateFavourite")
		return
	}

	responseBody := responses.FavouriteResponse{
		UserID:   resp.Favourite.GetUserId(),
		MemoryID: resp.Favourite.GetMemoryId(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// DeleteFavourite handles DELETE /api/groups/{groupId}/memories/{memoryId}/favourite
// @Summary Unmark a memory as favourite
// @Tags memories
// @Accept json
// @Produce json
// @Param groupId path int true "Group ID"
// @Param memoryId path int true "Memory ID"
// @Success 200 {object} responses.DeleteFavouriteResponse "Successfully unmarked as favourite"
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid memory ID"
// @Failure 401 {object} responses.ErrorResponse "Unauthorized - User not authenticated"
// @Failure 403 {object} responses.ErrorResponse "Forbidden - Permission denied by service"
// @Failure 404 {object} responses.ErrorResponse "Not Found - Memory not found or not a favourite"
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error"
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable"
// @Security ApiKeyAuth
// @Router /api/groups/{groupId}/memories/{memoryId}/favourite [delete]
func (h *MemoryHandler) DeleteFavourite(w http.ResponseWriter, r *http.Request) {
	groupIDStr := chi.URLParam(r, "groupId")
	memoryIDStr := chi.URLParam(r, "memoryId")
	memoryID, err := strconv.ParseUint(memoryIDStr, 10, 64)
	if err != nil {
		respondError(w, http.StatusBadRequest, "Invalid memory ID")
		return
	}

	groupID, err := strconv.ParseUint(groupIDStr, 10, 64)
	if err != nil {
		respondError(w, http.StatusBadRequest, "Invalid group ID")
		return
	}

	req := requests.DeleteFavouriteRequest{
		GroupID:  groupID,
		MemoryID: memoryID,
	}

	resp, err := h.memoryService.DeleteFavourite(r.Context(), &req)
	if err != nil {
		handleServiceError(w, err, "DeleteFavourite")
		return
	}

	if !resp.GetSuccess() {
		log.Printf("MemoryHandler.DeleteMemoryTag: Service reported failure for memory %d", memoryID)
		respondError(w, http.StatusInternalServerError, "Failed to delete memory tag: unexpected service response")
		return
	}

	responseBody := responses.DeleteFavouriteResponse{
		Success: resp.GetSuccess(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}
