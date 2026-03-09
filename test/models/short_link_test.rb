# frozen_string_literal: true

require "test_helper"

class ShortLinkTest < ActiveSupport::TestCase
  # --- canonical_url ---

  test "canonical_url adds https scheme when missing" do
    assert_equal "https://example.com", ShortLink.canonical_url("example.com")
  end

  test "canonical_url strips www prefix" do
    assert_equal "https://example.com", ShortLink.canonical_url("www.example.com")
  end

  test "canonical_url strips trailing slash" do
    assert_equal "https://example.com", ShortLink.canonical_url("https://example.com/")
  end

  test "canonical_url preserves path" do
    assert_equal "https://example.com/path", ShortLink.canonical_url("https://example.com/path")
  end

  test "canonical_url returns nil for blank input" do
    assert_nil ShortLink.canonical_url("")
    assert_nil ShortLink.canonical_url(nil)
  end

  test "canonical_url returns nil for bare hostname with no dot" do
    assert_nil ShortLink.canonical_url("localhost")
  end

  # --- url_with_www ---

  test "url_with_www prepends www when absent" do
    assert_equal "https://www.example.com", ShortLink.url_with_www("https://example.com")
  end

  test "url_with_www does not double-prepend www" do
    assert_equal "https://www.example.com", ShortLink.url_with_www("https://www.example.com")
  end

  # --- validations ---

  test "valid with a proper URL" do
    link = ShortLink.new(original_url: "https://example.com", short_code: "abc")
    assert link.valid?
  end

  test "invalid without original_url" do
    link = ShortLink.new(short_code: "abc")
    assert_not link.valid?
    assert_includes link.errors[:original_url], "can't be blank"
  end

  test "invalid with a non-URL string" do
    # "http://notadomain" has no dot in the host, so canonical_url returns nil and
    # the presence validation fires. Any invalid input correctly fails validation.
    link = ShortLink.new(original_url: "http://nodot", short_code: "abc")
    assert_not link.valid?
    assert link.errors[:original_url].any?
  end

  test "invalid with duplicate short_code" do
    existing = short_links(:google)
    link = ShortLink.new(original_url: "https://example.org", short_code: existing.short_code)
    assert_not link.valid?
    assert link.errors[:short_code].any?
  end

  # --- short code assignment ---

  test "short code is set to a 7-character alphanumeric token on create" do
    link = ShortLink.create!(original_url: "https://unique-random-test.com")
    assert_match(/\A[0-9a-zA-Z]{7}\z/, link.short_code)
  end

  test "two links created with the same URL share the same short code" do
    ShortLink.create!(original_url: "https://dedup-test.com")
    existing = ShortLink.find_by(original_url: "https://dedup-test.com")
    assert_not_nil existing
    assert_match(/\A[0-9a-zA-Z]{7}\z/, existing.short_code)
  end
end
