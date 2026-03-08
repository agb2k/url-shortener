# frozen_string_literal: true

# Analytics (ClickHouse) stores high-volume, append-only event data (e.g. visits) for
# reporting and aggregations; optimized for analytical queries, not transactional updates.
class AnalyticsRecord < ActiveRecord::Base
  self.abstract_class = true

  connects_to database: { writing: :analytics, reading: :analytics }
end
