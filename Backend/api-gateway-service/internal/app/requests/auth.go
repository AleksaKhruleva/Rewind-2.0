package requests

type StartRegistrationRequest struct {
	Email string `json:"email"`
}

type VerifyEmailCodeRequest struct {
	RegistrationID   string `json:"registration_id"`
	VerificationCode string `json:"verification_code"`
}

type SetPasswordAndUsernameRequest struct {
	RegistrationID string `json:"registration_id"`
	Password       string `json:"password"`
	Username       string `json:"username"`
}

type LoginRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type RefreshTokenRequest struct {
	RefreshToken string `json:"refresh_token"`
}

type ForgotPasswordRequest struct {
	Email string `json:"email"`
}

type ResetPasswordRequest struct {
	Token       string `json:"token"`
	NewPassword string `json:"new_password"`
}

type LogoutRequest struct {
	RefreshToken string `json:"refresh_token"`
}

type DeleteUserRequest struct {
	Email string `json:"email"`
}

type UpdateUsernameRequest struct {
	NewUsername string `json:"new_username"`
}

type CheckPasswordRequest struct {
	Password string `json:"password"`
}

type UpdateEmailRequest struct {
	NewEmail string `json:"new_email"`
	Password string `json:"password"`
}

type VerifyNewEmailCodeRequest struct {
	NewEmail         string `json:"new_email"`
	VerificationCode string `json:"verification_code"`
}

type VerifyPasswordResetCodeRequest struct {
	VerificationCode string `json:"verification_code"`
}

type SetNewPasswordRequest struct {
	NewPassword string `json:"new_password"`
}
