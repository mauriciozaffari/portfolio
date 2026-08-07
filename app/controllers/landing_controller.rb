class LandingController < ApplicationController
  include Localized

  # Only allow modern browsers supporting webp images, web push, badges, import
  # maps, CSS nesting, and CSS :has. Scoped to the page rather than to every
  # controller: see app/controllers/application_controller.rb.
  allow_browser versions: :modern

  def show
    @page = LandingPage.new(repository: Content.repository, locale: locale)
    @metadata = SiteMetadata.new(page: @page)
  end
end
