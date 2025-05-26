package responses

import (
	"time"
)

// MemoryResponse represents the HTTP response for a single memory.
type MemoryResponse struct {
	Id        uint64    `json:"id"`
	GroupID   uint64    `json:"groupId"`
	UserID    uint64    `json:"userId"`
	Username  string    `json:"username"`
	UserImage string    `json:"userImage"`
	MediaType string    `json:"mediaType"`
	MediaURL  string    `json:"mediaUrl"`
	Latitude  float64   `json:"latitude"`
	Longitude float64   `json:"longitude"`
	MusicID   string    `json:"musicId"`
	Offset    float64   `json:"offset"`
	Duration  float64   `json:"duration"`
	CreatedAt time.Time `json:"createdAt"`
	UpdatedAt time.Time `json:"updatedAt"`
}

// DetailedMemoryResponse represents the HTTP response for a detailed memory.
type DetailedMemoryResponse struct {
	Memory      MemoryResponse `json:"memory"`
	Tags        []string       `json:"tags"`
	IsFavourite bool           `json:"isFavourite"`
}

// ListMemoriesResponse represents the HTTP response for a list of memories.
type ListMemoriesResponse struct {
	Memories []DetailedMemoryResponse `json:"memories"`
}

// MemoryTagResponse represents the HTTP response for a memory tag.
type MemoryTagResponse struct {
	Tag string `json:"tag"`
}

// ListMemoryTagsResponse represents the HTTP response for a list of memory tags.
type ListMemoryTagsResponse struct {
	Tags []MemoryTagResponse `json:"tags"`
}

// FavouriteResponse represents the HTTP response for a favourite.
type FavouriteResponse struct {
	MemoryID uint64 `json:"memoryId"`
	UserID   uint64 `json:"userId"`
}

// DeleteMemoryResponse represents the response for the DeleteMemory endpoint.
type DeleteMemoryResponse struct {
	Success bool `json:"success"`
}

// DeleteMemoryTagResponse represents the HTTP response for a delete memory tags.
type DeleteMemoryTagResponse struct {
	Success bool `json:"success"`
}

// DeleteFavouriteResponse represents the HTTP response for a delete memory favourite.
type DeleteFavouriteResponse struct {
	Success bool `json:"success"`
}
