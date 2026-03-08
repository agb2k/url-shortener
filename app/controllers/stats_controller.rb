# frozen_string_literal: true

class StatsController < ApplicationController
  def index
    @total_clicks = Visit.count
    @top_countries = Visit.top_countries_by_clicks(limit: 10)

    by_link = Visit.clicks_by_short_link
    return @per_link_stats = [] if by_link.empty?

    short_links = ShortLink.where(id: by_link.keys).index_by(&:id)
    @per_link_stats = by_link.sort_by { |_, data| -data[:clicks] }.map do |short_link_id, data|
      {
        short_link: short_links[short_link_id],
        clicks: data[:clicks],
        countries: data[:countries] || {}
      }
    end
    @per_link_stats.select! { |row| row[:short_link].present? }
  end
end
