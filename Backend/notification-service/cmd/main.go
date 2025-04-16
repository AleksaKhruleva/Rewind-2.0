package main

import (
	"Rewind-notification-service/pkg/rabbitmq"
	"github.com/joho/godotenv"
	amqp "github.com/rabbitmq/amqp091-go"
	"log"
)

func main() {
	if err := godotenv.Load(); err != nil {
		log.Println("Error loading .env file")
	}
	conn, err := rabbitmq.Connect()
	if err != nil {
		log.Fatalf("Failed to connect to RabbitMQ: %v", err)
	}
	defer func(conn *amqp.Connection) {
		err := conn.Close()
		if err != nil {
			log.Fatalf("Failed to close RabbitMQ connection: %v", err)
		}
	}(conn)

	log.Println("Connected to RabbitMQ!")

	go rabbitmq.ConsumeVerificationCodes(conn)
	go rabbitmq.ConsumePasswordResetEmails(conn)

	var forever chan struct{}
	<-forever
}
