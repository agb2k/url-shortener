# frozen_string_literal: true

class StatsController < ApplicationController
  def index
    result = VisitStatsQuery.call
    @total_clicks   = result[:total_clicks]
    @top_countries  = result[:top_countries]
    @per_link_stats = result[:per_link_stats]
  end
end
