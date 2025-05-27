package handlers

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"strconv" // Needed for parsing uint64 from URL params
	"time"    // Needed for duration handling

	"github.com/go-chi/chi/v5"

	"Rewind-api-gateway-service/internal/app/requests"  // Your HTTP request structs
	"Rewind-api-gateway-service/internal/app/responses" // Your HTTP response structs
	"Rewind-api-gateway-service/internal/app/services"  // Your API Gateway service layer
)

// GroupHandler структура для обработчиков запросов групп.
type GroupHandler struct {
	groupService services.GroupServiceInterface
	// authService services.AuthServiceInterface // Include if needed for handler-specific auth logic,
	// but service layer already handles user verification.
}

// NewGroupHandler создает новый обработчик групп.
func NewGroupHandler(groupService services.GroupServiceInterface) *GroupHandler {
	return &GroupHandler{groupService: groupService}
}

// CreateGroup обработчик для POST /api/groups
// @Summary Create a new group
// @Tags groups
// @Accept json
// @Produce json
// @Param body body requests.CreateGroupRequest true "Group details"
// @Success 200 {object} responses.GroupResponse "Successfully created group"
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid request body or data"
// @Failure 401 {object} responses.ErrorResponse "Unauthorized - User not authenticated"
// @Failure 403 {object} responses.ErrorResponse "Forbidden - Permission denied by service"
// @Failure 404 {object} responses.ErrorResponse "Not Found - User not found"
// @Failure 409 {object} responses.ErrorResponse "Conflict - Group with this name already exists"
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error"
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable"
// @Security ApiKeyAuth
// @Router /api/groups [post]
func (h *GroupHandler) CreateGroup(w http.ResponseWriter, r *http.Request) {
	var reqBody requests.CreateGroupRequest
	if err := decodeJSONBody(r, &reqBody); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	// User ID is extracted by the service layer from the context
	resp, err := h.groupService.CreateGroup(r.Context(), reqBody.Name)
	if err != nil {
		handleServiceError(w, err, "CreateGroup")
		return
	}

	group := resp.GetGroup()
	if group == nil {
		log.Println("GroupHandler.CreateGroup: Service returned success but group is nil")
		respondError(w, http.StatusInternalServerError, "Failed to create group: unexpected service response")
		return
	}

	// Map protobuf response to HTTP response struct
	responseBody := responses.GroupResponse{
		Id:          group.GetId(),
		Name:        group.GetName(),
		Image:       group.GetImage(),
		AdminUserId: group.GetAdminUserId(),
		CreatedAt:   group.GetCreatedAt().AsTime(),
		UpdatedAt:   group.GetUpdatedAt().AsTime(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// GetGroup обработчик для GET /api/groups/{id}
// @Summary Get group details by ID
// @Tags groups
// @Produce json
// @Param id path int true "Group ID"
// @Success 200 {object} responses.GetGroupResponse "Group details"
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid group ID format"
// @Failure 401 {object} responses.ErrorResponse "Unauthorized - User not authenticated"
// @Failure 403 {object} responses.ErrorResponse "Forbidden - User is not a member of the group"
// @Failure 404 {object} responses.ErrorResponse "Not Found - Group or User not found"
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error"
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable"
// @Security ApiKeyAuth
// @Router /api/groups/{id} [get]
func (h *GroupHandler) GetGroup(w http.ResponseWriter, r *http.Request) {
	groupIDStr := chi.URLParam(r, "id")
	groupID, err := strconv.ParseUint(groupIDStr, 10, 64)
	if err != nil || groupID == 0 {
		log.Printf("GroupHandler.GetGroup: Invalid group ID in URL: %s", groupIDStr)
	}

	// User ID is extracted by the service layer from the context
	resp, err := h.groupService.GetGroup(r.Context(), groupID)
	if err != nil {
		handleServiceError(w, err, "GetGroup")
		return
	}

	group := resp.GetGroup()
	if group == nil {
		log.Println("GroupHandler.GetGroup: Service returned success but group is nil")
		respondError(w, http.StatusInternalServerError, "Failed to retrieve group: unexpected service response")
		return
	}

	// Map protobuf response to HTTP response struct
	responseBody := responses.GetGroupResponse{
		GroupResponse: responses.GroupResponse{
			Id:          group.GetId(),
			Name:        group.GetName(),
			Image:       group.GetImage(),
			AdminUserId: group.GetAdminUserId(),
			CreatedAt:   group.GetCreatedAt().AsTime(),
			UpdatedAt:   group.GetUpdatedAt().AsTime(),
		},
		IsAdmin: resp.GetIsAdmin(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// UpdateGroup обработчик для PUT /api/groups/{id}
// @Summary Update group details by ID
// @Tags groups
// @Accept multipart/form-data
// @Produce json
// @Param id path int true "Group ID"
// @Param name formData string false "Updated group name (optional)"
// @Param image formData file false "Updated group image file (optional)"
// @Success 200 {object} responses.GroupResponse "Successfully updated group"
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid request, data, or group ID format"
// @Failure 401 {object} responses.ErrorResponse "Unauthorized - User not authenticated"
// @Failure 403 {object} responses.ErrorResponse "Forbidden - User is not an administrator of the group"
// @Failure 404 {object} responses.ErrorResponse "Not Found - Group or User not found"
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error"
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable"
// @Security ApiKeyAuth
// @Router /api/groups/{id} [put]
func (h *GroupHandler) UpdateGroup(w http.ResponseWriter, r *http.Request) {
	groupIDStr := chi.URLParam(r, "id")
	groupID, err := strconv.ParseUint(groupIDStr, 10, 64)
	if err != nil || groupID == 0 {
		log.Printf("GroupHandler.UpdateGroup: Invalid group ID in URL: %s", groupIDStr)
		respondError(w, http.StatusBadRequest, "Invalid group ID format")
		return
	}

	// Parse the multipart form with a maximum size (e.g., 25MB)
	if err := r.ParseMultipartForm(25 << 20); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request: %v", err))
		return
	}

	// Extract the name from the form
	name := r.FormValue("name")
	var namePtr *string
	if name != "" {
		namePtr = &name
	}

	// Extract the image file from the form
	file, _, err := r.FormFile("image")
	var imageData []byte
	if err == nil && file != nil {
		defer file.Close()
		imageData, err = io.ReadAll(file)
		if err != nil {
			respondError(w, http.StatusInternalServerError, fmt.Sprintf("Failed to read image file: %v", err))
			return
		}
	} else if err != http.ErrMissingFile {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid image file: %v", err))
		return
	}

	resp, err := h.groupService.UpdateGroup(r.Context(), groupID, namePtr, imageData)
	if err != nil {
		handleServiceError(w, err, "UpdateGroup")
		return
	}

	group := resp.GetGroup()
	if group == nil {
		log.Println("GroupHandler.UpdateGroup: Service returned success but group is nil")
		respondError(w, http.StatusInternalServerError, "Failed to update group: unexpected service response")
		return
	}

	// Map protobuf response to HTTP response struct
	responseBody := responses.GroupResponse{
		Id:          group.GetId(),
		Name:        group.GetName(),
		Image:       group.GetImage(),
		AdminUserId: group.GetAdminUserId(),
		CreatedAt:   group.GetCreatedAt().AsTime(),
		UpdatedAt:   group.GetUpdatedAt().AsTime(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// DeleteGroup обработчик для DELETE /api/groups/{id}
// @Summary Delete a group by ID
// @Tags groups
// @Produce json
// @Param id path int true "Group ID"
// @Success 200 {object} responses.DeleteGroupResponse "Successfully deleted group"
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid group ID format"
// @Failure 401 {object} responses.ErrorResponse "Unauthorized - User not authenticated"
// @Failure 403 {object} responses.ErrorResponse "Forbidden - User is not an administrator of the group"
// @Failure 404 {object} responses.ErrorResponse "Not Found - Group or User not found"
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error"
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable"
// @Security ApiKeyAuth
// @Router /api/groups/{id} [delete]
func (h *GroupHandler) DeleteGroup(w http.ResponseWriter, r *http.Request) {
	groupIDStr := chi.URLParam(r, "id")
	groupID, err := strconv.ParseUint(groupIDStr, 10, 64)
	if err != nil || groupID == 0 {
		log.Printf("GroupHandler.DeleteGroup: Invalid group ID in URL: %s", groupIDStr)
		respondError(w, http.StatusBadRequest, "Invalid group ID format")
		return
	}

	// Service layer handles user ID extraction and permission check
	resp, err := h.groupService.DeleteGroup(r.Context(), groupID)
	if err != nil {
		handleServiceError(w, err, "DeleteGroup")
		return
	}

	if !resp.GetSuccess() {
		// This case might indicate a logical failure in the service that wasn't mapped to a gRPC error code
		log.Printf("GroupHandler.DeleteGroup: Service reported failure for group %d", groupID)
		respondError(w, http.StatusInternalServerError, "Failed to delete group")
		return
	}

	responseBody := responses.DeleteGroupResponse{
		Success: resp.GetSuccess(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// ListGroupMembers обработчик для GET /api/groups/{id}/members
// @Summary List members of a group
// @Tags groups
// @Produce json
// @Param id path int true "Group ID"
// @Success 200 {object} responses.ListGroupMembersResponse "List of group members"
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid group ID format"
// @Failure 401 {object} responses.ErrorResponse "Unauthorized - User not authenticated"
// @Failure 403 {object} responses.ErrorResponse "Forbidden - User is not a member of the group"
// @Failure 404 {object} responses.ErrorResponse "Not Found - Group or User not found"
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error"
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable"
// @Security ApiKeyAuth
// @Router /api/groups/{id}/members [get]
func (h *GroupHandler) ListGroupMembers(w http.ResponseWriter, r *http.Request) {
	groupIDStr := chi.URLParam(r, "id")
	groupID, err := strconv.ParseUint(groupIDStr, 10, 64)
	if err != nil || groupID == 0 {
		log.Printf("GroupHandler.ListGroupMembers: Invalid group ID in URL: %s", groupIDStr)
		respondError(w, http.StatusBadRequest, "Invalid group ID format")
		return
	}

	resp, err := h.groupService.ListGroupMembers(r.Context(), groupID)
	if err != nil {
		handleServiceError(w, err, "ListGroupMembers")
		return
	}

	// Map protobuf response to HTTP response struct
	responseBody := responses.ListGroupMembersResponse{
		Members: make([]responses.MemberDetails, len(resp.GetMembers())),
	}
	for i, memberPB := range resp.GetMembers() {
		responseBody.Members[i] = responses.MemberDetails{
			UserId:              memberPB.GetUserId(),
			Username:            memberPB.GetUsername(),
			UserImage:           memberPB.GetUserImage(),
			IsAdmin:             memberPB.GetIsAdmin(),
			MemoriesAddedCount:  memberPB.GetMemoriesAddedCount(),
			MemoriesViewedCount: memberPB.GetMemoriesViewedCount(),
			JoinedAt:            memberPB.GetJoinedAt().AsTime(),
		}
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// RemoveGroupMember обработчик для DELETE /api/groups/{group_id}/members/{user_id}
// @Summary Remove a member from a group
// @Tags groups
// @Produce json
// @Param group_id path int true "Group ID"
// @Param user_id path int true "User ID to remove"
// @Success 200 {object} responses.DeleteUserResponse "Successfully removed member"
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid group ID or user ID format"
// @Failure 401 {object} responses.ErrorResponse "Unauthorized - User not authenticated"
// @Failure 403 {object} responses.ErrorResponse "Forbidden - User does not have permission (not admin or not removing self)"
// @Failure 404 {object} responses.ErrorResponse "Not Found - Group or User not found"
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error"
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable"
// @Security ApiKeyAuth
// @Router /api/groups/{group_id}/members/{user_id} [delete]
func (h *GroupHandler) RemoveGroupMember(w http.ResponseWriter, r *http.Request) {
	groupIDStr := chi.URLParam(r, "group_id")
	groupID, err := strconv.ParseUint(groupIDStr, 10, 64)
	if err != nil || groupID == 0 {
		log.Printf("GroupHandler.RemoveGroupMember: Invalid group ID in URL: %s", groupIDStr)
		respondError(w, http.StatusBadRequest, "Invalid group ID format")
		return
	}

	userToRemoveIDStr := chi.URLParam(r, "user_id")
	userToRemoveID, err := strconv.ParseUint(userToRemoveIDStr, 10, 64)
	if err != nil || userToRemoveID == 0 {
		log.Printf("GroupHandler.RemoveGroupMember: Invalid user ID in URL: %s", userToRemoveIDStr)
		respondError(w, http.StatusBadRequest, "Invalid user ID format")
		return
	}

	// Service layer handles requesting user ID extraction and permission/existence checks
	resp, err := h.groupService.RemoveGroupMember(r.Context(), groupID, userToRemoveID)
	if err != nil {
		handleServiceError(w, err, "RemoveGroupMember")
		return
	}

	if !resp.GetSuccess() {
		log.Printf("GroupHandler.RemoveGroupMember: Service reported failure for group %d, user %d", groupID, userToRemoveID)
		respondError(w, http.StatusInternalServerError, "Failed to remove group member")
		return
	}

	responseBody := responses.DeleteUserResponse{
		Success: resp.GetSuccess(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// CreateGroupInvitation обработчик для POST /api/groups/{id}/invitations
// @Summary Create a group invitation
// @Tags groups
// @Accept json
// @Produce json
// @Param id path int true "Group ID"
// @Param body body requests.CreateGroupInvitationRequest true "Invitation details (optional duration)"
// @Success 200 {object} responses.CreateGroupInvitationResponse "Successfully created invitation"
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid group ID format or request body"
// @Failure 401 {object} responses.ErrorResponse "Unauthorized - User not authenticated"
// @Failure 403 {object} responses.ErrorResponse "Forbidden - User is not an administrator of the group"
// @Failure 404 {object} responses.ErrorResponse "Not Found - Group or User not found"
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error"
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable"
// @Security ApiKeyAuth
// @Router /api/groups/{id}/invitations [post]
func (h *GroupHandler) CreateGroupInvitation(w http.ResponseWriter, r *http.Request) {
	groupIDStr := chi.URLParam(r, "id")
	groupID, err := strconv.ParseUint(groupIDStr, 10, 64)
	if err != nil || groupID == 0 {
		log.Printf("GroupHandler.CreateGroupInvitation: Invalid group ID in URL: %s", groupIDStr)
		respondError(w, http.StatusBadRequest, "Invalid group ID format")
		return
	}

	var reqBody requests.CreateGroupInvitationRequest
	if err := decodeJSONBody(r, &reqBody); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	// Convert optional int duration (seconds) to *time.Duration
	var durationPtr *time.Duration
	if reqBody.DurationSeconds != nil {
		duration := time.Duration(*reqBody.DurationSeconds) * time.Second
		durationPtr = &duration
	}

	// Service layer handles requesting user ID extraction and permission/existence checks
	resp, err := h.groupService.CreateGroupInvitation(r.Context(), groupID, durationPtr)
	if err != nil {
		handleServiceError(w, err, "CreateGroupInvitation")
		return
	}

	invitationPB := resp.GetInvitation()
	if invitationPB == nil {
		log.Println("GroupHandler.CreateGroupInvitation: Service returned success but invitation is nil")
		respondError(w, http.StatusInternalServerError, "Failed to create invitation: unexpected service response")
		return
	}

	// Map protobuf response to HTTP response struct
	responseBody := responses.CreateGroupInvitationResponse{
		InvitationCode: invitationPB.GetInvitationCode(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// AcceptGroupInvitation обработчик для POST /api/invitations/{code}/accept
// @Summary Accept a group invitation
// @Tags groups
// @Produce json
// @Param code path string true "Invitation Code"
// @Success 200 {object} responses.AcceptGroupInvitationResponse "Successfully accepted invitation"
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid invitation code format"
// @Failure 401 {object} responses.ErrorResponse "Unauthorized - User not authenticated"
// @Failure 404 {object} responses.ErrorResponse "Not Found - Group or User not found"
// @Failure 409 {object} responses.ErrorResponse "Conflict - User is already a member of the group"
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error"
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable"
// @Security ApiKeyAuth
// @Router /api/invitations/{code}/accept [post]
func (h *GroupHandler) AcceptGroupInvitation(w http.ResponseWriter, r *http.Request) {
	invitationCode := chi.URLParam(r, "code")
	if invitationCode == "" {
		log.Println("GroupHandler.AcceptGroupInvitation: Invitation code is missing in URL")
		respondError(w, http.StatusBadRequest, "Invitation code is required")
		return
	}

	// Service layer handles requesting user ID extraction and existence checks
	resp, err := h.groupService.AcceptGroupInvitation(r.Context(), invitationCode)
	if err != nil {
		handleServiceError(w, err, "AcceptGroupInvitation")
		return
	}

	groupPB := resp.GetGroup()
	memberPB := resp.GetGroupMember()

	if groupPB == nil || memberPB == nil {
		log.Println("GroupHandler.AcceptGroupInvitation: Service returned success but group or member is nil")
		respondError(w, http.StatusInternalServerError, "Failed to accept invitation: unexpected service response")
		return
	}

	// Map protobuf response to HTTP response struct
	responseBody := responses.AcceptGroupInvitationResponse{
		Group: responses.GroupResponse{ // Reuse GroupResponse struct
			Id:          groupPB.GetId(),
			Name:        groupPB.GetName(),
			Image:       groupPB.GetImage(),
			AdminUserId: groupPB.GetAdminUserId(),
			CreatedAt:   groupPB.GetCreatedAt().AsTime(),
			UpdatedAt:   groupPB.GetUpdatedAt().AsTime(),
		},
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// ListUserGroups обработчик для GET /api/users/{user_id}/groups
// @Summary List groups for a specific user
// @Tags groups
// @Produce json
// @Success 200 {object} responses.ListUserGroupsResponse "List of groups for the user"
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid user ID format"
// @Failure 401 {object} responses.ErrorResponse "Unauthorized - User not authenticated"
// @Failure 403 {object} responses.ErrorResponse "Forbidden - User does not have permission to list groups for this user"
// @Failure 404 {object} responses.ErrorResponse "Not Found - Group or User not found"
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error"
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable"
// @Security ApiKeyAuth
// @Router /api/users/groups [get]
func (h *GroupHandler) ListUserGroups(w http.ResponseWriter, r *http.Request) {
	// Service layer handles requesting user ID extraction and permission/existence checks
	resp, err := h.groupService.ListUserGroups(r.Context())
	if err != nil {
		handleServiceError(w, err, "ListUserGroups")
		return
	}

	// Map protobuf response to HTTP response struct
	responseBody := responses.ListUserGroupsResponse{
		Groups: make([]responses.GroupResponse, len(resp.GetGroups())), // Reuse GroupResponse struct
	}
	for i, groupPB := range resp.GetGroups() {
		responseBody.Groups[i] = responses.GroupResponse{
			Id:          groupPB.GetId(),
			Name:        groupPB.GetName(),
			Image:       groupPB.GetImage(),
			AdminUserId: groupPB.GetAdminUserId(),
			CreatedAt:   groupPB.GetCreatedAt().AsTime(),
			UpdatedAt:   groupPB.GetUpdatedAt().AsTime(),
		}
	}

	respondJSON(w, http.StatusOK, responseBody)
}
