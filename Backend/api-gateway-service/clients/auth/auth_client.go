package clients

import (
	"context"
	"fmt"
	"log"
	"os"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"

	pb "Rewind-api-gateway-service/pkg/proto"
)

// AuthServiceClient представляет собой gRPC-клиент для сервиса аутентификации.
type AuthServiceClient struct {
	client pb.AuthServiceClient
	conn   *grpc.ClientConn
}

// NewAuthServiceClient создает новый клиент сервиса аутентификации.
func NewAuthServiceClient() (*AuthServiceClient, error) {
	authServiceAddress := os.Getenv("AUTH_SERVICE_GRPC_ADDRESS")
	if authServiceAddress == "" {
		authServiceAddress = "localhost:50051" // Значение по умолчанию
		log.Println("Warning: AUTH_SERVICE_GRPC_ADDRESS environment variable not set, using default.")
	}

	conn, err := grpc.NewClient(authServiceAddress, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		return nil, fmt.Errorf("failed to connect to auth-service: %w", err)
	}

	client := pb.NewAuthServiceClient(conn)

	return &AuthServiceClient{
		client: client,
		conn:   conn,
	}, nil
}

// Close закрывает gRPC соединение.
func (c *AuthServiceClient) Close() error {
	return c.conn.Close()
}

// StartRegistration вызывает метод StartRegistration сервиса аутентификации.
func (c *AuthServiceClient) StartRegistration(ctx context.Context, req *pb.StartRegistrationRequest) (*pb.StartRegistrationResponse, error) {
	return c.client.StartRegistration(ctx, req)
}

// VerifyEmailCode вызывает метод VerifyEmailCode сервиса аутентификации.
func (c *AuthServiceClient) VerifyEmailCode(ctx context.Context, req *pb.VerifyEmailCodeRequest) (*pb.VerifyEmailCodeResponse, error) {
	return c.client.VerifyEmailCode(ctx, req)
}

// SetPasswordAndUsername вызывает метод SetPasswordAndUsername сервиса аутентификации.
func (c *AuthServiceClient) SetPasswordAndUsername(ctx context.Context, req *pb.SetPasswordAndUsernameRequest) (*pb.SetPasswordAndUsernameResponse, error) {
	return c.client.SetPasswordAndUsername(ctx, req)
}

// Login вызывает метод Login сервиса аутентификации.
func (c *AuthServiceClient) Login(ctx context.Context, req *pb.LoginRequest) (*pb.LoginResponse, error) {
	return c.client.Login(ctx, req)
}

// RefreshToken вызывает метод RefreshToken сервиса аутентификации.
func (c *AuthServiceClient) RefreshToken(ctx context.Context, req *pb.RefreshTokenRequest) (*pb.RefreshTokenResponse, error) {
	return c.client.RefreshToken(ctx, req)
}

// ForgotPassword вызывает метод ForgotPassword сервиса аутентификации.
func (c *AuthServiceClient) ForgotPassword(ctx context.Context, req *pb.ForgotPasswordRequest) (*pb.ForgotPasswordResponse, error) {
	return c.client.ForgotPassword(ctx, req)
}

// ResetPassword вызывает метод ResetPassword сервиса аутентификации.
func (c *AuthServiceClient) ResetPassword(ctx context.Context, req *pb.ResetPasswordRequest) (*pb.ResetPasswordResponse, error) {
	return c.client.ResetPassword(ctx, req)
}

// Logout вызывает метод Logout сервиса аутентификации.
func (c *AuthServiceClient) Logout(ctx context.Context, req *pb.LogoutRequest) (*pb.LogoutResponse, error) {
	return c.client.Logout(ctx, req)
}

// DeleteUser вызывает метод DeleteUser сервиса аутентификации.
func (c *AuthServiceClient) DeleteUser(ctx context.Context, req *pb.DeleteUserRequest) (*pb.DeleteUserResponse, error) {
	return c.client.DeleteUser(ctx, req)
}

// GetUsersByIDs вызывает метода GetUsersByIDs сервиса аутентификации
func (c *AuthServiceClient) GetUsersByIDs(ctx context.Context, req *pb.GetUsersByIDsRequest) (*pb.GetUsersByIDsResponse, error) {
	return c.client.GetUsersByIDs(ctx, req)
}

