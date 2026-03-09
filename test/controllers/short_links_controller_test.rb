# frozen_string_literal: true

require "test_helper"

class ShortLinksControllerTest < ActionDispatch::IntegrationTest
  setup do
    ActiveJob::Base.queue_adapter = :test
  end

  teardown do
    ActiveJob::Base.queue_adapter = :async
    ENV.delete("REDIS_URL")
    AppRedis.instance_variable_set(:@connection, nil)
  end

  # --- GET /links ---

  test "index renders the URL form" do
    get short_links_path
    assert_response :ok
    assert_select "form"
  end

  # --- POST /links ---

  test "create with a valid URL redirects to show page" do
    post short_links_path, params: { short_link: { original_url: "https://example-new.com" } }
    assert_response :redirect
    follow_redirect!
    assert_response :ok
  end

  test "create enqueues ScrapeTitleJob for new links" do
    assert_enqueued_with(job: ScrapeTitleJob) do
      post short_links_path, params: { short_link: { original_url: "https://brand-new-url.com" } }
    end
  end

  test "create with a duplicate URL redirects to the existing short link" do
    existing = short_links(:google)
    post short_links_path, params: { short_link: { original_url: existing.original_url } }
    assert_redirected_to short_link_path(existing)
  end

  test "create with an invalid URL re-renders the form with 422" do
    post short_links_path, params: { short_link: { original_url: "not-a-url" } }
    assert_response :unprocessable_entity
  end

  test "create with a blank URL re-renders the form with 422" do
    post short_links_path, params: { short_link: { original_url: "" } }
    assert_response :unprocessable_entity
  end

  # --- GET /links/:id ---

  test "show renders the short link detail" do
    link = short_links(:youtube)
    get short_link_path(link)
    assert_response :ok
    assert_select "a[href*='#{link.short_code}']"
  end

  test "show returns 404 for an unknown short code" do
    get short_link_path("no_such_code")
    assert_response :not_found
  end

  # --- GET /r/:short_code ---

  test "redirect issues a 302 to the original URL" do
    get short_link_redirect_path(short_links(:google).short_code)
    assert_response :found
  end

  test "redirect enqueues LogVisitJob" do
    assert_enqueued_with(job: LogVisitJob) do
      get short_link_redirect_path(short_links(:github).short_code)
    end
  end

  test "redirect returns 404 for an unknown short code" do
    get short_link_redirect_path("unknown_xyz")
    assert_response :not_found
  end

  # --- Rate limiting ---

  test "create returns 429 after exceeding the limit" do
    fake_redis = FakeRedis.new
    ENV["REDIS_URL"] = "redis://test"
    AppRedis.instance_variable_set(:@connection, fake_redis)

    ShortLinksController::CREATE_RATE_LIMIT.times do |i|
      post short_links_path, params: { short_link: { original_url: "https://site#{i}.example.com" } }
    end
    post short_links_path, params: { short_link: { original_url: "https://one-too-many.com" } }
    assert_response :too_many_requests
  end

  private

  class FakeRedis
    def initialize = (@store = Hash.new(0))
    def incr(key)          = (@store[key] += 1)
    def get(key)           = @store[key]&.to_s
    def setex(key, _, val) = (@store[key] = val)
    def expire(_k, _t)     = nil
  end
end
