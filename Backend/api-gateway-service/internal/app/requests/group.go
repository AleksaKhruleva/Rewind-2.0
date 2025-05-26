package requests

// CreateGroupRequest represents the HTTP request body for creating a new group.
type CreateGroupRequest struct {
	Name string `json:"name" validate:"required"` // Group name is required
}

// UpdateGroupRequest represents the HTTP request body for updating group details.
// Pointers are used for optional fields to distinguish between missing and empty values.
type UpdateGroupRequest struct {
	Name  *string `json:"name"`  // Optional group name
	Image *string `json:"image"` // Optional image URL
}

// SetGroupAdminRequest represents the HTTP request body for setting/unsetting a user as group admin.
type SetGroupAdminRequest struct {
	IsAdmin bool `json:"is_admin"` // True to set as admin, false to unset
}

// CreateGroupInvitationRequest represents the HTTP request body for creating a group invitation.
// Duration is represented in seconds and is optional.
type CreateGroupInvitationRequest struct {
	DurationSeconds *int64 `json:"duration_seconds"` // Optional duration in seconds
}
