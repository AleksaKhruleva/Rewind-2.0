# Builder stage
FROM golang:1.23.1-alpine AS builder

WORKDIR /app


ENV GOPATH /go
ENV PATH $GOPATH/bin:$PATH

# Копируем go.mod и go.sum первыми для лучшего кэширования Docker
COPY go.mod go.sum ./

# Скачиваем зависимости Go
RUN go mod download

# Копируем остальной исходный код проекта
COPY . .

# Собираем Go приложение
RUN go build -ldflags="-s -w" -o api-gateway-service ./cmd/main.go

# Финальная стадия
FROM scratch

WORKDIR /app

# Копируем собранный бинарник и конфигурационные файлы из builder stage
COPY --from=builder /app/api-gateway-service /app/
COPY --from=builder /app/.env /app/


EXPOSE 8080

ENTRYPOINT ["/app/api-gateway-service"]
