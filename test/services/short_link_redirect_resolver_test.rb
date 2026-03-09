# frozen_string_literal: true

require "test_helper"

class ShortLinkRedirectResolverTest < ActiveSupport::TestCase
  setup do
    @link = short_links(:google)
  end

  teardown do
    ENV.delete("REDIS_URL")
    AppRedis.instance_variable_set(:@connection, nil)
  end

  test "returns nil for an unknown short code" do
    assert_nil ShortLinkRedirectResolver.resolve("does_not_exist")
  end

  test "resolves from DB when Redis is unavailable" do
    payload = ShortLinkRedirectResolver.resolve(@link.short_code)
    assert_not_nil payload
    assert_equal @link.id, payload[:short_link_id]
  end

  test "resolves from cache on cache hit" do
    cached = { original_url: "https://www.google.com", short_link_id: @link.id }.to_json
    fake_redis = Object.new
    fake_redis.define_singleton_method(:get) { |_key| cached }

    with_fake_redis(fake_redis) do
      payload = ShortLinkRedirectResolver.resolve(@link.short_code)
      assert_equal @link.id, payload[:short_link_id]
    end
  end

  test "writes to cache on cache miss" do
    written = {}
    fake_redis = Object.new
    fake_redis.define_singleton_method(:get)   { |_key| nil }
    fake_redis.define_singleton_method(:setex) { |key, _ttl, val| written[key] = val }

    with_fake_redis(fake_redis) do
      ShortLinkRedirectResolver.resolve(@link.short_code)
    end

    assert written.any?, "Expected at least one key to be written to Redis"
  end

  private

  def with_fake_redis(fake)
    ENV["REDIS_URL"] = "redis://test"
    AppRedis.instance_variable_set(:@connection, fake)
    yield
  ensure
    ENV.delete("REDIS_URL")
    AppRedis.instance_variable_set(:@connection, nil)
  end
end
