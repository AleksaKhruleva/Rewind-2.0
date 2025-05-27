package responses

import "time"

// GroupResponse represents the structure of a group returned in HTTP responses.
// Based on the pb.Group message.
type GroupResponse struct {
	Id          uint64    `json:"id"`            // Group ID
	Name        string    `json:"name"`          // Group name
	Image       string    `json:"image"`         // Group image URL
	AdminUserId uint64    `json:"admin_user_id"` // ID of the group administrator
	CreatedAt   time.Time `json:"created_at"`    // Creation timestamp
	UpdatedAt   time.Time `json:"updated_at"`    // Last update timestamp
}

// GetGroupResponse represents the HTTP response body for getting group details.
// Includes group details and the requesting user's admin status in that group.
type GetGroupResponse struct {
	GroupResponse
	IsAdmin bool `json:"is_admin"` // Is the requesting user an admin of this group?
}

// MemberDetails represents the details of a group member returned in HTTP responses.
// Based on the MemberDetails message in the Group service proto.
type MemberDetails struct {
	UserId              uint64    `json:"user_id"`               // User ID
	Username            string    `json:"username"`              // Username from Auth-Service
	UserImage           string    `json:"user_image"`            // User image URL from Auth-Service
	IsAdmin             bool      `json:"is_admin"`              // Is this member an admin of the group?
	MemoriesAddedCount  uint64    `json:"memories_added_count"`  // Count of memories added by this member
	MemoriesViewedCount uint64    `json:"memories_viewed_count"` // Count of memories viewed by this member
	JoinedAt            time.Time `json:"joined_at"`             // Timestamp when the user joined the group
}

// ListGroupMembersResponse represents the HTTP response body for listing group members.
type ListGroupMembersResponse struct {
	Members []MemberDetails `json:"members"` // List of group members with details
}

// RemoveGroupMemberResponse represents the HTTP response body for removing a group member.
type RemoveGroupMemberResponse struct {
	Success bool `json:"success"` // Indicates if the operation was successful
}

// SetGroupAdminResponse represents the HTTP response body for setting/unsetting a user as group admin.
type SetGroupAdminResponse struct {
	Success bool `json:"success"` // Indicates if the operation was successful
}

// CreateGroupInvitationResponse represents the HTTP response body for creating a group invitation.
type CreateGroupInvitationResponse struct {
	InvitationCode string `json:"invitation_code"` // The generated invitation code
}

// GroupMemberResponse represents basic group member details for use in other responses.
// Based on the pb.GroupMember message.
type GroupMemberResponse struct {
	Id                  uint64    `json:"id"`                    // Group Member entry ID
	GroupId             uint64    `json:"group_id"`              // Associated Group ID
	UserId              uint64    `json:"user_id"`               // Associated User ID
	IsAdmin             bool      `json:"is_admin"`              // Is this member an admin?
	MemoriesAddedCount  uint64    `json:"memories_added_count"`  // Memories added count
	MemoriesViewedCount uint64    `json:"memories_viewed_count"` // Memories viewed count
	CreatedAt           time.Time `json:"created_at"`            // Creation timestamp
	UpdatedAt           time.Time `json:"updated_at"`            // Last update timestamp
}

// AcceptGroupInvitationResponse represents the HTTP response body for accepting an invitation.
type AcceptGroupInvitationResponse struct {
	Group GroupResponse `json:"group"` // Details of the group joined
}

// ListUserGroupsResponse represents the HTTP response body for listing groups for a user.
type ListUserGroupsResponse struct {
	Groups []GroupResponse `json:"groups"` // List of groups
	// TODO: Optionally include user's role in each group if needed in this list
	// type UserGroupDetails struct {
	//    Group GroupResponse `json:"group"`
	//    IsAdmin bool `json:"is_admin"`
	// }
	// UserGroups []UserGroupDetails `json:"user_groups"`
}

// DeleteGroupResponse represents the response for the DeleteGroup endpoint.
type DeleteGroupResponse struct {
	Success bool `json:"success"`
}
