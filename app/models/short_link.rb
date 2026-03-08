# frozen_string_literal: true

# short_code is a temporary placeholder until after_create replaces it with Base62(id).
class ShortLink < ApplicationRecord
  PENDING_SHORT_CODE_PREFIX = "pending_"

  before_validation :normalize_original_url
  validates :original_url, presence: true
  validate :original_url_must_be_valid
  validates :short_code, presence: true, uniqueness: true

  after_create :assign_short_code_from_id, if: :pending_short_code?

  def to_param
    short_code
  end

  # Display form: full URL with www. (e.g. https://www.yahoo.com).
  def original_url_for_display
    self.class.url_with_www(original_url)
  end

  # Full form for display: ensure host has www. (e.g. https://www.yahoo.com).
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

  def pending_short_code?
    short_code.to_s.start_with?(PENDING_SHORT_CODE_PREFIX)
  end

  def assign_short_code_from_id
    update_column(:short_code, Base62Encoder.encode(id))
  end
end
