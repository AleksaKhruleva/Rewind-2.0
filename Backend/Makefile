# Имя исполняемого файла
#BINARY_NAME=merch-service

# Переменные для путей
CMD_PATH=cmd
OUTPUT_PATH=bin

# Установка зависимостей
.PHONY: deps
deps:
	go mod tidy
	go mod download

# Запуск линтера
.PHONY: lint
lint:
	golangci-lint run ./...

# Форматирование кода
.PHONY: fmt
fmt:
	go fmt ./...
	goimports -w .

# Проверка статического анализа
.PHONY: vet
vet:
	go vet ./...

# Запуск юнит-тестов с покрытием кода
.PHONY: test
test:
	make mocks
	CGO_ENABLED=1 go test -cover -race -v -coverpkg=./internal/... ./tests/...

# Запуск интеграционных тестов
.PHONY: test-integration
test-integration:
	go test -tags=integration -v ./tests/integration/...

# Сборка бинарного файла
#.PHONY: build
#build: fmt vet
#	go build -o $(OUTPUT_PATH)/$(BINARY_NAME) $(CMD_PATH)/main.go

# Запуск сервиса
.PHONY: run
run:
	go run $(CMD_PATH)/main.go

# Запуск через Docker
.PHONY: docker
docker:
	docker compose up -d --build

# Остановка Docker
.PHONY: stop
stop:
	docker compose down

.PHONY: swagger
swagger:
	cd ./api-gateway-service && swag init -g cmd/main.go

# Генерация моков
.PHONY: mocks
mocks:
	cd ./internal/app/services && go generate
	cd ./internal/app/repositories && go generate

# Генерация протофайлов для auth-service из Backend
.PHONY: proto-auth
proto-auth:
	cd ./auth-service && mkdir -p pkg
	cd ./auth-service && mkdir -p proto/clients
	cd ./auth-service && protoc --go_out=./pkg --go-grpc_out=./pkg --go_opt=paths=source_relative --go-grpc_opt=paths=source_relative proto/auth.proto
	cp ./media-service/proto/media.proto ./auth-service/proto/clients
	cd ./auth-service && protoc --go_out=./pkg --go-grpc_out=./pkg --go_opt=paths=source_relative --go-grpc_opt=paths=source_relative proto/clients/media.proto


# Генерация протофайлов для group-service из Backend
.PHONY: proto-group
proto-group:
	cd ./group-service && mkdir -p pkg
	cd ./group-service && mkdir -p proto/clients
	cd ./group-service && protoc --go_out=./pkg --go-grpc_out=./pkg --go_opt=paths=source_relative --go-grpc_opt=paths=source_relative proto/group.proto
	cp ./auth-service/proto/auth.proto ./group-service/proto/clients
	cd ./group-service && protoc --go_out=./pkg --go-grpc_out=./pkg --go_opt=paths=source_relative --go-grpc_opt=paths=source_relative proto/clients/auth.proto
	cp ./media-service/proto/media.proto ./group-service/proto/clients
	cd ./group-service && protoc --go_out=./pkg --go-grpc_out=./pkg --go_opt=paths=source_relative --go-grpc_opt=paths=source_relative proto/clients/media.proto


# Генерация протофайлов для memory-service из Backend
.PHONY: proto-memory
proto-memory:
	cd ./memory-service && mkdir -p pkg
	cd ./memory-service && mkdir -p proto/clients
	cd ./memory-service && protoc --go_out=./pkg --go-grpc_out=./pkg --go_opt=paths=source_relative --go-grpc_opt=paths=source_relative proto/memory.proto
	cp ./auth-service/proto/auth.proto ./memory-service/proto/clients
	cd ./memory-service && protoc --go_out=./pkg --go-grpc_out=./pkg --go_opt=paths=source_relative --go-grpc_opt=paths=source_relative proto/clients/auth.proto
	cp ./media-service/proto/media.proto ./memory-service/proto/clients
	cd ./memory-service && protoc --go_out=./pkg --go-grpc_out=./pkg --go_opt=paths=source_relative --go-grpc_opt=paths=source_relative proto/clients/media.proto

# Генерация протофайлов для media-service из Backend
.PHONY: proto-media
proto-media:
	cd ./media-service && mkdir -p pkg
	cd ./media-service && protoc --go_out=./pkg --go-grpc_out=./pkg --go_opt=paths=source_relative --go-grpc_opt=paths=source_relative proto/media.proto

# Генерация протофайлов для api-gateway-service из Backend
.PHONY: proto-api-gateway
proto-api-gateway:
	cd ./api-gateway-service && mkdir -p pkg
	cd ./api-gateway-service && mkdir -p proto/clients
	cp ./auth-service/proto/auth.proto ./api-gateway-service/proto
	cd ./api-gateway-service && protoc --go_out=./pkg --go-grpc_out=./pkg --go_opt=paths=source_relative --go-grpc_opt=paths=source_relative proto/auth.proto
	cp ./group-service/proto/group.proto ./api-gateway-service/proto
	cd ./api-gateway-service && protoc --go_out=./pkg --go-grpc_out=./pkg --go_opt=paths=source_relative --go-grpc_opt=paths=source_relative proto/group.proto
	cp ./memory-service/proto/memory.proto ./api-gateway-service/proto
	cd ./api-gateway-service && protoc --go_out=./pkg --go-grpc_out=./pkg --go_opt=paths=source_relative --go-grpc_opt=paths=source_relative proto/memory.proto

.PHONY: proto
proto:
	make proto-auth
	make proto-group
	make proto-memory
	make proto-media
	make proto-api-gateway