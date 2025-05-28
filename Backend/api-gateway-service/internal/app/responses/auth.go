package responses

// StartRegistrationResponse represents the response for the StartRegistration endpoint.
type StartRegistrationResponse struct {
	RegistrationID string `json:"registration_id"` // Unique ID to track the registration process
	Success        bool   `json:"success"`
}

// VerifyEmailCodeResponse represents the response for the VerifyEmailCode endpoint.
type VerifyEmailCodeResponse struct {
	Success bool `json:"success"`
}

// SetPasswordAndUsernameResponse represents the response for the SetPasswordAndUsername endpoint.
type SetPasswordAndUsernameResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
}

// LoginResponse represents the response for the Login endpoint.
type LoginResponse struct {
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
}

// RefreshTokenResponse represents the response for the RefreshToken endpoint.
type RefreshTokenResponse struct {
	AccessToken string `json:"access_token"`
}

// ForgotPasswordResponse represents the response for the ForgotPassword endpoint.
type ForgotPasswordResponse struct {
	Success bool `json:"success"`
}

// ResetPasswordResponse represents the response for the ResetPassword endpoint.
type ResetPasswordResponse struct {
	Success bool `json:"success"`
}

// LogoutResponse represents the response for the Logout endpoint.
type LogoutResponse struct {
	Success bool `json:"success"`
}

// DeleteUserResponse represents the response for the DeleteUser endpoint.
type DeleteUserResponse struct {
	Success bool `json:"success"`
}

// GetUserByIDResponse represents the HTTP response body for getting user details by ID.
type GetUserByIDResponse struct {
	ID                  uint64 `json:"id"`                    // User ID
	Username            string `json:"username"`              // Username
	Email               string `json:"email"`                 // Email address
	Image               string `json:"image"`                 // User image URL
	MemoriesAddedCount  uint64 `json:"memories_added_count"`  // Number of memories added by the user
	InvitedMembersCount uint64 `json:"invited_members_count"` // Number of invited members
	MemoriesViewedCount uint64 `json:"memories_viewed_count"` // Number of memories rolled by the user
}

type UpdateUsernameResponse struct {
	Success bool `json:"success"`
}

type CheckPasswordResponse struct {
	Success bool `json:"success"`
}

type UpdateEmailResponse struct {
	Success bool `json:"success"`
}

type VerifyNewEmailCodeResponse struct {
	Success bool `json:"success"`
}

type UpdateAvatarResponse struct {
	Success bool `json:"success"`
}

type StartPasswordResetResponse struct {
	Success bool `json:"success"`
}

type VerifyPasswordResetCodeResponse struct {
	Success bool `json:"success"`
}

type SetNewPasswordResponse struct {
	Success bool `json:"success"`
}

type DeleteAvatarResponse struct {
	Success bool `json:"success"`
}
