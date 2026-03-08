# frozen_string_literal: true

# Cache-aside for the redirect hot path using AppRedis; falls back to DB when Redis is unavailable.
class ShortLinkRedirectResolver
  CACHE_KEY_PREFIX = "short_link/redirect/"
  CACHE_TTL = 24.hours

  class << self
    def resolve(short_code)
      key = "#{CACHE_KEY_PREFIX}#{short_code}"
      redis = AppRedis.connection

      if redis
        raw = redis.get(key)
        return JSON.parse(raw, symbolize_names: true) if raw
      end

      link = ShortLink.find_by(short_code: short_code)
      return nil unless link

      payload = { original_url: ShortLink.url_with_www(link.original_url), short_link_id: link.id }
      redis&.setex(key, CACHE_TTL.to_i, payload.to_json)
      payload
    end
  end
end
