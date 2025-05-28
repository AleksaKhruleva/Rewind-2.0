package requests

// CreateMemoryRequest represents the HTTP request body for creating a memory.
type CreateMemoryRequest struct {
	GroupID   uint64   `form:"groupId"` // Use 'form' tag for multipart parsing
	MediaType string   `form:"mediaType"`
	Latitude  *float64 `form:"latitude,omitempty"`
	Longitude *float64 `form:"longitude,omitempty"`
	MusicID   *string  `form:"musicId,omitempty"`
	Offset    *float64 `form:"offset,omitempty"`
	Duration  *float64 `form:"duration,omitempty"`
	Tags      []string `form:"tags,omitempty"`
}

// DeleteMemoryRequest represents the HTTP request for deleting a memory.
type DeleteMemoryRequest struct {
	GroupID  uint64 `json:"groupId"`
	MemoryID uint64 `json:"memoryId"`
}

// GetMemoryRequest represents the HTTP request for deleting a memory.
type GetMemoryRequest struct {
	GroupID  uint64 `json:"groupId"`
	MemoryID uint64 `json:"memoryId"`
}

// ListMemoriesByGroupRequest represents the HTTP request for listing memories by group.
type ListMemoriesByGroupRequest struct {
	GroupID uint64 `json:"groupId"`
}

// ListMemoriesByGroupWithFiltersRequest represents the HTTP request for listing memories with filters.
type ListMemoriesByGroupWithFiltersRequest struct {
	GroupID          uint64            `json:"groupId"`
	Filters          map[string]string `json:"filters,omitempty"`
	NumberOfMemories uint64            `json:"numberOfMemories"`
}

// CreateMemoryTagRequest represents the HTTP request for creating a memory tag.
type CreateMemoryTagRequest struct {
	GroupID  uint64 `json:"groupId"`
	MemoryID uint64 `json:"memoryId"`
	Tag      string `json:"tag"`
}

// DeleteMemoryTagRequest represents the HTTP request for deleting a memory tag.
type DeleteMemoryTagRequest struct {
	GroupID  uint64 `json:"groupId"`
	MemoryID uint64 `json:"memoryId"`
	Tag      string `json:"tag"` // The tag value to delete
}

// ListMemoryTagsByMemoryIDRequest represents the HTTP request for listing memory tags.
type ListMemoryTagsByMemoryIDRequest struct {
	GroupID  uint64 `json:"groupId"`
	MemoryID uint64 `json:"memoryId"`
}

// CreateFavouriteRequest represents the HTTP request for creating a favourite.
type CreateFavouriteRequest struct {
	GroupID  uint64 `json:"groupId"`
	MemoryID uint64 `json:"memoryId"`
}

// DeleteFavouriteRequest represents the HTTP request for deleting a favourite.
type DeleteFavouriteRequest struct {
	GroupID  uint64 `json:"groupId"`
	MemoryID uint64 `json:"memoryId"`
}
