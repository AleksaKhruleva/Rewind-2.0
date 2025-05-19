package services

import (
	"context"

	"Rewind-api-gateway-service/clients/auth"
	pb "Rewind-api-gateway-service/pkg/proto"
)

// AuthServiceInterface определяет методы сервиса аутентификации.
type AuthServiceInterface interface {
	StartRegistration(ctx context.Context, email string) (*pb.StartRegistrationResponse, error)
	VerifyEmailCode(ctx context.Context, registrationID, verificationCode string) (*pb.VerifyEmailCodeResponse, error)
	SetPasswordAndUsername(ctx context.Context, registrationID, password, username string) (*pb.SetPasswordAndUsernameResponse, error)
	Login(ctx context.Context, email, password string) (*pb.LoginResponse, error)
	RefreshToken(ctx context.Context, refreshToken string) (*pb.RefreshTokenResponse, error)
	ForgotPassword(ctx context.Context, email string) (*pb.ForgotPasswordResponse, error)
	ResetPassword(ctx context.Context, token, newPassword string) (*pb.ResetPasswordResponse, error)
	Logout(ctx context.Context, refreshToken string) (*pb.LogoutResponse, error)
	DeleteUser(ctx context.Context, email string) (*pb.DeleteUserResponse, error)
	GetUserByID(ctx context.Context, userID uint64) (*pb.GetUserByIDResponse, error)
}

// AuthService представляет сервис для аутентификации.
type AuthService struct {
	authClient *auth.AuthServiceClient
}

// NewAuthService создает новый сервис аутентификации.
func NewAuthService(authClient *auth.AuthServiceClient) *AuthService {
	return &AuthService{authClient: authClient}
}

// StartRegistration вызывает метод StartRegistration сервиса аутентификации.
func (s *AuthService) StartRegistration(ctx context.Context, email string) (*pb.StartRegistrationResponse, error) {
	return s.authClient.StartRegistration(ctx, &pb.StartRegistrationRequest{Email: email})
}

// VerifyEmailCode вызывает метод VerifyEmailCode сервиса аутентификации.
func (s *AuthService) VerifyEmailCode(ctx context.Context, registrationID, verificationCode string) (*pb.VerifyEmailCodeResponse, error) {
	return s.authClient.VerifyEmailCode(ctx, &pb.VerifyEmailCodeRequest{RegistrationId: registrationID, VerificationCode: verificationCode})
}

// SetPasswordAndUsername вызывает метод SetPasswordAndUsername сервиса аутентификации.
func (s *AuthService) SetPasswordAndUsername(ctx context.Context, registrationID, password, username string) (*pb.SetPasswordAndUsernameResponse, error) {
	return s.authClient.SetPasswordAndUsername(ctx, &pb.SetPasswordAndUsernameRequest{RegistrationId: registrationID, Password: password, Username: username})
}

// Login вызывает метод Login сервиса аутентификации.
func (s *AuthService) Login(ctx context.Context, email, password string) (*pb.LoginResponse, error) {
	return s.authClient.Login(ctx, &pb.LoginRequest{Email: email, Password: password})
}

// RefreshToken вызывает метод RefreshToken сервиса аутентификации.
func (s *AuthService) RefreshToken(ctx context.Context, refreshToken string) (*pb.RefreshTokenResponse, error) {
	return s.authClient.RefreshToken(ctx, &pb.RefreshTokenRequest{RefreshToken: refreshToken})
}

// ForgotPassword вызывает метод ForgotPassword сервиса аутентификации.
func (s *AuthService) ForgotPassword(ctx context.Context, email string) (*pb.ForgotPasswordResponse, error) {
	return s.authClient.ForgotPassword(ctx, &pb.ForgotPasswordRequest{Email: email})
}

// ResetPassword вызывает метод ResetPassword сервиса аутентификации.
func (s *AuthService) ResetPassword(ctx context.Context, token, newPassword string) (*pb.ResetPasswordResponse, error) {
	return s.authClient.ResetPassword(ctx, &pb.ResetPasswordRequest{Token: token, NewPassword: newPassword})
}

// Logout вызывает метод Logout сервиса аутентификации.
func (s *AuthService) Logout(ctx context.Context, refreshToken string) (*pb.LogoutResponse, error) {
	return s.authClient.Logout(ctx, &pb.LogoutRequest{RefreshToken: refreshToken})
}

func (s *AuthService) DeleteUser(ctx context.Context, email string) (*pb.DeleteUserResponse, error) {
	return s.authClient.DeleteUser(ctx, &pb.DeleteUserRequest{Email: email})
}

func (s *AuthService) GetUserByID(ctx context.Context, userID uint64) (*pb.GetUserByIDResponse, error) {
	return s.authClient.GetUserByID(ctx, &pb.GetUserByIDRequest{UserId: userID})
}
