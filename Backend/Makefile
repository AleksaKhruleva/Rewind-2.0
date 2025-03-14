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


# Генерация моков
.PHONY: mocks
mocks:
	cd ./internal/app/services && go generate
	cd ./internal/app/repositories && go generate