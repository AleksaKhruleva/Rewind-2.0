// Package server Description: Описывает gRPC сервер приложения
package server

import (
	"fmt"
	"log"
	"net"
	"os"
	"os/signal"
	"syscall"

	"google.golang.org/grpc"

	pb "Rewind-group-service/pkg/proto" // Путь к вашему сгенерированному proto файлу
)

// NewGRPCServer создает новый gRPC сервер
func NewGRPCServer() *grpc.Server {
	grpcServer := grpc.NewServer()
	return grpcServer
}

// RunGRPCServer запускает gRPC сервер
func RunGRPCServer(grpcServer *grpc.Server, groupService pb.GroupServiceServer) error {
	listenAddr := os.Getenv("GRPC_PORT")
	if listenAddr == "" {
		listenAddr = ":50052" // Значение по умолчанию
		log.Println("Warning: Server.GRPCAddress not set in .env, using default:", listenAddr)
	}

	lis, err := net.Listen("tcp", listenAddr)
	if err != nil {
		return fmt.Errorf("failed to listen: %w", err)
	}

	// Регистрация сервиса GroupService на gRPC сервере
	pb.RegisterGroupServiceServer(grpcServer, groupService)

	log.Printf("gRPC server listening on %s", listenAddr)

	quit := make(chan os.Signal, 1)
	signal.Notify(quit, os.Interrupt, syscall.SIGTERM)

	go func() {
		if err := grpcServer.Serve(lis); err != nil {
			log.Fatalf("failed to serve: %v", err)
		}
	}()

	<-quit
	log.Println("Got stop server signal, shutting down...")

	grpcServer.GracefulStop()
	log.Println("gRPC server is correctly shut down")
	return nil
}
