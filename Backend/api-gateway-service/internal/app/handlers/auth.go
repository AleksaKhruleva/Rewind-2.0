package handlers

import (
	"encoding/json"
	"fmt"
	"io"
	"net/http"

	"Rewind-api-gateway-service/internal/app/requests"
	"Rewind-api-gateway-service/internal/app/services"
)

// AuthHandler структура для обработчиков аутентификации
type AuthHandler struct {
	authService services.AuthServiceInterface // Изменен тип на интерфейс
}

// NewAuthHandler создает новый обработчик аутентификации
func NewAuthHandler(authService services.AuthServiceInterface) *AuthHandler {
	return &AuthHandler{authService: authService}
}

// StartRegistration обработчик для POST /api/auth/register
// @Summary Start user registration (First stage of registration)
// @Description Initiates the user registration process by sending a verification email.
// @Tags auth
// @Accept json
// @Produce json
// @Param body body requests.StartRegistrationRequest true "User email for registration"
// @Success 200 {object} responses.StartRegistrationResponse
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/auth/register [post]
func (h *AuthHandler) StartRegistration(w http.ResponseWriter, r *http.Request) {
	var req requests.StartRegistrationRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.StartRegistration(r.Context(), req.Email)
	if err != nil {
		respondError(w, http.StatusInternalServerError, fmt.Sprintf("Auth service error: %v", err))
		return
	}

	respondJSON(w, http.StatusOK, resp)
}

// VerifyEmailCode обработчик для POST /api/auth/verify-email
// @Summary Verify email code (Second stage of registration)
// @Description Verifies the email verification code sent to the user.
// @Tags auth
// @Accept json
// @Produce json
// @Param body body requests.VerifyEmailCodeRequest true "Verification details"
// @Success 200 {object} responses.VerifyEmailCodeResponse
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/auth/verify-email [post]
func (h *AuthHandler) VerifyEmailCode(w http.ResponseWriter, r *http.Request) {
	var req requests.VerifyEmailCodeRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.VerifyEmailCode(r.Context(), req.RegistrationID, req.VerificationCode)
	if err != nil {
		respondError(w, http.StatusInternalServerError, fmt.Sprintf("Auth service error: %v", err))
		return
	}

	respondJSON(w, http.StatusOK, resp)
}

// SetPasswordAndUsername обработчик для POST /api/auth/set-password
// @Summary Set password and username (Third stage of registration)
// @Description Sets the user's password and username after email verification.
// @Tags auth
// @Accept json
// @Produce json
// @Param body body requests.SetPasswordAndUsernameRequest true "Password and username details"
// @Success 200 {object} responses.SetPasswordAndUsernameResponse
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/auth/set-password [post]
func (h *AuthHandler) SetPasswordAndUsername(w http.ResponseWriter, r *http.Request) {
	var req requests.SetPasswordAndUsernameRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.SetPasswordAndUsername(r.Context(), req.RegistrationID, req.Password, req.Username)
	if err != nil {
		respondError(w, http.StatusInternalServerError, fmt.Sprintf("Auth service error: %v", err))
		return
	}

	respondJSON(w, http.StatusOK, resp)
}

// Login обработчик для POST /api/auth/login
// @Summary User login
// @Description Logs in an existing user.
// @Tags auth
// @Accept json
// @Produce json
// @Param body body requests.LoginRequest true "Login credentials"
// @Success 200 {object} responses.LoginResponse
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/auth/login [post]
func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var req requests.LoginRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.Login(r.Context(), req.Identifier, req.Password)
	if err != nil {
		respondError(w, http.StatusInternalServerError, fmt.Sprintf("Auth service error: %v", err))
		return
	}

	respondJSON(w, http.StatusOK, resp)
}

// RefreshToken обработчик для POST /api/auth/refresh
// @Summary Refresh access token
// @Description Refreshes the access token using a refresh token.
// @Tags auth
// @Accept json
// @Produce json
// @Param body body requests.RefreshTokenRequest true "Refresh token"
// @Success 200 {object} responses.RefreshTokenResponse
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/auth/refresh [post]
func (h *AuthHandler) RefreshToken(w http.ResponseWriter, r *http.Request) {
	var req requests.RefreshTokenRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.RefreshToken(r.Context(), req.RefreshToken)
	if err != nil {
		respondError(w, http.StatusInternalServerError, fmt.Sprintf("Auth service error: %v", err))
		return
	}

	respondJSON(w, http.StatusOK, resp)
}

// ForgotPassword обработчик для POST /api/auth/forgot-password
// @Summary Request password reset
// @Description Sends a password reset link to the user's email.
// @Tags auth
// @Accept json
// @Produce json
// @Param body body requests.ForgotPasswordRequest true "User email for password reset"
// @Success 200 {object} responses.ForgotPasswordResponse
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/auth/forgot-password [post]
func (h *AuthHandler) ForgotPassword(w http.ResponseWriter, r *http.Request) {
	var req requests.ForgotPasswordRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.ForgotPassword(r.Context(), req.Email)
	if err != nil {
		respondError(w, http.StatusInternalServerError, fmt.Sprintf("Auth service error: %v", err))
		return
	}

	respondJSON(w, http.StatusOK, resp)
}

// ResetPassword обработчик для POST /api/auth/reset-password
// @Summary Reset password
// @Description Resets the user's password using a reset token.
// @Tags auth
// @Accept json
// @Produce json
// @Param body body requests.ResetPasswordRequest true "Password reset details"
// @Success 200 {object} responses.ResetPasswordResponse
// @Failure 400 {object} map[string]string
// @Failure 500 {object} map[string]string
// @Router /api/auth/reset-password [post]
func (h *AuthHandler) ResetPassword(w http.ResponseWriter, r *http.Request) {
	var req requests.ResetPasswordRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.ResetPassword(r.Context(), req.Token, req.NewPassword)
	if err != nil {
		respondError(w, http.StatusInternalServerError, fmt.Sprintf("Auth service error: %v", err))
		return
	}

	respondJSON(w, http.StatusOK, resp)
}

// Logout обработчик для POST /api/auth/logout
// @Summary User logout
// @Description Logs out a user by invalidating the refresh token.
// @Tags auth
// @Accept json
// @Produce json
// @Param body body requests.LogoutRequest true "Refresh token to invalidate"
// @Success 200 {object} responses.LogoutResponse
// @Failure 400 {object} map[string]string
// @Router /api/auth/logout [post]
func (h *AuthHandler) Logout(w http.ResponseWriter, r *http.Request) {
	var req requests.LogoutRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.Logout(r.Context(), req.RefreshToken)
	if err != nil {
		respondError(w, http.StatusInternalServerError, fmt.Sprintf("Auth service error: %v", err))
		return
	}

	respondJSON(w, http.StatusOK, resp)
}

// Вспомогательные функции (decodeJSONBody, respondJSON, respondError) остаются без изменений

// Вспомогательные функции

func decodeJSONBody(r *http.Request, dst interface{}) error {
	if r.Header.Get("Content-Type") != "application/json" {
		return fmt.Errorf("content type must be application/json")
	}

	body, err := io.ReadAll(r.Body)
	if err != nil {
		return err
	}
	defer r.Body.Close()

	err = json.Unmarshal(body, dst)
	if err != nil {
		return err
	}

	return nil
}

func respondJSON(w http.ResponseWriter, status int, payload interface{}) {
	response, err := json.Marshal(payload)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(err.Error()))
		return
	}
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	w.Write(response)
}

func respondError(w http.ResponseWriter, status int, message string) {
	respondJSON(w, status, map[string]string{"error": message})
}
