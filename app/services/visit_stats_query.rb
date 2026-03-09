# frozen_string_literal: true

# Assembles all data needed by StatsController#index in one place.
# Returns { total_clicks:, top_countries:, per_link_stats: }.
class VisitStatsQuery
  TOP_COUNTRIES_LIMIT = 10

  def self.call
    new.call
  end

  def call
    by_link = Visit.clicks_by_short_link

    {
      total_clicks: Visit.count,
      top_countries: Visit.top_countries_by_clicks(limit: TOP_COUNTRIES_LIMIT),
      per_link_stats: per_link_stats(by_link)
    }
  end

  private

  def per_link_stats(by_link)
    return [] if by_link.empty?

    short_links = ShortLink.where(id: by_link.keys).index_by(&:id)

    by_link
      .sort_by { |_, data| -data[:clicks] }
      .filter_map do |short_link_id, data|
        link = short_links[short_link_id]
        next unless link

        { short_link: link, clicks: data[:clicks], countries: data[:countries] || {} }
      end
  end
end
