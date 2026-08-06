class ApplicationController < ActionController::Base
  # `allow_browser` is deliberately *not* here, where the Rails generator put
  # it. It gates on the User-Agent, and robots.txt and sitemap.xml have no
  # rendering contract to protect: a crawler sending an old browser's UA string
  # — which several do, to look innocuous — was being told this site has no
  # sitemap. Verified: Chrome 49 got 406 from both. The gate now lives on
  # LandingController, which is the only thing here that renders a page.

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes
end
