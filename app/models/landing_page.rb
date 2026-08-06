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
  PROMINENT = "primary".freeze
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
    @profile ||= repository.site_profile(locale: locale)
  end

  def leadership
    @leadership ||= repository.leadership(locale: locale)
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
    @case_studies ||= of_type(:case_study).sort_by { |entry| [ -months(entry.record[:period]), entry.record.id ] }
  end

  def projects
    @projects ||= of_type(:open_source).sort_by { |entry| [ -entry.record[:downloads].to_i, entry.record.id ] }
  end

  def education
    @education ||= of_type(:education).sort_by { |entry| [ -entry.record[:year].to_i, entry.record.id ] }
  end

  # True when any record on the page came from a locale the reader did not ask
  # for, which is what the reader-facing notice is conditioned on.
  def substituted?
    entries.any?(&:substituted?)
  end

  def entries
    @entries ||= [ profile, leadership, *metrics, *roles, *case_studies, *projects, *skill_groups, *education ].compact
  end

  private
    def of_type(type)
      repository.of_type(type, locale: locale)
    end

    def roles
      @roles ||= of_type(:experience).sort_by { |entry| [ -months(entry.record[:start_date]), entry.record.id ] }
    end

    def prominent?(entry)
      entry.record[:prominence] == PROMINENT
    end

    # A single integer for a date that may or may not name a month, so that
    # `2018-07` sorts after `2018` rather than beside it as a string would.
    def months(value)
      match = YEAR_MONTH.match(value.to_s)
      return 0 if match.nil?

      match[:year].to_i * MONTHS_IN_YEAR + match[:month].to_i
    end
end
