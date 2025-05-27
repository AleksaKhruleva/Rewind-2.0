package di

import (
	"log"
	"os"

	"github.com/go-playground/validator/v10"

	"Rewind-media-service/internal/app/services"
	pb "Rewind-media-service/pkg/proto"
)

type Dependencies struct {
	Validator    *validator.Validate
	MediaService pb.MediaServiceServer
}

func BuildDependencies() Dependencies {

	mediaValidator := validator.New()

	// Load configuration from environment variables
	endpointURL := os.Getenv("S3_ENDPOINT_URL")
	imageBucket := os.Getenv("S3_IMAGE_BUCKET")
	videoBucket := os.Getenv("S3_VIDEO_BUCKET")
	quoteBucket := os.Getenv("S3_QUOTE_BUCKET")
	avatarBucket := os.Getenv("S3_AVATAR_BUCKET")

	if endpointURL == "" || imageBucket == "" || videoBucket == "" || quoteBucket == "" || avatarBucket == "" {
		log.Fatalf("Missing required environment variables. Please check your .env file.")
	}

	bucketNames := map[pb.MediaType]string{
		pb.MediaType_image:  imageBucket,
		pb.MediaType_video:  videoBucket,
		pb.MediaType_quote:  quoteBucket,
		pb.MediaType_avatar: avatarBucket,
	}

	imagesAllowed := []string{".jpg", ".jpeg", ".png", ".heic"}
	videosAllowed := []string{".mov", ".mp4"}

	allowedExtensions := map[pb.MediaType][]string{
		pb.MediaType_image:  imagesAllowed,
		pb.MediaType_video:  videosAllowed,
		pb.MediaType_quote:  imagesAllowed,
		pb.MediaType_avatar: imagesAllowed,
	}

	mediaService, err := services.NewMediaService(
		mediaValidator,
		endpointURL,
		bucketNames,
		allowedExtensions,
	)
	if err != nil {
		log.Fatalf("Failed to create media service: %v", err)
	}

	return Dependencies{
		Validator:    mediaValidator,
		MediaService: mediaService,
	}
}
