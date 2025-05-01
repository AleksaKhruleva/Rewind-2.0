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
