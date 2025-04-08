package repositories

import (
	"context"
	"time"

	"github.com/go-redis/redis/v8"
)

// RedisRepositoryInterface определяет интерфейс для взаимодействия с Redis.
type RedisRepositoryInterface interface {
	Set(ctx context.Context, key string, value interface{}, expiration time.Duration) *redis.StatusCmd
	Get(ctx context.Context, key string) *redis.StringCmd
	Del(ctx context.Context, keys ...string) *redis.IntCmd
	HSet(ctx context.Context, key string, values ...interface{}) *redis.IntCmd
	HGet(ctx context.Context, key, field string) *redis.StringCmd
	Expire(ctx context.Context, key string, expiration time.Duration) *redis.BoolCmd
}

// RedisRepository является реализацией интерфейса RedisRepositoryInterface, использующей go-redis.
type RedisRepository struct {
	client *redis.Client
}

// NewRedisRepository создает новый экземпляр RedisRepository.
func NewRedisRepository(redisURL string) (*RedisRepository, error) {
	opt, err := redis.ParseURL(redisURL)
	if err != nil {
		return nil, err
	}
	client := redis.NewClient(opt)
	_, err = client.Ping(context.Background()).Result()
	if err != nil {
		return nil, err
	}
	return &RedisRepository{client: client}, nil
}

func (r *RedisRepository) Set(ctx context.Context, key string, value interface{}, expiration time.Duration) *redis.StatusCmd {
	return r.client.Set(ctx, key, value, expiration)
}

func (r *RedisRepository) Get(ctx context.Context, key string) *redis.StringCmd {
	return r.client.Get(ctx, key)
}

func (r *RedisRepository) Del(ctx context.Context, keys ...string) *redis.IntCmd {
	return r.client.Del(ctx, keys...)
}

func (r *RedisRepository) HSet(ctx context.Context, key string, values ...interface{}) *redis.IntCmd {
	return r.client.HSet(ctx, key, values...)
}

func (r *RedisRepository) HGet(ctx context.Context, key, field string) *redis.StringCmd {
	return r.client.HGet(ctx, key, field)
}

func (r *RedisRepository) Expire(ctx context.Context, key string, expiration time.Duration) *redis.BoolCmd {
	return r.client.Expire(ctx, key, expiration)
}
