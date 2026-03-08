# frozen_string_literal: true

# Fixed window per period; keys get TTL so they don't leak.
class RateLimiter
  KEY_PREFIX = "rate_limit:"

  class << self
    def exceeded?(scope, identifier, limit:, period: 1.minute)
      redis = AppRedis.connection
      return false unless redis

      key = key_for(scope, identifier, period)
      count = redis.incr(key)
      redis.expire(key, period.to_i + 1) if count == 1

      count > limit
    end

    private

    def key_for(scope, identifier, period)
      window = (Time.current.to_i / period.to_i) * period.to_i
      "#{KEY_PREFIX}#{scope}:#{identifier}:#{window}"
    end
  end
end
