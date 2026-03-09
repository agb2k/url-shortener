# frozen_string_literal: true

class ShortLinksController < ApplicationController
  RATE_LIMIT_SCOPE = "short_links:create"
  CREATE_RATE_LIMIT = 10
  CREATE_RATE_PERIOD = 1.minute

  before_action :rate_limit_creation, only: [:create]

  def index
    @short_link = ShortLink.new
  end

  def show
    @short_link = ShortLink.find_by!(short_code: params[:id])
    @presenter  = ShortLinkPresenter.new(@short_link, helpers)
  end

  def create
    link = ShortLink.new(
      original_url: params.dig(:short_link, :original_url).presence || params[:original_url]
    )
    unless link.valid?
      respond_to do |format|
        format.html { @short_link = link; render :index, status: :unprocessable_entity }
        format.json { render json: { errors: link.errors.full_messages }, status: :unprocessable_entity }
      end
      return
    end

    existing = ShortLink.find_by(original_url: link.original_url)
    if existing
      respond_to do |format|
        format.html { redirect_to short_link_path(existing), notice: "This URL was already shortened." }
        format.json { render json: { short_code: existing.short_code, redirect_url: short_link_redirect_url(existing.short_code, helpers.short_url_display_options) }, status: :ok }
      end
      return
    end

    if link.save
      link.reload
      ScrapeTitleJob.perform_later(link.id)
      respond_to do |format|
        format.html { redirect_to short_link_path(link), notice: "Short link created." }
        format.json { render json: { short_code: link.short_code, redirect_url: short_link_redirect_url(link.short_code, helpers.short_url_display_options) }, status: :created }
      end
    else
      respond_to do |format|
        format.html { @short_link = link; render :index, status: :unprocessable_entity }
        format.json { render json: { errors: link.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def redirect
    payload = ShortLinkRedirectResolver.resolve(params[:short_code])
    unless payload
      head :not_found
      return
    end

    LogVisitJob.perform_later(
      payload[:short_link_id],
      request.remote_ip.to_s,
      request.user_agent.to_s
    )

    redirect_to payload[:original_url], status: :found, allow_other_host: true
  end

  private

  def rate_limit_creation
    return unless RateLimiter.exceeded?(
      RATE_LIMIT_SCOPE,
      request.remote_ip.to_s,
      limit: CREATE_RATE_LIMIT,
      period: CREATE_RATE_PERIOD
    )

    response.set_header("Retry-After", CREATE_RATE_PERIOD.to_i.to_s)
    respond_to do |format|
      format.html { head :too_many_requests }
      format.json { render json: { error: "Too many requests" }, status: :too_many_requests }
    end
  end
end
