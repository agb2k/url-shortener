# frozen_string_literal: true

require "test_helper"

class StatsControllerTest < ActionDispatch::IntegrationTest
  test "index renders successfully" do
    get stats_path
    assert_response :ok
  end
end
