package utils

import (
	"crypto/rand"
	"encoding/base64"
	"github.com/golang-jwt/jwt/v5"
	"time"
)

// GenerateAccessToken - функция для генерации JWT (access token)
func GenerateAccessToken(userID uint, username string, secretKey string) (string, error) {
	token := jwt.New(jwt.SigningMethodHS256)

	claims := token.Claims.(jwt.MapClaims)
	claims["user_id"] = userID
	claims["username"] = username
	claims["exp"] = time.Now().Add(time.Minute * 30).Unix() // Время истечения токена

	tokenString, err := token.SignedString([]byte(secretKey))
	if err != nil {
		return "", err
	}

	return tokenString, nil
}

// GenerateRefreshToken - функция для генерации refresh token
func GenerateRefreshToken() (string, error) {
	b := make([]byte, 32)
	_, err := rand.Read(b)
	if err != nil {
		return "", err
	}
	return base64.StdEncoding.EncodeToString(b), nil
}
