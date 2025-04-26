# Builder stage
FROM golang:1.23.1-alpine AS builder

WORKDIR /app

# Установка protoc и необходимых библиотек protobuf
RUN apk update && apk add protobuf && rm -rf /var/cache/apk/*

# Установка Go плагинов для protoc
ENV GOPATH /go
ENV PATH $GOPATH/bin:$PATH

RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@latest \
    && go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest

# Копируем go.mod и go.sum первыми для лучшего кэширования Docker
COPY go.mod go.sum ./

# Скачиваем зависимости Go
RUN go mod download

# --- ДОБАВЬТЕ ЭТУ СТРОКУ ---
# Явно копируем файл .env в рабочую директорию стадии builder
COPY .env ./
# --------------------------

# Копируем остальной исходный код проекта, включая директорию 'proto'
COPY . .

# Генерируем Go код из .proto файлов
RUN protoc --proto_path=. --go_out=./pkg --go-grpc_out=./pkg --go_opt=paths=source_relative --go-grpc_opt=paths=source_relative proto/auth.proto

# Собираем Go приложение
RUN go build -ldflags="-s -w" -o auth-service ./cmd/main.go

# Финальная стадия (остается без изменений)
FROM scratch

# Копируем собранный бинарник и .env из builder stage
COPY --from=builder /app/auth-service /app/
COPY --from=builder /app/.env /app/

WORKDIR /app

EXPOSE 50051

ENTRYPOINT ["/app/auth-service"]