// GetUserByID вызывает метода GetUserByID сервиса аутентификации
func (c *AuthServiceClient) GetUserByID(ctx context.Context, req *pb.GetUserByIDRequest) (*pb.GetUserByIDResponse, error) {
	return c.client.GetUserByID(ctx, req)
}

// UpdateUsername вызывает метод UpdateUsername сервиса аутентификации
func (c *AuthServiceClient) UpdateUsername(ctx context.Context, req *pb.UpdateUsernameRequest) (*pb.UpdateUsernameResponse, error) {
	return c.client.UpdateUsername(ctx, req)
}

// CheckPassword вызывает метод CheckPassword сервиса аутентификации
func (c *AuthServiceClient) CheckPassword(ctx context.Context, req *pb.CheckPasswordRequest) (*pb.CheckPasswordResponse, error) {
	return c.client.CheckPassword(ctx, req)
}

// UpdateEmail вызывает метод UpdateEmail сервиса аутентификации
func (c *AuthServiceClient) UpdateEmail(ctx context.Context, req *pb.UpdateEmailRequest) (*pb.UpdateEmailResponse, error) {
	return c.client.UpdateEmail(ctx, req)
}

// VerifyNewEmailCode вызывает метод VerifyNewEmailCode сервиса аутентификации
func (c *AuthServiceClient) VerifyNewEmailCode(ctx context.Context, req *pb.VerifyNewEmailCodeRequest) (*pb.VerifyNewEmailCodeResponse, error) {
	return c.client.VerifyNewEmailCode(ctx, req)
}

// UpdateAvatar вызывает метод UpdateAvatar сервиса аутентификации
func (c *AuthServiceClient) UpdateAvatar(ctx context.Context, req *pb.UpdateAvatarRequest) (*pb.UpdateAvatarResponse, error) {
	return c.client.UpdateAvatar(ctx, req)
}

// StartPasswordReset вызывает метод StartPasswordReset сервиса аутентификации
func (c *AuthServiceClient) StartPasswordReset(ctx context.Context, req *pb.StartPasswordResetRequest) (*pb.StartPasswordResetResponse, error) {
	return c.client.StartPasswordReset(ctx, req)
}

// VerifyPasswordResetCode вызывает метод VerifyPasswordResetCode сервиса аутентификации
func (c *AuthServiceClient) VerifyPasswordResetCode(ctx context.Context, req *pb.VerifyPasswordResetCodeRequest) (*pb.VerifyPasswordResetCodeResponse, error) {
	return c.client.VerifyPasswordResetCode(ctx, req)
}

// SetNewPassword вызывает метод SetNewPassword сервиса аутентификации
func (c *AuthServiceClient) SetNewPassword(ctx context.Context, req *pb.SetNewPasswordRequest) (*pb.SetNewPasswordResponse, error) {
	return c.client.SetNewPassword(ctx, req)
}

// DeleteAvatar вызывает метод DeleteAvatar сервиса аутентификации
func (c *AuthServiceClient) DeleteAvatar(ctx context.Context, req *pb.DeleteAvatarRequest) (*pb.DeleteAvatarResponse, error) {
	return c.client.DeleteAvatar(ctx, req)
}

// UserAddedMemory вызывает метод UserAddedMemory сервиса аутентификации
func (c *AuthServiceClient) UserAddedMemory(ctx context.Context, req *pb.UserAddedMemoryRequest) (*pb.UserAddedMemoryResponse, error) {
	return c.client.UserAddedMemory(ctx, req)
}

// UserInvitedMember вызывает метод UserInvitedMember сервиса аутентификации
func (c *AuthServiceClient) UserInvitedMember(ctx context.Context, req *pb.UserInvitedMemberRequest) (*pb.UserInvitedMemberResponse, error) {
	return c.client.UserInvitedMember(ctx, req)
}

// UserViewedMemories вызывает метод UserViewedMemories сервиса аутентификации
func (c *AuthServiceClient) UserViewedMemories(ctx context.Context, req *pb.UserViewedMemoriesRequest) (*pb.UserViewedMemoriesResponse, error) {
	return c.client.UserViewedMemories(ctx, req)
}

// GetUserAchievements вызывает метод GetUserAchievements сервиса аутентификации
func (c *AuthServiceClient) GetUserAchievements(ctx context.Context, req *pb.GetUserAchievementsRequest) (*pb.GetUserAchievementsResponse, error) {
	return c.client.GetUserAchievements(ctx, req)
}
