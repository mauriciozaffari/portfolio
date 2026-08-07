# Locale handling for controllers that render a locale-aware representation of
# the same records — the page, the resume PDF, and the assistant.
#
# The duplication this removes was locale handling rather than format handling,
# which is why the controllers stay separate: `ResumeController` deliberately
# omits `allow_browser`, and a shared controller would have to reintroduce that
# gate behind a conditional. See the comment on that controller.
#
# `around_action` is registered at include time, so `include Localized` belongs
# at the top of a controller: any filter that renders — a rate limiter, say —
# must run inside the locale scope, or its response is built in whatever locale
# the previous request left behind.
module Localized
  extend ActiveSupport::Concern

  included do
    around_action :with_locale
  end

  private
    # Not user input, and so deliberately not validated: every locale-aware route
    # is static and supplies `locale` as a default, and Rails merges path
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
