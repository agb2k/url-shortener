# frozen_string_literal: true

require "test_helper"

class VisitTest < ActiveSupport::TestCase
  # ClickHouse MergeTree tables do not support DELETE, so rows inserted in previous
  # test runs persist. We use IDs derived from the current timestamp to stay isolated,
  # and assert relative/proportional values rather than exact counts.

  setup do
    @link_id_a = SecureRandom.random_number(1_000_000_000..9_999_999_999)
    @link_id_b = SecureRandom.random_number(1_000_000_000..9_999_999_999)

    Visit.insert_all!([
      { short_link_id: @link_id_a, created_at: Time.current, country: "US" },
      { short_link_id: @link_id_a, created_at: Time.current, country: "US" },
      { short_link_id: @link_id_a, created_at: Time.current, country: "AU" },
      { short_link_id: @link_id_b, created_at: Time.current, country: "GB" }
    ])
  end

  test "clicks_by_short_link returns click count per link" do
    result = Visit.clicks_by_short_link
    assert_equal 3, result[@link_id_a][:clicks]
    assert_equal 1, result[@link_id_b][:clicks]
  end

  test "clicks_by_short_link groups countries correctly" do
    result = Visit.clicks_by_short_link
    countries = result[@link_id_a][:countries]
    # US should have twice as many clicks as AU for this link
    assert countries["US"] > countries["AU"],
           "Expected US (#{countries["US"]}) > AU (#{countries["AU"]})"
  end

  test "top_countries_by_clicks orders by count descending" do
    top = Visit.top_countries_by_clicks(limit: 10)
    counts = top.map(&:last)
    assert_equal counts.sort.reverse, counts
  end
end
