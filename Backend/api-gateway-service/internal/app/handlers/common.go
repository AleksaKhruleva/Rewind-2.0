package handlers

import (
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"Rewind-api-gateway-service/internal/app/responses"
)

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

// handleServiceError преобразует ошибки сервисного слоя (gRPC статусы) в HTTP статусы.
func handleServiceError(w http.ResponseWriter, err error, action string) {
	st, ok := status.FromError(err)
	if ok {
		log.Printf("Service error during %s (gRPC code %s): %v", action, st.Code().String(), st.Message())
		switch st.Code() {
		case codes.InvalidArgument:
			respondError(w, http.StatusBadRequest, st.Message())
		case codes.Unauthenticated:
			respondError(w, http.StatusUnauthorized, st.Message())
		case codes.PermissionDenied:
			respondError(w, http.StatusForbidden, st.Message())
		case codes.NotFound:
			respondError(w, http.StatusNotFound, st.Message())
		case codes.AlreadyExists:
			respondError(w, http.StatusConflict, st.Message())
		case codes.Unavailable:
			respondError(w, http.StatusServiceUnavailable, "Service is unavailable. Please try again later.")
		default:
			// Для всех остальных ошибок gRPC (Internal, Unknown, etc.) возвращаем Internal Server Error
			respondError(w, http.StatusInternalServerError, "Internal Server Error from service")
		}
	} else {
		// Обработка ошибок, которые не являются gRPC статусами
		log.Printf("Non-gRPC error during %s: %v", action, err)
		respondError(w, http.StatusInternalServerError, "Internal Server Error")
	}
}
