# Builder stage
FROM golang:1.23.1-alpine AS builder

WORKDIR /app

ENV GOPATH /go
ENV PATH $GOPATH/bin:$PATH

# Копируем go.mod и go.sum первыми для лучшего кэширования Docker
COPY go.mod go.sum ./

# Скачиваем зависимости Go
RUN go mod download

# Явно копируем файл .env в рабочую директорию стадии builder
COPY .env ./
# --------------------------

# Копируем остальной исходный код проекта
COPY . .

# Собираем Go приложение
RUN go build -ldflags="-s -w" -o media-service ./cmd/main.go

FROM alpine:3.20

# Устанавливаем bash, curl и сертификаты
RUN apk add --no-cache bash curl ca-certificates

# Копируем собранный бинарник и .env
COPY --from=builder /app/media-service /app/
COPY --from=builder /app/.env /app/

WORKDIR /app

EXPOSE 50055

ENTRYPOINT ["/app/media-service"]
