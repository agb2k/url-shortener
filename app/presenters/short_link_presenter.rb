# frozen_string_literal: true

# Centralises all display logic for a ShortLink, keeping views and models free of presentation concerns.
class ShortLinkPresenter
  delegate :id, :short_code, :title, to: :@short_link

  def initialize(short_link, helpers)
    @short_link = short_link
    @helpers    = helpers
  end

  # Full short URL (e.g. https://short.example.com/r/1a2b).
  def display_url
    @helpers.short_link_display_url(@short_link.short_code)
  end

  # Original URL with www. prefix, for display purposes.
  def display_original_url
    @short_link.original_url_for_display
  end

  # Original URL stripped of its scheme prefix (e.g. "www.youtube.com/watch?v=...").
  def bare_original_url
    @short_link.original_url.sub(/\Ahttps?:\/\//, "")
  end

  def title_or_placeholder
    @short_link.title.presence || "—"
  end

  # Path for the redirect endpoint (used as the href target for the short link).
  def redirect_path
    @helpers.short_link_redirect_path(@short_link.short_code)
  end
end
