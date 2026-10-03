# frozen_string_literal: true

# The landing page's content, composed for one locale.
#
# Content::Repository owns what is publishable. This owns the order a reader
# meets it in, and nothing else: every value below comes back out of the loader
# untouched, so a Markdown edit changes the page without a code change.
#
# No record type carries an explicit ordering key, so the rule is chronological
# where a record has a date, by magnitude where it has one, and by id — which is
# what the repository already returns — otherwise.
class LandingPage
  PROMINENT = 'primary'
  MONTHS_IN_YEAR = 12

  # Matches both shapes `start_date` uses: a full month (`2018-07`) and a bare
  # year (`2018`), which a record uses when the month is not worth claiming.
  YEAR_MONTH = /\A(?<year>\d{4})(?:-(?<month>\d{2}))?/

  attr_reader :repository, :locale

  def initialize(repository:, locale:)
    @repository = repository
    @locale = locale
  end

  def profile
    @profile ||= repository.site_profile(locale:)
  end

  def leadership
    @leadership ||= repository.leadership(locale:)
  end

  def metrics
    @metrics ||= of_type(:metric)
  end

  def skill_groups
    @skill_groups ||= of_type(:skill_group)
  end

  # The roles a reader should see first, newest first.
  def current_roles
    @current_roles ||= roles.select { |entry| prominent?(entry) }
  end

  # `prominence` foregrounds; it does not filter. Everything the corpus holds is
  # still on the page, just set more quietly.
  def earlier_roles
    @earlier_roles ||= roles.reject { |entry| prominent?(entry) }
  end

  def case_studies
    @case_studies ||= newest_first(of_type(:case_study)) { |record| months(record[:period]) }
  end

  def projects
    @projects ||= newest_first(of_type(:open_source)) { |record| record[:downloads].to_i }
  end

  def education
    @education ||= newest_first(of_type(:education)) { |record| record[:year].to_i }
  end

  # True when any record on the page came from a locale the reader did not ask
  # for, which is what the reader-facing notice is conditioned on.
  def substituted?
    entries.any?(&:substituted?)
  end

  # When the content behind this locale last changed, from the records rather
  # than from the clock. nil when no record carries a readable date, which the
  # two callers — the sitemap's `lastmod` and the resume's `CreationDate` — both
  # answer by omitting the field rather than by inventing one.
  def updated
    @updated ||= entries.filter_map { |entry| date(entry.record.updated) }.max
  end

  def entries
    @entries ||= [profile, leadership, *metrics, *roles, *case_studies, *projects, *skill_groups, *education].compact
  end

  private

  def of_type(type)
    repository.of_type(type, locale:)
  end

  def roles
    @roles ||= newest_first(of_type(:experience)) { |record| months(record[:start_date]) }
  end

  # Largest key first, ties broken by id so the order is stable across runs.
  def newest_first(entries)
    entries.sort_by do |entry|
      record = entry.record
      [-yield(record), record.id]
    end
  end

  def prominent?(entry)
    entry.record[:prominence] == PROMINENT
  end

  # `updated` is a required key, so a nil here means a record was hand-edited
  # into a shape the loader admits and a reader cannot use.
  def date(value)
    Date.parse(value.to_s)
  rescue Date::Error
    nil
  end

  # A single integer for a date that may or may not name a month, so that
  # `2018-07` sorts after `2018` rather than beside it as a string would.
  def months(value)
    match = YEAR_MONTH.match(value.to_s)
    return 0 unless match

    (match[:year].to_i * MONTHS_IN_YEAR) + match[:month].to_i
  end
end
