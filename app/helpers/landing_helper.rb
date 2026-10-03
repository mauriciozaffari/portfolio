# frozen_string_literal: true

module LandingHelper
  # An en dash with spaces around it. A bare hyphen between two four-digit years
  # is indistinguishable from a Brazilian landline, and Content::SafetyScanner is
  # right to refuse it — see features/curated-content/IMPLEMENTATION.md.
  RANGE_SEPARATOR = ' – '

  # A `start_date` or `end_date` that names a month. A record omits the month
  # when it is not worth claiming, and the page does not invent one.
  MONTH = /\A(?<year>\d{4})-(?<month>\d{2})\z/

  # The in-page anchors, in narrative order. Every id here is asserted against a
  # real element by spec/requests/landing_spec.rb, so a rename cannot leave the
  # navigation pointing at nothing.
  #
  # Every label is chrome, including the leadership one, which is deliberately
  # not the `leadership` record's `title`. An index entry cannot carry a
  # substitution marker, so a record-derived label put an unexplained English
  # heading in the middle of a Portuguese navigation and read as a bug rather
  # than as the fallback. The section's own `<h2>` still renders the record's
  # title, substituted and marked — that is content, and it may legitimately
  # arrive in another language.
  def landing_sections
    [
      ['impact', t('landing.impact.heading')],
      ['experience', t('landing.experience.heading')],
      ['work', t('landing.work.heading')],
      ['leadership', t('landing.leadership.heading')],
      ['projects', t('landing.projects.heading')],
      ['skills', t('landing.skills.heading')],
      ['contact', t('landing.contact.heading')]
    ]
  end

  # One canonical URL per locale, so the switcher and site-metadata agree.
  def locale_switcher(current_locale)
    Content::Schema::LOCALES.map do |code|
      {
        locale: code,
        label: t("landing.languages.switch.#{code}"),
        path: locale_path(code),
        current: code == current_locale
      }
    end
  end

  def locale_path(locale)
    SiteMetadata.path_for(locale)
  end

  # Not `resume_path`, which is the routing table's own helper for the English
  # document. This one picks the locale, the way `locale_path` does above.
  def resume_path_for(locale)
    Resume.path_for(locale)
  end

  def calendar_month(value)
    text = value.to_s
    match = MONTH.match(text)
    return text unless match

    l(Date.new(match[:year].to_i, match[:month].to_i, 1), format: :month_year)
  end

  # An open-ended role reads "… – present". A role that began and ended inside
  # one undated year reads as that year alone, not "2016 – 2016".
  def role_period(record)
    start = calendar_month(record[:start_date])
    finish = role_end(record[:end_date])
    return start if start == finish

    [start, finish].join(RANGE_SEPARATOR)
  end

  def role_end(end_date)
    return t('landing.experience.present') if end_date.blank?

    calendar_month(end_date)
  end

  def content_date(value)
    l(Date.parse(value.to_s), format: :day_month_year)
  end

  # A substituted record's container needs the language the reader is actually
  # getting, so a screen reader switches voice instead of mispronouncing the
  # text, plus a hook the specs can assert. An unsubstituted one needs neither:
  # a redundant `lang` on every container of an untranslated page says nothing,
  # and an empty one would be worse than none.
  #
  # Returned as attributes for a `tag` builder rather than as a string, because
  # `herb analyze` rejects an ERB tag in attribute position and is right to.
  def substitution_attributes(localized)
    return {} unless localized&.substituted?

    { lang: localized.language, data: { substituted: true } }
  end
end
