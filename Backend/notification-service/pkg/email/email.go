package email

import (
	"encoding/base64"
	"fmt"
	"log"
	"net/smtp"
	"os"
	"strings"
)

// sendEmail отправляет email с корректным MIME и заголовками
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

	encodedSubject := encodeRFC2047(subject)

	headers := make(map[string]string)
	headers["From"] = fromEmail
	headers["To"] = toEmail
	headers["Subject"] = encodedSubject
	headers["MIME-Version"] = "1.0"
	headers["Content-Type"] = "text/plain; charset=\"UTF-8\""
	headers["Content-Transfer-Encoding"] = "8bit"

	var msg strings.Builder
	for k, v := range headers {
		msg.WriteString(fmt.Sprintf("%s: %s\r\n", k, v))
	}
	msg.WriteString("\r\n" + body + "\r\n")

	log.Println("Sending email to", toEmail)
	err := smtp.SendMail(addr, auth, fromEmail, []string{toEmail}, []byte(msg.String()))
	if err != nil {
		return fmt.Errorf("failed to send email: %w", err)
	}
	log.Printf("Email sent successfully to %s", toEmail)
	return nil
}

// encodeRFC2047 кодирует строку для использования в заголовках письма (Subject)
func encodeRFC2047(str string) string {
	// =?UTF-8?B?<base64>?=
	return fmt.Sprintf("=?UTF-8?B?%s?=", base64.StdEncoding.EncodeToString([]byte(str)))
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
