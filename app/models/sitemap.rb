# The two canonical URLs and when the content behind each of them last changed.
#
# `lastmod` is derived from the records the page actually renders, never from
# the clock. Build time would mark every URL as modified on every deploy, which
# trains a crawler to ignore the field — the one thing a sitemap is for.
class Sitemap
  Entry = Data.define(:url, :last_modified)

  attr_reader :repository

  def initialize(repository:)
    @repository = repository
  end

  def entries
    @entries ||= Content::Schema::LOCALES.map do |locale|
      Entry.new(url: SiteMetadata.url_for(locale), last_modified: last_modified(page_for(locale)))
    end
  end

  private
    # LandingPage rather than the repository directly, so "the content behind
    # this URL" means the same set of records here as it does in the browser —
    # including the locale fallback, which is why /pt-BR currently reports the
    # English records' dates rather than nothing at all.
    def page_for(locale) = LandingPage.new(repository: repository, locale: locale)

    def last_modified(page)
      page.entries.filter_map { |entry| date(entry.record.updated) }.max
    end

    # `updated` is a required key, so a nil here means a record was hand-edited
    # into a shape the loader admits and a crawler cannot read. Omitting the
    # element beats publishing a date that is not one.
    def date(value)
      Date.parse(value.to_s)
    rescue Date::Error
      nil
    end
end
