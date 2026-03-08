Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check
  root "short_links#index"

  resources :short_links, only: [:index, :show, :create], path: "links"
  get "r/:short_code", to: "short_links#redirect", as: :short_link_redirect
  get "stats", to: "stats#index", as: :stats
end
