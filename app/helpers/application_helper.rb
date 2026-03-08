module ApplicationHelper
  # Set SHORT_URL_BASE (e.g. https://go.example.com) for bit.ly-style short links; otherwise uses request host.
  def short_url_display_options
    base = ENV["SHORT_URL_BASE"].presence
    if base
      uri = URI.parse(base)
      opts = { host: uri.host, protocol: uri.scheme }
      opts[:port] = uri.port if uri.port && uri.port != 80 && uri.port != 443
      opts
    else
      opts = { host: request.host, protocol: request.scheme }
      opts[:port] = request.port if request.port != 80 && request.port != 443
      opts
    end
  end

  def short_link_display_url(short_code)
    short_link_redirect_url(short_code, short_url_display_options)
  end
end
