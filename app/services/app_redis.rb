# frozen_string_literal: true

# Single Redis connection for the app (rate limiting, redirect cache). Named AppRedis to avoid clashing with the redis-client gem's RedisClient class.
class AppRedis
  class << self
    def available?
      ENV["REDIS_URL"].present?
    end

    def connection
      return nil unless available?

      @connection ||= Redis.new(url: ENV["REDIS_URL"])
    end
  end
end
