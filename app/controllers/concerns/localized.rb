# frozen_string_literal: true

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

  # Not user input, and so deliberately not validated. The two page routes
  # supply `locale` as a route default, which wins over the query string, so
  # `/?locale=pt-BR` cannot switch the English URL. The API routes supply no
  # default, because there the query string is the intended way to ask, so a
  # request without one falls back to the default locale. A spec holds both
  # behaviours down.
  def locale
    params[:locale].presence || Content::Schema::DEFAULT_LOCALE
  end

  # Scoped rather than assigned, so a request cannot leave the process on a
  # locale the next one did not ask for.
  def with_locale(&)
    I18n.with_locale(locale, &)
  end
end
