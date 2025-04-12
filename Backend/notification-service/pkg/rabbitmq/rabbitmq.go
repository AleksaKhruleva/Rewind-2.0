package rabbitmq

import (
	"Rewind-notification-service/pkg/email"
	"encoding/json"
	"fmt"
	"log"
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

func ConsumeVerificationCodes(conn *amqp.Connection) {
	ch, err := conn.Channel()
	if err != nil {
		log.Printf("Failed to open a channel: %v", err)
		return
	}
	defer ch.Close()

	queueName := "verification_codes"
	q, err := ch.QueueDeclare(
		queueName, // name
		true,      // durable
		false,     // delete when unused
		false,     // exclusive
		false,     // no-wait
		nil,       // arguments
	)
	if err != nil {
		log.Printf("Failed to declare a queue: %v", err)
		return
	}

	msgs, err := ch.Consume(
		q.Name, // queue
		"",     // consumer
		false,  // auto-ack
		false,  // exclusive
		false,  // no-local
		false,  // no-wait
		nil,    // args
	)
	if err != nil {
		log.Printf("Failed to register a consumer: %v", err)
		return
	}

	log.Printf(" [*] Waiting for verification code messages...")

	for d := range msgs {
		var message VerificationCodeMessage
		err := json.Unmarshal(d.Body, &message)
		if err != nil {
			log.Printf("Failed to unmarshal verification code message: %v", err)
		} else {
			err = d.Ack(false)
			if err != nil {
				log.Printf("Failed to acknowledge message: %v", err)
				return
			}
			log.Printf(" [x] Received verification code for: %s, Code: %s", message.Email, message.Code)
			err := email.SendVerificationEmail(message.Email, message.Code)
			if err != nil {
				log.Printf("Couldn't send verification email: %s", err)
			}
		}
	}

}

func ConsumePasswordResetEmails(conn *amqp.Connection) {
	ch, err := conn.Channel()
	if err != nil {
		log.Printf("Failed to open a channel: %v", err)
		return
	}
	defer ch.Close()

	queueName := "password_reset_emails"
	q, err := ch.QueueDeclare(
		queueName, // name
		true,      // durable
		false,     // delete when unused
		false,     // exclusive
		false,     // no-wait
		nil,       // arguments
	)
	if err != nil {
		log.Printf("Failed to declare a queue: %v", err)
		return
	}

	msgs, err := ch.Consume(
		q.Name, // queue
		"",     // consumer
		false,  // auto-ack
		false,  // exclusive
		false,  // no-local
		false,  // no-wait
		nil,    // args
	)
	if err != nil {
		log.Printf("Failed to register a consumer: %v", err)
		return
	}

	log.Printf(" [*] Waiting for password reset email messages...")

	for d := range msgs {
		var message PasswordResetMessage
		err := json.Unmarshal(d.Body, &message)
		if err != nil {
			log.Printf("Failed to unmarshal password reset email message: %v", err)
		} else {
			// Подтверждаем обработку сообщения
			err = d.Ack(false)
			if err != nil {
				log.Printf("Failed to acknowledge message: %v", err)
				return
			}

			log.Printf(" [x] Received password reset request for: %s, Link: %s", message.Email, message.ResetLink)
			err := email.SendPasswordResetEmail(message.Email, message.ResetLink)
			if err != nil {
				log.Printf("Couldn't send password reset email message: %s", err)
			}
		}
	}

}
