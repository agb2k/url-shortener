# frozen_string_literal: true

class Visit < AnalyticsRecord
  self.table_name = "visits"

  def self.top_countries_by_clicks(limit: 10)
    group(:country).count.sort_by { |_, count| -count }.first(limit)
  end

  # Returns { short_link_id => { clicks: N, countries: { "US" => 2, ... } } } for all links with visits.
  def self.clicks_by_short_link
    clicks = group(:short_link_id).count
    by_link_and_country = group(:short_link_id, :country).count

    countries_by_link = {}
    by_link_and_country.each do |(short_link_id, country), count|
      countries_by_link[short_link_id] ||= {}
      key = country.presence || "unknown"
      countries_by_link[short_link_id][key] = count
    end

    clicks.keys.index_with do |sid|
      { clicks: clicks[sid], countries: countries_by_link[sid] || {} }
    end
  end
end
