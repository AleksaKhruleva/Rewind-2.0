package email

import (
	"fmt"
	"log"
	"net/smtp"
	"os"
)

func sendEmail(toEmail, subject, body string) error {
	fromEmail := os.Getenv("SMTP_FROM_EMAIL")
	fromPassword := os.Getenv("SMTP_PASSWORD")
	smtpHost := os.Getenv("SMTP_HOST")
	smtpPort := os.Getenv("SMTP_PORT")

	if fromEmail == "" || fromPassword == "" || smtpHost == "" || smtpPort == "" {
		log.Println("Warning: SMTP configuration environment variables not set.")
		return fmt.Errorf("SMTP configuration not complete")
	}

	auth := smtp.PlainAuth("", fromEmail, fromPassword, smtpHost)
	addr := fmt.Sprintf("%s:%s", smtpHost, smtpPort)

	msg := []byte("To: " + toEmail + "\r\n" +
		"Subject: " + subject + "\r\n" +
		"\r\n" +
		body + "\r\n")

	err := smtp.SendMail(addr, auth, fromEmail, []string{toEmail}, msg)
	if err != nil {
		return fmt.Errorf("failed to send email: %w", err)
	}
	log.Printf("Email sent successfully to %s", toEmail)
	return nil
}

// SendVerificationEmail отправляет email с кодом верификации
func SendVerificationEmail(email, code string) error {
	subject := "Ваш код верификации"
	body := fmt.Sprintf("Здравствуйте!\n\nВаш код верификации: %s\n\nПожалуйста, введите этот код для завершения регистрации.", code)
	return sendEmail(email, subject, body)
}

// SendPasswordResetEmail отправляет email со ссылкой для сброса пароля
func SendPasswordResetEmail(email, resetLink string) error {
	subject := "Запрос на сброс пароля"
	body := fmt.Sprintf("Здравствуйте!\n\nВы запросили сброс пароля. Перейдите по следующей ссылке, чтобы сбросить пароль:\n\n%s\n\nЕсли вы не запрашивали сброс пароля, проигнорируйте это письмо.", resetLink)
	return sendEmail(email, subject, body)
}
