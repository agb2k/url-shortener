# frozen_string_literal: true

require "open-uri"

class ScrapeTitleJob < ApplicationJob
  queue_as :default
  set timeout: 15

  discard_on StandardError

  def perform(short_link_id)
    short_link = ShortLink.find_by(id: short_link_id)
    return unless short_link

    html = URI.open(short_link.original_url, read_timeout: 8, open_timeout: 4).read
    title = Nokogiri::HTML(html).at_css("title")&.text&.strip
    return if title.blank?

    short_link.update!(title: title)
    # Broadcast so any open index page gets the new title via Turbo Stream.
    Turbo::StreamsChannel.broadcast_update_to(
      short_link,
      target: "short_link_#{short_link.id}_title",
      html: ERB::Util.html_escape(short_link.title)
    )
  end
end
