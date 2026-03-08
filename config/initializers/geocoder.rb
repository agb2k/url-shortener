# frozen_string_literal: true

# ip-api.com free tier (no key; 45 req/min). For Pro/HTTPS set GEOCODER_API_KEY.
Geocoder.configure(ip_lookup: :ipapi_com, timeout: 5, use_https: false)
