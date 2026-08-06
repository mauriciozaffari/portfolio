class LandingController < ApplicationController
  # Only allow modern browsers supporting webp images, web push, badges, import
  # maps, CSS nesting, and CSS :has. Scoped to the page rather than to every
  # controller: see app/controllers/application_controller.rb.
  allow_browser versions: :modern

  around_action :with_locale

  def show
    @page = LandingPage.new(repository: Content.repository, locale: locale)
    @metadata = SiteMetadata.new(page: @page)
  end

  private
    # Not user input, and so deliberately not validated: both locale URLs are
    # static routes that supply `locale` as a default, and Rails merges path
    # parameters over the query string, so `/?locale=pt-BR` cannot reach here.
    # A spec holds that behaviour down.
    def locale
      params[:locale]
    end

    # Scoped rather than assigned, so a request cannot leave the process on a
    # locale the next one did not ask for.
    def with_locale
      I18n.with_locale(locale) { yield }
    end
end
