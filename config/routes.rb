# frozen_string_literal: true

Rails.application.routes.draw do
  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get 'up' => 'rails/health#show', as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # One canonical, static URL per locale — a path prefix rather than a
  # subdomain or content negotiation, so site-metadata has something stable to
  # point hreflang at. Both are `landing#show`; the locale arrives as a route
  # default, which wins over the query string, so `/?locale=pt-BR` cannot serve
  # Portuguese from the English URL.
  root 'landing#show', defaults: { locale: 'en' }
  get 'pt-BR' => 'landing#show', as: :portuguese_root, defaults: { locale: 'pt-BR' }

  # Served by the application rather than dropped into public/: both documents
  # restate values that live in the content records, and a static copy is a
  # second source that drifts silently.
  #
  # `format: false` drops the `(.:format)` segment, so the dot in each name is a
  # literal — `/robots.txt.json` is a 404, and the path helper cannot generate
  # `/sitemap.xml.xml`.
  get 'robots.txt' => 'site_metadata#robots', as: :robots, format: false
  get 'sitemap.xml' => 'site_metadata#sitemap', as: :sitemap, format: false

  # One resume per locale, alongside the page it is built from. Generated on
  # request from the same records — nothing is written to disk, because the
  # container is stateless and has no writable persistence.
  #
  # The `.pdf` is a literal, as above: `format: false` means `/resume.pdf.json`
  # is a 404 rather than a second URL for the same document.
  get 'resume.pdf' => 'resume#show', as: :resume, format: false, defaults: { locale: 'en' }
  get 'pt-BR/resume.pdf' => 'resume#show', as: :portuguese_resume, format: false, defaults: { locale: 'pt-BR' }
end
