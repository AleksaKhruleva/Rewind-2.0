package utils

import (
	"fmt"
	"math/rand"
)

func GenerateVerificationCode() string {
	return fmt.Sprintf("%04d", rand.Intn(10000)) // Генерирует случайное число от 0000 до 9999
}
