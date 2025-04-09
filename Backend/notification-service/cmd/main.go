package main

import (
	"Rewind-notification-service/pkg/rabbitmq"
	amqp "github.com/rabbitmq/amqp091-go"
	"log"
)

func main() {
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
