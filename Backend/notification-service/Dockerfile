FROM golang:1.23.1-alpine AS builder

WORKDIR /app

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go build -ldflags="-s -w" -o notification-service ./cmd/main.go

FROM scratch

COPY --from=builder /app/notification-service /app/
COPY --from=builder /app/.env /app/

WORKDIR /app

EXPOSE 50053

ENTRYPOINT ["/app/notification-service"]