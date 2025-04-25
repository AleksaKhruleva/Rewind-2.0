# Builder stage
FROM golang:1.23.1-alpine AS builder

WORKDIR /app

# Установка компилятора protoc и необходимых библиотек в builder образе
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

# Копируем остальной исходный код проекта, включая директорию 'proto'
COPY . .

# Генерируем Go код из .proto файлов, необходимых для API Gateway
RUN protoc --go_out=./pkg --go-grpc_out=./pkg --go_opt=paths=source_relative --go-grpc_opt=paths=source_relative proto/auth.proto

# Собираем Go приложение (теперь уже с сгенерированными файлами)
RUN go build -ldflags="-s -w" -o api-gateway-service ./cmd/main.go

# Финальная стадия
FROM scratch

WORKDIR /app

# Копируем собранный бинарник и конфигурационные файлы из builder stage
COPY --from=builder /app/api-gateway-service /app/
COPY --from=builder /app/.env /app/


EXPOSE 8080

ENTRYPOINT ["/app/api-gateway-service"]
