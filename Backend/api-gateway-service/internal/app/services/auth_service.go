package services

import (
	"context"

	auth "Rewind-api-gateway-service/clients/auth"
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
	UpdateUsername(ctx context.Context, newUsername string) (*pb.UpdateUsernameResponse, error)
	CheckPassword(ctx context.Context, password string) (*pb.CheckPasswordResponse, error)
	UpdateEmail(ctx context.Context, newEmail, password string) (*pb.UpdateEmailResponse, error)
	VerifyNewEmailCode(ctx context.Context, newEmail, verificationCode string) (*pb.VerifyNewEmailCodeResponse, error)
	UpdateAvatar(ctx context.Context, imageData []byte) (*pb.UpdateAvatarResponse, error)
	StartPasswordReset(ctx context.Context) (*pb.StartPasswordResetResponse, error)
	VerifyPasswordResetCode(ctx context.Context, verificationCode string) (*pb.VerifyPasswordResetCodeResponse, error)
	SetNewPassword(ctx context.Context, newPassword string) (*pb.SetNewPasswordResponse, error)
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

// UpdateUsername вызывает метод UpdateUsername сервиса аутентификации.
func (s *AuthService) UpdateUsername(ctx context.Context, newUsername string) (*pb.UpdateUsernameResponse, error) {
	userID, err := GetRequestingUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}
	return s.authClient.UpdateUsername(ctx, &pb.UpdateUsernameRequest{UserId: userID, NewUsername: newUsername})
}

// CheckPassword вызывает метод CheckPassword сервиса аутентификации.
func (s *AuthService) CheckPassword(ctx context.Context, password string) (*pb.CheckPasswordResponse, error) {
	userID, err := GetRequestingUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}
	return s.authClient.CheckPassword(ctx, &pb.CheckPasswordRequest{UserId: userID, Password: password})
}

// UpdateEmail вызывает метод UpdateEmail сервиса аутентификации.
func (s *AuthService) UpdateEmail(ctx context.Context, newEmail, password string) (*pb.UpdateEmailResponse, error) {
	userID, err := GetRequestingUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}
	return s.authClient.UpdateEmail(ctx, &pb.UpdateEmailRequest{UserId: userID, NewEmail: newEmail, Password: password})
}

// VerifyNewEmailCode вызывает метод VerifyNewEmailCode сервиса аутентификации.
func (s *AuthService) VerifyNewEmailCode(ctx context.Context, newEmail, verificationCode string) (*pb.VerifyNewEmailCodeResponse, error) {
	userID, err := GetRequestingUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}
	return s.authClient.VerifyNewEmailCode(ctx, &pb.VerifyNewEmailCodeRequest{UserId: userID, NewEmail: newEmail, VerificationCode: verificationCode})
}

// UpdateAvatar вызывает метод UpdateAvatar сервиса аутентификации.
func (s *AuthService) UpdateAvatar(ctx context.Context, imageData []byte) (*pb.UpdateAvatarResponse, error) {
	userID, err := GetRequestingUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}
	return s.authClient.UpdateAvatar(ctx, &pb.UpdateAvatarRequest{UserId: userID, Image: imageData})
}

// StartPasswordReset вызывает метод StartPasswordReset сервиса аутентификации.
func (s *AuthService) StartPasswordReset(ctx context.Context) (*pb.StartPasswordResetResponse, error) {
	userID, err := GetRequestingUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}
	return s.authClient.StartPasswordReset(ctx, &pb.StartPasswordResetRequest{UserId: userID})
}

// VerifyPasswordResetCode вызывает метод VerifyPasswordResetCode сервиса аутентификации.
func (s *AuthService) VerifyPasswordResetCode(ctx context.Context, verificationCode string) (*pb.VerifyPasswordResetCodeResponse, error) {
	userID, err := GetRequestingUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}
	return s.authClient.VerifyPasswordResetCode(ctx, &pb.VerifyPasswordResetCodeRequest{UserId: userID, VerificationCode: verificationCode})
}

// SetNewPassword вызывает метод SetNewPassword сервиса аутентификации.
func (s *AuthService) SetNewPassword(ctx context.Context, newPassword string) (*pb.SetNewPasswordResponse, error) {
	userID, err := GetRequestingUserIDFromContext(ctx)
	if err != nil {
		return nil, err
	}
	return s.authClient.SetNewPassword(ctx, &pb.SetNewPasswordRequest{UserId: userID, NewPassword: newPassword})
}
