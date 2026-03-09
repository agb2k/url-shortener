# frozen_string_literal: true

require "test_helper"

class RateLimiterTest < ActiveSupport::TestCase
  SCOPE = "test:rate_limit"

  setup do
    @fake_redis = FakeRedis.new
    # AppRedis.connection checks ENV["REDIS_URL"] before returning @connection,
    # so we set both: the env var to pass the availability check, and the
    # instance variable so it returns our fake instead of opening a real socket.
    ENV["REDIS_URL"] = "redis://test"
    AppRedis.instance_variable_set(:@connection, @fake_redis)
  end

  teardown do
    ENV.delete("REDIS_URL")
    AppRedis.instance_variable_set(:@connection, nil)
  end

  test "returns false when count is below limit" do
    assert_equal false, RateLimiter.exceeded?(SCOPE, "ip_below", limit: 3, period: 1.minute)
  end

  test "returns false when count equals limit" do
    2.times { RateLimiter.exceeded?(SCOPE, "ip_at", limit: 3, period: 1.minute) }
    assert_equal false, RateLimiter.exceeded?(SCOPE, "ip_at", limit: 3, period: 1.minute)
  end

  test "returns true when count exceeds limit" do
    3.times { RateLimiter.exceeded?(SCOPE, "ip_over", limit: 3, period: 1.minute) }
    assert_equal true, RateLimiter.exceeded?(SCOPE, "ip_over", limit: 3, period: 1.minute)
  end

  test "returns false when Redis is unavailable" do
    ENV.delete("REDIS_URL")
    AppRedis.instance_variable_set(:@connection, nil)
    assert_equal false, RateLimiter.exceeded?(SCOPE, "ip", limit: 1, period: 1.minute)
  end

  private

  class FakeRedis
    def initialize = (@store = Hash.new(0))
    def incr(key)          = (@store[key] += 1)
    def expire(_key, _ttl) = nil
  end
end
