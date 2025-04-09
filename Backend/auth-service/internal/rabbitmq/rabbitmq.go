package rabbitmq

import (
	"encoding/json"
	"fmt"
	"os"

	amqp "github.com/rabbitmq/amqp091-go"
)

type VerificationCodeMessage struct {
	Email string `json:"email"`
	Code  string `json:"code"`
}

type PasswordResetMessage struct {
	Email     string `json:"email"`
	ResetLink string `json:"reset_link"`
}

// Connect устанавливает соединение с RabbitMQ
func Connect() (*amqp.Connection, error) {
	amqpURL := os.Getenv("RABBITMQ_URL")
	if amqpURL == "" {
		amqpURL = "amqp://guest:guest@localhost:5672/" // Значение по умолчанию для локальной разработки
		fmt.Println("Warning: RABBITMQ_URL environment variable not set, using default.")
	}

	conn, err := amqp.Dial(amqpURL)
	if err != nil {
		return nil, fmt.Errorf("failed to connect to RabbitMQ: %w", err)
	}
	return conn, nil
}

// PublishVerificationCode публикует сообщение с кодом верификации в очередь
func PublishVerificationCode(email, code string) error {
	conn, err := Connect()
	if err != nil {
		return err
	}
	defer conn.Close()

	ch, err := conn.Channel()
	if err != nil {
		return fmt.Errorf("failed to open a channel: %w", err)
	}
	defer ch.Close()

	queueName := "verification_codes" // Имя вашей очереди
	_, err = ch.QueueDeclare(
		queueName, // name
		true,      // durable
		false,     // delete when unused
		false,     // exclusive
		false,     // no-wait
		nil,       // arguments
	)
	if err != nil {
		return fmt.Errorf("failed to declare a queue: %w", err)
	}

	message := VerificationCodeMessage{Email: email, Code: code}
	body, err := json.Marshal(message)
	if err != nil {
		return fmt.Errorf("failed to marshal message: %w", err)
	}

	err = ch.Publish(
		"",        // exchange (используем exchange по умолчанию)
		queueName, // routing key (совпадает с именем очереди для exchange по умолчанию)
		false,     // mandatory
		false,     // immediate
		amqp.Publishing{
			ContentType: "application/json",
			Body:        body,
		})
	if err != nil {
		return fmt.Errorf("failed to publish a message: %w", err)
	}

	fmt.Printf(" [x] Sent %s\n", body)
	return nil
}

// PublishForgotPasswordEmail публикует сообщение со ссылкой для сброса пароля в очередь
func PublishForgotPasswordEmail(email, resetLink string) error {
	conn, err := Connect()
	if err != nil {
		return err
	}
	defer conn.Close()

	ch, err := conn.Channel()
	if err != nil {
		return fmt.Errorf("failed to open a channel: %w", err)
	}
	defer ch.Close()

	queueName := "password_reset_emails" // Имя очереди для сброса пароля
	_, err = ch.QueueDeclare(
		queueName, // name
		true,      // durable
		false,     // delete when unused
		false,     // exclusive
		false,     // no-wait
		nil,       // arguments
	)
	if err != nil {
		return fmt.Errorf("failed to declare a queue: %w", err)
	}

	message := PasswordResetMessage{Email: email, ResetLink: resetLink}
	body, err := json.Marshal(message)
	if err != nil {
		return fmt.Errorf("failed to marshal message: %w", err)
	}

	err = ch.Publish(
		"",        // exchange (используем exchange по умолчанию)
		queueName, // routing key (совпадает с именем очереди)
		false,     // mandatory
		false,     // immediate
		amqp.Publishing{
			ContentType: "application/json",
			Body:        body,
		})
	if err != nil {
		return fmt.Errorf("failed to publish a message: %w", err)
	}

	fmt.Printf(" [x] Sent password reset link for %s\n", email)
	return nil
}
