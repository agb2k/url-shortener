# frozen_string_literal: true

# We label private/loopback IPs as "Local" and skip the geocoding API (no country for localhost).
class LogVisitJob < ApplicationJob
  queue_as :default

  def perform(short_link_id, ip_address, user_agent)
    country = resolve_country(ip_address)

    Visit.create!(
      short_link_id: short_link_id,
      ip_address: ip_address.to_s,
      country: country,
      user_agent: user_agent.to_s,
      created_at: Time.current
    )
  end

  private

  def resolve_country(ip_address)
    return "Local" if private_or_loopback_ip?(ip_address.to_s)

    results = Geocoder.search(ip_address)
    result = results&.first
    result&.country_code.presence || result&.country.presence || "unknown"
  end

  def private_or_loopback_ip?(ip)
    return true if ip.blank?
    return true if ip == "127.0.0.1" || ip == "::1"

    addr = IPAddr.new(ip)
    addr.loopback? || addr.private?
  rescue ArgumentError
    false
  end
end
