Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # One canonical, static URL per locale — a path prefix rather than a
  # subdomain or content negotiation, so site-metadata has something stable to
  # point hreflang at. Both are `landing#show`; the locale arrives as a route
  # default, which wins over the query string, so `/?locale=pt-BR` cannot serve
  # Portuguese from the English URL.
  root "landing#show", defaults: { locale: "en" }
  get "pt-BR" => "landing#show", as: :portuguese_root, defaults: { locale: "pt-BR" }
end
