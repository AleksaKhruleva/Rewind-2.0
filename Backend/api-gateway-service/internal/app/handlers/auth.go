package handlers

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"Rewind-api-gateway-service/internal/app/requests"
	"Rewind-api-gateway-service/internal/app/responses"
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
// @Success 200 {object} responses.StartRegistrationResponse "Successfully initiated registration"
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid email format or request body"
// @Failure 409 {object} responses.ErrorResponse "Conflict - User with this email already exists"
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error"
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable"
// @Router /api/auth/register [post]
func (h *AuthHandler) StartRegistration(w http.ResponseWriter, r *http.Request) {
	var req requests.StartRegistrationRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.StartRegistration(r.Context(), req.Email)
	if err != nil {
		st, ok := status.FromError(err)
		if ok {
			switch st.Code() {
			case codes.InvalidArgument:
				respondError(w, http.StatusBadRequest, st.Message())
				return
			case codes.AlreadyExists:
				respondError(w, http.StatusConflict, st.Message())
				return
			case codes.Internal:
				log.Printf("Auth-Service internal error during StartRegistration: %v", st.Message())
				respondError(w, http.StatusInternalServerError, "Internal Server Error.")
				return
			case codes.Unavailable:
				log.Printf("Auth-Service unavailable during StartRegistration: %v", st.Message())
				respondError(w, http.StatusServiceUnavailable, "Auth-Service is unavailable.")
				return
			default:
				log.Printf("Unknown gRPC error from Auth-Service during StartRegistration (code %s): %v", st.Code().String(), st.Message())
				respondError(w, http.StatusInternalServerError, "Unknown Error during Auth-Service StartRegistration call.")
				return
			}
		} else {
			log.Printf("Non-gRPC error during Auth-Service StartRegistration call: %v", err)
			respondError(w, http.StatusInternalServerError, "Internal Server Error.")
		}
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
// @Success 200 {object} responses.VerifyEmailCodeResponse "Email code successfully verified"
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid registration ID or verification code format"
// @Failure 404 {object} responses.ErrorResponse "Not Found - Registration ID not found or expired"
// @Failure 409 {object} responses.ErrorResponse "Conflict - Registration ID or code already used"
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error"
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable"
// @Router /api/auth/verify-email [post]
func (h *AuthHandler) VerifyEmailCode(w http.ResponseWriter, r *http.Request) {
	var req requests.VerifyEmailCodeRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.VerifyEmailCode(r.Context(), req.RegistrationID, req.VerificationCode)
	if err != nil {
		st, ok := status.FromError(err)
		if ok {
			switch st.Code() {
			case codes.InvalidArgument:
				respondError(w, http.StatusBadRequest, st.Message())
				return
			case codes.NotFound:
				respondError(w, http.StatusNotFound, st.Message())
				return
			case codes.AlreadyExists:
				respondError(w, http.StatusConflict, st.Message())
				return
			case codes.Internal:
				log.Printf("Auth-Service internal error during VerifyEmailCode: %v", st.Message())
				respondError(w, http.StatusInternalServerError, "Internal Server Error.")
				return
			case codes.Unavailable:
				log.Printf("Auth-Service unavailable during VerifyEmailCode: %v", st.Message())
				respondError(w, http.StatusServiceUnavailable, "Auth-Service is unavailable.")
				return
			default:
				log.Printf("Unknown gRPC error from Auth-Service during VerifyEmailCode (code %s): %v", st.Code().String(), st.Message())
				respondError(w, http.StatusInternalServerError, "Unknown Error during Auth-Service VerifyEmailCode call.")
				return
			}
		}

		log.Printf("Non-gRPC error during Auth-Service VerifyEmailCode call: %v", err)
		respondError(w, http.StatusInternalServerError, "Internal Server Error.")
		return
	}
	respondJSON(w, http.StatusOK, resp)
}

// SetPasswordAndUsername обработчик для POST /api/auth/finish-register
// @Summary Set password and username (Third stage of registration)
// @Description Sets the user's password and username after email verification.
// @Tags auth
// @Accept json
// @Produce json
// @Param body body requests.SetPasswordAndUsernameRequest true "Password and username details"
// @Success 200 {object} responses.SetPasswordAndUsernameResponse "Password and username successfully set"
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid format or request body"
// @Failure 404 {object} responses.ErrorResponse "Not Found - Registration ID not found or expired"
// @Failure 409 {object} responses.ErrorResponse "Conflict - User with this email or username already exists"
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error"
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable"
// @Router /api/auth/finish-register [post]
func (h *AuthHandler) SetPasswordAndUsername(w http.ResponseWriter, r *http.Request) {
	var req requests.SetPasswordAndUsernameRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.SetPasswordAndUsername(r.Context(), req.RegistrationID, req.Password, req.Username)
	if err != nil {
		st, ok := status.FromError(err)
		if ok {
			switch st.Code() {
			case codes.InvalidArgument:
				respondError(w, http.StatusBadRequest, st.Message())
				return
			case codes.NotFound:
				respondError(w, http.StatusNotFound, st.Message())
				return
			case codes.AlreadyExists:
				respondError(w, http.StatusConflict, st.Message())
				return
			case codes.Internal:
				log.Printf("Auth-Service internal error during SetPasswordAndUsername: %v", st.Message())
				respondError(w, http.StatusInternalServerError, "Internal Server Error.")
				return
			case codes.Unavailable:
				log.Printf("Auth-Service unavailable during SetPasswordAndUsername: %v", st.Message())
				respondError(w, http.StatusServiceUnavailable, "Auth-Service is unavailable.")
				return
			default:
				log.Printf("Unknown gRPC error from Auth-Service during SetPasswordAndUsername (code %s): %v", st.Code().String(), st.Message())
				respondError(w, http.StatusInternalServerError, "Unknown Error during Auth-Service SetPasswordAndUsername call.")
				return
			}
		}

		log.Printf("Non-gRPC error during Auth-Service SetPasswordAndUsername call: %v", err)
		respondError(w, http.StatusInternalServerError, "Internal Server Error.")
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
// @Success 200 {object} responses.LoginResponse "User successfully logged in"
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid email or password format"
// @Failure 401 {object} responses.ErrorResponse "Unauthorized - Invalid credentials"
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error"
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable"
// @Router /api/auth/login [post]
func (h *AuthHandler) Login(w http.ResponseWriter, r *http.Request) {
	var req requests.LoginRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.Login(r.Context(), req.Email, req.Password)
	if err != nil {
		st, ok := status.FromError(err)
		if ok {
			switch st.Code() {
			case codes.InvalidArgument:
				respondError(w, http.StatusBadRequest, st.Message())
				return
			case codes.Unauthenticated:
				respondError(w, http.StatusUnauthorized, st.Message())
				return
			case codes.Internal:
				log.Printf("Auth-Service internal error during Login: %v", st.Message())
				respondError(w, http.StatusInternalServerError, "Internal Server Error.")
				return
			case codes.Unavailable:
				log.Printf("Auth-Service unavailable during Login: %v", st.Message())
				respondError(w, http.StatusServiceUnavailable, "Auth-Service is unavailable.")
				return
			default:
				log.Printf("Unknown gRPC error from Auth-Service during Login (code %s): %v", st.Code().String(), st.Message())
				respondError(w, http.StatusInternalServerError, "Unknown error from Auth-Service.")
				return
			}
		}

		log.Printf("Non-gRPC error during Auth-Service Login call: %v", err)
		respondError(w, http.StatusInternalServerError, "Internal Server Error.")
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
// @Success 200 {object} responses.RefreshTokenResponse "Access token successfully refreshed"
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid refresh token format"
// @Failure 401 {object} responses.ErrorResponse "Unauthorized - Invalid or expired refresh token"
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error"
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable"
// @Router /api/auth/refresh [post]
func (h *AuthHandler) RefreshToken(w http.ResponseWriter, r *http.Request) {
	var req requests.RefreshTokenRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.RefreshToken(r.Context(), req.RefreshToken)
	if err != nil {
		st, ok := status.FromError(err)
		if ok {
			switch st.Code() {
			case codes.InvalidArgument:
				respondError(w, http.StatusBadRequest, st.Message())
				return
			case codes.Unauthenticated:
				respondError(w, http.StatusUnauthorized, st.Message())
				return
			case codes.Internal:
				log.Printf("Auth-Service internal error during RefreshToken: %v", st.Message())
				respondError(w, http.StatusInternalServerError, "Internal Server Error.")
				return
			case codes.Unavailable:
				log.Printf("Auth-Service unavailable during RefreshToken: %v", st.Message())
				respondError(w, http.StatusServiceUnavailable, "Auth-Service is unavailable.")
				return
			default:
				log.Printf("Unknown gRPC error from Auth-Service during RefreshToken (code %s): %v", st.Code().String(), st.Message())
				respondError(w, http.StatusInternalServerError, "Unknown error from Auth-Service.")
				return
			}
		}

		log.Printf("Non-gRPC error during Auth-Service RefreshToken call: %v", err)
		respondError(w, http.StatusInternalServerError, "Internal Server Error.")
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
// @Success 200 {object} responses.ForgotPasswordResponse "Password reset link sent (success is true even if user not found to prevent enumeration)"
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid email format or request body"
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error"
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable"
// @Router /api/auth/forgot-password [post]
func (h *AuthHandler) ForgotPassword(w http.ResponseWriter, r *http.Request) {
	var req requests.ForgotPasswordRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.ForgotPassword(r.Context(), req.Email)
	if err != nil {
		st, ok := status.FromError(err)
		if ok {
			switch st.Code() {
			case codes.InvalidArgument:
				respondError(w, http.StatusBadRequest, st.Message())
				return
			case codes.Internal:
				log.Printf("Auth-Service internal error during ForgotPassword: %v", st.Message())
				respondError(w, http.StatusInternalServerError, "Internal Server Error.")
				return
			case codes.Unavailable:
				log.Printf("Auth-Service unavailable during ForgotPassword: %v", st.Message())
				respondError(w, http.StatusServiceUnavailable, "Auth-Service is unavailable.")
				return
			default:
				log.Printf("Unknown gRPC error from Auth-Service during ForgotPassword (code %s): %v", st.Code().String(), st.Message())
				respondError(w, http.StatusInternalServerError, "Unknown error from Auth-Service.")
				return
			}
		}

		log.Printf("Non-gRPC error during Auth-Service ForgotPassword call: %v", err)
		respondError(w, http.StatusInternalServerError, "Internal Server Error.")
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
// @Success 200 {object} responses.ResetPasswordResponse "Password successfully reset"
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid password format or request body"
// @Failure 404 {object} responses.ErrorResponse "Not Found - Invalid or expired reset token"
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error"
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable"
// @Router /api/auth/reset-password [post]
func (h *AuthHandler) ResetPassword(w http.ResponseWriter, r *http.Request) {
	var req requests.ResetPasswordRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.ResetPassword(r.Context(), req.Token, req.NewPassword)
	if err != nil {
		st, ok := status.FromError(err)
		if ok {
			switch st.Code() {
			case codes.InvalidArgument:
				respondError(w, http.StatusBadRequest, st.Message())
				return
			case codes.NotFound:
				respondError(w, http.StatusNotFound, st.Message())
				return
			case codes.Internal:
				log.Printf("Auth-Service internal error during ResetPassword: %v", st.Message())
				respondError(w, http.StatusInternalServerError, "Internal Server Error.")
				return
			case codes.Unavailable:
				log.Printf("Auth-Service unavailable during ResetPassword: %v", st.Message())
				respondError(w, http.StatusServiceUnavailable, "Auth-Service is unavailable.")
				return
			default:
				log.Printf("Unknown gRPC error from Auth-Service during ResetPassword (code %s): %v", st.Code().String(), st.Message())
				respondError(w, http.StatusInternalServerError, "Unknown error from Auth-Service.")
				return
			}
		}

		log.Printf("Non-gRPC error during Auth-Service ResetPassword call: %v", err)
		respondError(w, http.StatusInternalServerError, "Internal Server Error.")
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
// @Success 200 {object} responses.LogoutResponse "User successfully logged out (success is true even if token not found)"
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid refresh token format or request body"
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error"
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable"
// @Router /api/auth/logout [post]
func (h *AuthHandler) Logout(w http.ResponseWriter, r *http.Request) {
	var req requests.LogoutRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.Logout(r.Context(), req.RefreshToken)
	if err != nil {
		st, ok := status.FromError(err)
		if ok {
			switch st.Code() {
			case codes.InvalidArgument:
				respondError(w, http.StatusBadRequest, st.Message())
				return
			case codes.Internal:
				log.Printf("Auth-Service internal error during Logout: %v", st.Message())
				respondError(w, http.StatusInternalServerError, "Internal Server Error.")
				return
			case codes.Unavailable:
				log.Printf("Auth-Service unavailable during Logout: %v", st.Message())
				respondError(w, http.StatusServiceUnavailable, "Auth-Service is unavailable.")
				return
			default:
				log.Printf("Unknown gRPC error from Auth-Service during Logout (code %s): %v", st.Code().String(), st.Message())
				respondError(w, http.StatusInternalServerError, "Unknown error from Auth-Service.")
				return
			}
		}

		log.Printf("Non-gRPC error during Auth-Service Logout call: %v", err)
		respondError(w, http.StatusInternalServerError, "Internal Server Error.")
		return
	}

	respondJSON(w, http.StatusOK, resp)
}

// DeleteUser обработчик для POST /api/auth/delete-user
// @Summary Delete user account
// @Description Deletes a user account by email.
// @Tags auth
// @Accept json
// @Produce json
// @Param body body requests.DeleteUserRequest true "User email to delete"
// @Success 200 {object} responses.DeleteUserResponse "User account successfully deleted"
// @Failure 400 {object} responses.ErrorResponse "Bad Request - Invalid email format or request body"
// @Failure 404 {object} responses.ErrorResponse "Not Found - User not found"
// @Failure 500 {object} responses.ErrorResponse "Internal Server Error"
// @Failure 503 {object} responses.ErrorResponse "Service Unavailable"
// @Router /api/auth/delete-user [post]
func (h *AuthHandler) DeleteUser(w http.ResponseWriter, r *http.Request) {
	var req requests.DeleteUserRequest
	if err := decodeJSONBody(r, &req); err != nil {
		respondError(w, http.StatusBadRequest, fmt.Sprintf("Invalid request body: %v", err))
		return
	}

	resp, err := h.authService.DeleteUser(r.Context(), req.Email)
	if err != nil {
		st, ok := status.FromError(err)
		if ok {
			switch st.Code() {
			case codes.InvalidArgument:
				respondError(w, http.StatusBadRequest, st.Message())
				return
			case codes.NotFound:
				respondError(w, http.StatusNotFound, st.Message())
				return
			case codes.Internal:
				log.Printf("Auth-Service internal error during DeleteUser: %v", st.Message())
				respondError(w, http.StatusInternalServerError, "Internal Server Error.")
				return
			case codes.Unavailable:
				log.Printf("Auth-Service unavailable during DeleteUser: %v", st.Message())
				respondError(w, http.StatusServiceUnavailable, "Auth-Service is unavailable.")
				return
			default:
				log.Printf("Unknown gRPC error from Auth-Service during DeleteUser (code %s): %v", st.Code().String(), st.Message())
				respondError(w, http.StatusInternalServerError, "Unknown error from Auth-Service.")
				return
			}
		}

		log.Printf("Non-gRPC error during Auth-Service DeleteUser call: %v", err)
		respondError(w, http.StatusInternalServerError, "Internal Server Error.")
		return
	}

	respondJSON(w, http.StatusOK, resp)
}

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
	w.Header().Set("Content-Type", "application/json")
	response, err := json.Marshal(payload)
	if err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		w.Write([]byte(`{"error":"Internal server error marshaling JSON"}`))
		return
	}
	w.WriteHeader(status)
	w.Write(response)
}

func respondError(w http.ResponseWriter, status int, message string) {
	respondJSON(w, status, responses.ErrorResponse{Error: message})
}
