package middleware

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"strings"

	"github.com/golang-jwt/jwt/v5"

	// Assuming you have a common responses package with an ErrorResponse struct
	"Rewind-api-gateway-service/internal/app/responses"
)

// ContextKey is a custom type for context keys to avoid collisions.
type ContextKey string

const (
	// ContextKeyUserID is the key used to store the authenticated user ID in the request context.
	ContextKeyUserID ContextKey = "userID"
)

// ExcludedPaths are the URL paths that do NOT require JWT authentication.
// These should match the paths registered in your router setup that don't need a token.
var ExcludedPaths = []string{
	"/api/auth/",
	"/swagger/",
}

// AuthMiddleware is a chi middleware that validates the JWT token from the Authorization header.
// If the token is valid, it extracts the user ID and adds it to the request context.
// If the token is missing or invalid, it responds with a 401 Unauthorized error.
func AuthMiddleware(next http.Handler) http.Handler {
	// Get the JWT secret key once when the middleware is initialized
	jwtSecretKey := os.Getenv("JWT_SECRET_KEY")
	if jwtSecretKey == "" {
		// Log a fatal error if the secret key is not set, as the middleware cannot function
		log.Fatal("JWT_SECRET_KEY environment variable not set. Authentication middleware cannot be initialized.")
	}
	secretKeyBytes := []byte(jwtSecretKey)

	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		// Check if the current request path is in the excluded list
		// Using strings.HasPrefix for paths like /api/auth and /swagger/
		for _, pathPrefix := range ExcludedPaths {
			if strings.HasPrefix(r.URL.Path, pathPrefix) {
				// If the path is excluded, skip authentication and proceed to the next handler
				next.ServeHTTP(w, r)
				return
			}
		}

		// Get the Authorization header from the request
		authHeader := r.Header.Get("Authorization")

		// Check if the Authorization header is missing or not in "Bearer <token>" format
		if authHeader == "" || !strings.HasPrefix(authHeader, "Bearer ") {
			log.Printf("AuthMiddleware: Missing or invalid Authorization header")
			respondUnauthorized(w, "Authentication required")
			return
		}

		// Extract the token string by removing the "Bearer " prefix
		tokenString := strings.TrimPrefix(authHeader, "Bearer ")

		// Parse and validate the JWT token
		token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
			// Verify the signing method is HMAC
			if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
				log.Printf("AuthMiddleware: Unexpected signing method: %v", token.Method)
				return nil, fmt.Errorf("unexpected signing method: %v", token.Method)
			}
			// Return the secret key for validation
			return secretKeyBytes, nil
		})

		// Check for parsing or validation errors
		if err != nil {
			log.Printf("AuthMiddleware: Token parsing or validation failed: %v", err)
			respondUnauthorized(w, "Invalid or expired token")
			return
		}

		// Check if the token is valid and extract claims
		if claims, ok := token.Claims.(jwt.MapClaims); ok && token.Valid {
			// Extract the user_id claim. JWT claims are often float64 for numbers.
			userIDFloat, ok := claims["user_id"].(float64)
			if !ok {
				log.Printf("AuthMiddleware: User ID claim not found or not a number in token")
				respondUnauthorized(w, "Invalid token claims")
				return
			}
			userID := uint64(userIDFloat) // Convert float64 to uint64

			// Add the extracted user ID to the request context
			ctx := context.WithValue(r.Context(), ContextKeyUserID, userID)
			r = r.WithContext(ctx)

			// Proceed to the next handler in the chain with the updated context
			next.ServeHTTP(w, r)
		} else {
			// If token is not valid or claims are not MapClaims
			log.Printf("AuthMiddleware: Invalid token or claims format")
			respondUnauthorized(w, "Invalid token")
		}
	})
}

// respondUnauthorized sends a 401 Unauthorized JSON response.
func respondUnauthorized(w http.ResponseWriter, message string) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusUnauthorized)
	// Use the common ErrorResponse struct
	jsonErr := responses.ErrorResponse{Error: message}
	if err := json.NewEncoder(w).Encode(jsonErr); err != nil {
		log.Printf("Failed to encode JSON unauthorized response: %v", err)
		// Fallback to a simple text response if JSON encoding fails
		http.Error(w, "Unauthorized", http.StatusInternalServerError)
	}
}
