package handlers

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"strconv" // For parsing ID from URL

	"github.com/go-chi/chi/v5"

	"Rewind-api-gateway-service/internal/app/requests"
	"Rewind-api-gateway-service/internal/app/responses"
	"Rewind-api-gateway-service/internal/app/services"
)

// AuthHandler структура для обработчиков аутентификации.
type AuthHandler struct {
	authService services.AuthServiceInterface
}

// NewAuthHandler создает новый обработчик аутентификации.
func NewAuthHandler(authService services.AuthServiceInterface) *AuthHandler {
	return &AuthHandler{authService: authService}
}

// StartRegistration обработчик для POST /api/auth/register.
// @Summary Start user registration (First stage of registration).
// @Description Initiates the user registration process by sending a verification email.
// @Tags auth
// @Accept json
// @Produce json
// @Param body body requests.StartRegistrationRequest true "User email for registration".
// @Success 200 {object} responses.StartRegistrationResponse "Successfully initiated registration".
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid email format or request body".
// @Failure 409 {object} responses.ErrorResponse "Conflict - User with this email already exists".
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error".
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable".
// @Router /api/auth/register [post].
func (h *AuthHandler) StartRegistration(w http.ResponseWriter, r *http.Request) {
	var req requests.StartRegistrationRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.StartRegistration(r.Context(), req.Email)
	if err != nil {
		handleServiceError(w, err, "StartRegistration")
		return
	}

	// Map protobuf response to HTTP response struct
	responseBody := responses.StartRegistrationResponse{
		RegistrationID: resp.GetRegistrationId(),
		Success:        resp.GetSuccess(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// VerifyEmailCode обработчик для POST /api/auth/verify-email.
// @Summary Verify email code (Second stage of registration).
// @Description Verifies the email verification code sent to the user.
// @Tags auth
// @Accept json
// @Produce json
// @Param body body requests.VerifyEmailCodeRequest true "Verification details".
// @Success 200 {object} responses.VerifyEmailCodeResponse "Email code successfully verified".
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid registration ID or verification code format".
// @Failure 404 {object} responses.ErrorResponse "Not Found - Registration ID not found or expired".
// @Failure 409 {object} responses.ErrorResponse "Conflict - Registration ID or code already used".
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error".
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable".
// @Router /api/auth/verify-email [post].
func (h *AuthHandler) VerifyEmailCode(w http.ResponseWriter, r *http.Request) {
	var req requests.VerifyEmailCodeRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.VerifyEmailCode(r.Context(), req.RegistrationID, req.VerificationCode)
	if err != nil {
		handleServiceError(w, err, "VerifyEmailCode")
		return
	}

	// Map protobuf response to HTTP response struct
	responseBody := responses.VerifyEmailCodeResponse{
		Success: resp.GetSuccess(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// SetPasswordAndUsername обработчик для POST /api/auth/finish-register.
// @Summary Set password and username (Third stage of registration).
// @Description Sets the user's password and username after email verification.
// @Tags auth
// @Accept json
// @Produce json
// @Param body body requests.SetPasswordAndUsernameRequest true "Password and username details".
// @Success 200 {object} responses.SetPasswordAndUsernameResponse "Password and username successfully set".
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid format or request body".
// @Failure 404 {object} responses.ErrorResponse "Not Found - Registration ID not found or expired".
// @Failure 409 {object} responses.ErrorResponse "Conflict - User with this email or username already exists".
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error".
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable".
// @Router /api/auth/finish-register [post].
func (h *AuthHandler) SetPasswordAndUsername(w http.ResponseWriter, r *http.Request) {
	var req requests.SetPasswordAndUsernameRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.SetPasswordAndUsername(r.Context(), req.RegistrationID, req.Password, req.Username)
	if err != nil {
		handleServiceError(w, err, "SetPasswordAndUsername")
		return
	}

	// Map protobuf response to HTTP response struct
	responseBody := responses.SetPasswordAndUsernameResponse{
		AccessToken:  resp.GetAccessToken(),
		RefreshToken: resp.GetRefreshToken(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// Login обработчик для POST /api/auth/login.
// @Summary User login.
// @Description Logs in an existing user.
// @Tags auth
// @Accept json
// @Produce json
// @Param body body requests.LoginRequest true "Login credentials".
// @Success 200 {object} responses.LoginResponse "User successfully logged in".
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid email or password format".
// @Failure 401 {object} responses.ErrorResponse "Unauthorized - Invalid credentials".
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error".
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable".
// @Router /api/auth/login [post].
func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var req requests.LoginRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.Login(r.Context(), req.Email, req.Password)
	if err != nil {
		handleServiceError(w, err, "Login")
		return
	}

	// Map protobuf response to HTTP response struct
	responseBody := responses.LoginResponse{
		AccessToken:  resp.GetAccessToken(),
		RefreshToken: resp.GetRefreshToken(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// RefreshToken обработчик для POST /api/auth/refresh.
// @Summary Refresh access token.
// @Description Refreshes the access token using a refresh token.
// @Tags auth
// @Accept json
// @Produce json
// @Param body body requests.RefreshTokenRequest true "Refresh token".
// @Success 200 {object} responses.RefreshTokenResponse "Access token successfully refreshed".
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid refresh token format".
// @Failure 401 {object} responses.ErrorResponse "Unauthorized - Invalid or expired refresh token".
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error".
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable".
// @Router /api/auth/refresh [post].
func (h *AuthHandler) RefreshToken(w http.ResponseWriter, r *http.Request) {
	var req requests.RefreshTokenRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.RefreshToken(r.Context(), req.RefreshToken)
	if err != nil {
		handleServiceError(w, err, "RefreshToken")
		return
	}

	// Map protobuf response to HTTP response struct
	responseBody := responses.RefreshTokenResponse{
		AccessToken: resp.GetAccessToken(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// ForgotPassword обработчик для POST /api/auth/forgot-password.
// @Summary Request password reset.
// @Description Sends a password reset link to the user's email.
// @Tags auth
// @Accept json
// @Produce json
// @Param body body requests.ForgotPasswordRequest true "User email for password reset".
// @Success 200 {object} responses.ForgotPasswordResponse "Password reset link sent (success is true even if user not found to prevent enumeration)".
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid email format or request body".
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error".
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable".
// @Router /api/auth/forgot-password [post].
func (h *AuthHandler) ForgotPassword(w http.ResponseWriter, r *http.Request) {
	var req requests.ForgotPasswordRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.ForgotPassword(r.Context(), req.Email)
	if err != nil {
		handleServiceError(w, err, "ForgotPassword")
		return
	}

	// Map protobuf response to HTTP response struct
	responseBody := responses.ForgotPasswordResponse{
		Success: resp.GetSuccess(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// ResetPassword обработчик для POST /api/auth/reset-password.
// @Summary Reset password.
// @Description Resets the user's password using a reset token.
// @Tags auth
// @Accept json
// @Produce json
// @Param body body requests.ResetPasswordRequest true "Password reset details".
// @Success 200 {object} responses.ResetPasswordResponse "Password successfully reset".
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid password format or request body".
// @Failure 404 {object} responses.ErrorResponse "Not Found - Invalid or expired reset token".
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error".
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable".
// @Router /api/auth/reset-password [post].
func (h *AuthHandler) ResetPassword(w http.ResponseWriter, r *http.Request) {
	var req requests.ResetPasswordRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.ResetPassword(r.Context(), req.Token, req.NewPassword)
	if err != nil {
		handleServiceError(w, err, "ResetPassword")
		return
	}

	// Map protobuf response to HTTP response struct
	responseBody := responses.ResetPasswordResponse{
		Success: resp.GetSuccess(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// Logout обработчик для POST /api/users/logout.
// @Summary User logout.
// @Description Logs out a user by invalidating the refresh token.
// @Tags users
// @Accept json
// @Produce json
// @Param body body requests.LogoutRequest true "Refresh token to invalidate".
// @Success 200 {object} responses.LogoutResponse "User successfully logged out (success is true even if token not found)".
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid refresh token format or request body".
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error".
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable".
// @Security ApiKeyAuth
// @Router /api/users/logout [post].
func (h *AuthHandler) Logout(w http.ResponseWriter, r *http.Request) {
	var req requests.LogoutRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.Logout(r.Context(), req.RefreshToken)
	if err != nil {
		handleServiceError(w, err, "Logout")
		return
	}

	// Map protobuf response to HTTP response struct
	responseBody := responses.LogoutResponse{
		Success: resp.GetSuccess(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// DeleteUser обработчик для DELETE /api/users/delete-user.
// @Summary Delete user account.
// @Description Deletes a user account by email.
// @Tags users
// @Produce json
// @Success 200 {object} responses.DeleteUserResponse "User account successfully deleted".
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid email format or request body".
// @Failure 404 {object} responses.ErrorResponse "Not Found - User not found".
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error".
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable".
// @Security ApiKeyAuth
// @Router /api/users/delete-user [delete].
func (h *AuthHandler) DeleteUser(w http.ResponseWriter, r *http.Request) {
	resp, err := h.authService.DeleteUser(r.Context())
	if err != nil {
		handleServiceError(w, err, "DeleteUser")
		return
	}

	// Map protobuf response to HTTP response struct
	responseBody := responses.DeleteUserResponse{
		Success: resp.GetSuccess(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// GetUserByID обработчик для GET /api/users/{id}.
// @Summary Get user details by ID.
// @Description Retrieves details for a specific user by their ID.
// @Tags users
// @Produce json
// @Param id path int true "User ID".
// @Success 200 {object} responses.GetUserByIDResponse "User details".
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid user ID format".
// @Failure 404 {object} responses.ErrorResponse "Not Found - User not found".
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error".
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable".
// @Security ApiKeyAuth
// @Router /api/users/{id} [get].
func (h *AuthHandler) GetUserByID(w http.ResponseWriter, r *http.Request) {
	userIDStr := chi.URLParam(r, "id")
	userID, err := strconv.ParseUint(userIDStr, 10, 64)
	if err != nil || userID == 0 {
		log.Printf("AuthHandler.GetUserByID: Invalid user ID in URL: %s", userIDStr)
		respondError(w, http.StatusBadRequest, "Invalid user ID format")
		return
	}

	resp, err := h.authService.GetUserByID(r.Context(), userID)
	if err != nil {
		handleServiceError(w, err, "GetUserByID")
		return
	}

	userPB := resp.GetUser()
	if userPB == nil {
		log.Println("AuthHandler.GetUserByID: Service returned success but user is nil")
		respondError(w, http.StatusInternalServerError, "Failed to retrieve user: unexpected service response")
		return
	}

	responseBody := responses.GetUserByIDResponse{
		ID:       userPB.GetId(),
		Username: userPB.GetUsername(),
		Email:    userPB.GetEmail(),
		Image:    userPB.GetImage(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// UpdateUsername обработчик для PATCH /api/users/username.
// @Summary Update username.
// @Description Updates the username for a specific user.
// @Tags users
// @Accept json
// @Produce json
// @Param body body requests.UpdateUsernameRequest true "New username".
// @Success 200 {object} responses.UpdateUsernameResponse "Username successfully updated".
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid user ID or username format".
// @Failure 404 {object} responses.ErrorResponse "Not Found - User not found".
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error".
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable".
// @Security ApiKeyAuth
// @Router /api/users/username [patch].
func (h *AuthHandler) UpdateUsername(w http.ResponseWriter, r *http.Request) {
	var req requests.UpdateUsernameRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.UpdateUsername(r.Context(), req.NewUsername)
	if err != nil {
		handleServiceError(w, err, "UpdateUsername")
		return
	}

	responseBody := responses.UpdateUsernameResponse{
		Success: resp.GetSuccess(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// CheckPassword обработчик для POST /api/users/check-password.
// @Summary Check user password.
// @Description Checks if the provided password matches the user's password.
// @Tags users
// @Accept json
// @Produce json
// @Param body body requests.CheckPasswordRequest true "User ID and password to check".
// @Success 200 {object} responses.CheckPasswordResponse "Password check result".
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid request body".
// @Failure 403 {object} responses.ErrorResponse "Permission Denied - Incorrect password".
// @Failure 404 {object} responses.ErrorResponse "Not Found - User not found".
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error".
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable".
// @Security ApiKeyAuth
// @Router /api/users/check-password [post].
func (h *AuthHandler) CheckPassword(w http.ResponseWriter, r *http.Request) {
	var req requests.CheckPasswordRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.CheckPassword(r.Context(), req.Password)
	if err != nil {
		handleServiceError(w, err, "CheckPassword")
		return
	}

	responseBody := responses.CheckPasswordResponse{
		Success: resp.GetSuccess(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// UpdateEmail обработчик для POST /api/users/email/start-change.
// @Summary Send code to the new email.
// @Description Sends a verification code to the new email for the specific user.
// @Tags users
// @Accept json
// @Produce json
// @Param body body requests.UpdateEmailRequest true "New email and password".
// @Success 200 {object} responses.UpdateEmailResponse "Email update initiated".
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid user ID or request body".
// @Failure 404 {object} responses.ErrorResponse "Not Found - User not found".
// @Failure 409 {object} responses.ErrorResponse "Conflict - User already has this email".
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error".
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable".
// @Security ApiKeyAuth
// @Router /api/users/email/start-change [post].
func (h *AuthHandler) UpdateEmail(w http.ResponseWriter, r *http.Request) {
	var req requests.UpdateEmailRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.UpdateEmail(r.Context(), req.NewEmail)
	if err != nil {
		handleServiceError(w, err, "UpdateEmail")
		return
	}

	responseBody := responses.UpdateEmailResponse{
		Success: resp.GetSuccess(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// VerifyNewEmailCode обработчик для PATCH /api/users/email/verify-change.
// @Summary Verify new email code and change user email.
// @Description Verifies the code sent to the new email address and changes user email.
// @Tags users
// @Accept json
// @Produce json
// @Param body body requests.VerifyNewEmailCodeRequest true "New email and verification code".
// @Success 200 {object} responses.VerifyNewEmailCodeResponse "New email verified".
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid user ID or request body".
// @Failure 404 {object} responses.ErrorResponse "Not Found - User not found or invalid code".
// @Failure 409 {object} responses.ErrorResponse "Conflict - User with this email already exists".
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error".
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable".
// @Security ApiKeyAuth
// @Router /api/users/email/verify-change [patch].
func (h *AuthHandler) VerifyNewEmailCode(w http.ResponseWriter, r *http.Request) {
	var req requests.VerifyNewEmailCodeRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.VerifyNewEmailCode(r.Context(), req.VerificationCode)
	if err != nil {
		handleServiceError(w, err, "VerifyNewEmailCode")
		return
	}

	responseBody := responses.VerifyNewEmailCodeResponse{
		Success: resp.GetSuccess(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// UpdateAvatar обработчик для PATCH /api/users/avatar.
// @Summary Update user avatar.
// @Description Updates the avatar for a specific user.
// @Tags users
// @Accept multipart/form-data
// @Produce json
// @Param image formData file true "New avatar image".
// @Success 200 {object} responses.UpdateAvatarResponse "Avatar successfully updated".
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid user ID or image upload error".
// @Failure 404 {object} responses.ErrorResponse "Not Found - User not found".
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error".
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable".
// @Security ApiKeyAuth
// @Router /api/users/avatar [patch].
func (h *AuthHandler) UpdateAvatar(w http.ResponseWriter, r *http.Request) {
	// Parse the multipart form with a maximum memory of 32MB
	err := r.ParseMultipartForm(32 << 20)
	if err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid form data: %v", err))
		return
	}

	// Get the file from the form data
	file, _, err := r.FormFile("image")
	if err != nil {
		respondError(w, http.StatusBadRequest, "Image file is required")
		return
	}
	defer file.Close()

	// Read the file into a byte slice
	imageData, err := io.ReadAll(file)
	if err != nil {
		respondError(w, http.StatusInternalServerError, "Failed to read image data")
		return
	}

	resp, err := h.authService.UpdateAvatar(r.Context(), imageData)
	if err != nil {
		handleServiceError(w, err, "UpdateAvatar")
		return
	}

	responseBody := responses.UpdateAvatarResponse{
		Success: resp.GetSuccess(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// StartPasswordReset обработчик для POST /api/users/password/reset/start.
// @Summary Start password reset process.
// @Description Initiates the password reset process by sending a verification code to the user's email.
// @Tags users
// @Accept json
// @Produce json
// @Success 200 {object} responses.StartPasswordResetResponse "Password reset process initiated successfully".
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid user ID format or request body".
// @Failure 404 {object} responses.ErrorResponse "Not Found - User not found".
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error".
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable".
// @Security ApiKeyAuth
// @Router /api/users/password/reset/start [post].
func (h *AuthHandler) StartPasswordReset(w http.ResponseWriter, r *http.Request) {
	resp, err := h.authService.StartPasswordReset(r.Context())
	if err != nil {
		handleServiceError(w, err, "StartPasswordReset")
		return
	}

	responseBody := responses.StartPasswordResetResponse{
		Success: resp.GetSuccess(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// VerifyPasswordResetCode обработчик для POST /api/auth/password/reset/verify.
// @Summary Verify password reset code.
// @Description Verifies the password reset code provided by the user.
// @Tags users
// @Accept json
// @Produce json
// @Param body body requests.VerifyPasswordResetCodeRequest true "User ID and verification code".
// @Success 200 {object} responses.VerifyPasswordResetCodeResponse "Password reset code verified successfully".
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid user ID or verification code format".
// @Failure 404 {object} responses.ErrorResponse "Not Found - User not found or invalid code".
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error".
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable".
// @Security ApiKeyAuth
// @Router /api/users/password/reset/verify [post].
func (h *AuthHandler) VerifyPasswordResetCode(w http.ResponseWriter, r *http.Request) {
	var req requests.VerifyPasswordResetCodeRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.VerifyPasswordResetCode(r.Context(), req.VerificationCode)
	if err != nil {
		handleServiceError(w, err, "VerifyPasswordResetCode")
		return
	}

	responseBody := responses.VerifyPasswordResetCodeResponse{
		Success: resp.GetSuccess(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}

// SetNewPassword обработчик для PATCH /api/users/password/reset/set.
// @Summary Set new password.
// @Description Sets a new password for the user after successful code verification.
// @Tags users
// @Accept json
// @Produce json
// @Param body body requests.SetNewPasswordRequest true "User ID and new password".
// @Success 200 {object} responses.SetNewPasswordResponse "New password set successfully".
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid user ID or new password format".
// @Failure 404 {object} responses.ErrorResponse "Not Found - User not found or password reset process not initiated".
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error".
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable".
// @Security ApiKeyAuth
// @Router /api/users/password/reset/set [patch].
func (h *AuthHandler) SetNewPassword(w http.ResponseWriter, r *http.Request) {
	var req requests.SetNewPasswordRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.SetNewPassword(r.Context(), req.NewPassword)
	if err != nil {
		handleServiceError(w, err, "SetNewPassword")
		return
	}

	responseBody := responses.SetNewPasswordResponse{
		Success: resp.GetSuccess(),
	}

	respondJSON(w, http.StatusOK, responseBody)
}
