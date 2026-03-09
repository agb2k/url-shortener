# frozen_string_literal: true

class ShortLink < ApplicationRecord
  before_validation :normalize_original_url
  before_validation :assign_random_short_code, if: -> { short_code.blank? }
  validates :original_url, presence: true
  validate :original_url_must_be_valid
  validate :original_url_must_not_be_self_referential
  validates :short_code, presence: true, uniqueness: true

  def to_param
    short_code
  end

  def original_url_for_display
    self.class.url_with_www(original_url)
  end

  # Adds www. to the host when absent (e.g. https://example.com → https://www.example.com).
  def self.url_with_www(url)
    return url if url.blank?

    uri = URI.parse(url)
    return url unless uri.is_a?(URI::HTTP) && uri.host.present?

    uri.host = uri.host.start_with?("www.") ? uri.host : "www.#{uri.host}"
    uri.to_s
  rescue URI::InvalidURIError
    url
  end

  # Canonical form so google.com, www.google.com, https://www.google.com all match.
  def self.canonical_url(url)
    return nil if url.blank?

    u = url.to_s.strip
    u = "https://#{u}" unless u.match?(%r{\Ahttps?://}i)
    uri = URI.parse(u)
    return nil unless uri.is_a?(URI::HTTP) && uri.host.present?

    host = uri.host.downcase.sub(/\Awww\./, "")
    return nil unless host.include?(".")

    path = (uri.path.presence || "").chomp("/")
    uri.host = host
    uri.path = path.presence || ""  # no trailing slash for root (e.g. https://yahoo.com)
    uri.fragment = nil
    uri.to_s
  rescue URI::InvalidURIError
    nil
  end

  private

  def normalize_original_url
    return if original_url.blank?

    self.original_url = self.class.canonical_url(original_url)
  end

  def original_url_must_be_valid
    return if original_url.blank?

    uri = URI.parse(original_url)
    host = uri.host.to_s
    valid = uri.is_a?(URI::HTTP) && host.present? && host.include?(".")
    errors.add(:original_url, "is not a valid URL") unless valid
  rescue URI::InvalidURIError
    errors.add(:original_url, "is not a valid URL")
  end

  def original_url_must_not_be_self_referential
    return if original_url.blank?

    base = ENV["SHORT_URL_BASE"].presence
    return unless base

    own_host = URI.parse(base).host.to_s.downcase
    url_host = URI.parse(original_url).host.to_s.downcase
    errors.add(:original_url, "cannot be a link to this URL shortener") if url_host == own_host
  rescue URI::InvalidURIError
    nil
  end

  def assign_random_short_code
    loop do
      self.short_code = SecureRandom.alphanumeric(7)
      break unless self.class.exists?(short_code: short_code)
    end
  end
end
