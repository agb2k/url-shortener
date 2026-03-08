class ApplicationController < ActionController::Base
  allow_browser versions: :modern # Require modern browsers (webp, import maps, etc.).
  stale_when_importmap_changes     # Invalidate HTML when importmap changes.
end
