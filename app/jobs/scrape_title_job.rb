# frozen_string_literal: true

require "open-uri"

class ScrapeTitleJob < ApplicationJob
  ALLOWED_SCHEMES = %w[http https].freeze
  TITLE_MAX_LENGTH = 255

  queue_as :default
  set timeout: 15

  discard_on StandardError

  def perform(short_link_id)
    short_link = ShortLink.find_by(id: short_link_id)
    return unless short_link

    # Only fetch http/https URLs; reject file://, ftp://, etc. to prevent SSRF via other schemes.
    scheme = URI.parse(short_link.original_url).scheme.to_s.downcase
    return unless ALLOWED_SCHEMES.include?(scheme)

    html = URI.open(short_link.original_url, read_timeout: 8, open_timeout: 4).read
    title = Nokogiri::HTML(html).at_css("title")&.text&.strip&.truncate(TITLE_MAX_LENGTH)
    return if title.blank?

    short_link.update!(title: title)
    # Target ID matches the element rendered in show.html.erb for live title updates.
    Turbo::StreamsChannel.broadcast_update_to(
      short_link,
      target: "short_link_#{short_link.id}_title",
      html: ERB::Util.html_escape(short_link.title)
    )
  end
end
