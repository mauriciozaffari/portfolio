# frozen_string_literal: true

require 'forwardable'

# The downloadable resume for one locale.
#
# A PDF is the least retractable thing this site publishes. A page can be
# corrected; a file that has been fetched circulates uncorrected forever, which
# is why the disclosure rules are applied here twice — once to the words, and
# once to the document information dictionary, which no reader ever looks at and
# every PDF tool reads.
#
# The content is LandingPage's, unchanged. See Resume::Document for what that
# buys and features/resume-download/SPEC.md for the trade it accepts.
class Resume
  extend Forwardable

  MEDIA_TYPE = 'application/pdf'

  # A contact address as a reader should see it: no scheme, no `mailto:`, no
  # `www.`, no trailing slash. The resume shows the addresses themselves rather
  # than labelled links, because a hyperlink reading "LinkedIn" loses its own
  # destination the moment the file is printed.
  SCHEME = %r{\A(?:https?://|mailto:)}
  SUBDOMAIN = /\Awww\./

  class << self
    def path_for(locale)
      routes = Rails.application.routes.url_helpers

      locale.to_s == 'pt-BR' ? routes.portuguese_resume_path : routes.resume_path
    end

    def url_for(locale) = "#{SiteMetadata::ORIGIN}#{path_for(locale)}"

    def display_address(url)
      url.to_s.sub(SCHEME, '').sub(SUBDOMAIN, '').chomp('/')
    end
  end

  attr_reader :page

  def initialize(page:)
    @page = page
  end

  def_delegator :page, :locale

  def profile = page.profile.record

  # `<name>-resume.pdf`, or its Portuguese counterpart. The stem comes from the
  # record and the noun from the locale file, so the file a recruiter saves is
  # named after the person rather than after the route that served it.
  def filename
    "#{profile[:name].to_s.parameterize}-#{I18n.t('resume.filename')}.pdf"
  end

  # The document information dictionary, set in full rather than left to
  # defaults. Prawn stamps `Creator` and `Producer` with its own name; both are
  # replaced by the canonical host, which says where the file came from and
  # discloses no tool version and no filesystem path.
  #
  # The dates are the corpus's own `updated`, not the clock. Generating on
  # request means a clock would stamp a different document every time the same
  # unchanged content was downloaded, and would disclose the server's timezone
  # for nothing. UTC for the same reason.
  #
  # Deliberately absent: `Keywords`, which would be a second home for the skill
  # records, and any custom key. What is here is the six fields every reader
  # displays, and nothing outside the allowlist can reach them — `Author` and
  # `Subject` come from the `site_profile` record, which the content-safety
  # scanner already gates.
  def info
    person = profile
    name = person[:name]
    headline = person[:headline]
    host = SiteMetadata.host

    {
      Title: I18n.t('landing.document_title', name:, headline:),
      Author: name,
      Subject: headline,
      Creator: host,
      Producer: host
    }.merge(dates)
  end

  def pdf
    @pdf ||= Document.new(page:, info:).render
  end

  private

  # Absent rather than invented when no record carries a readable date, on
  # the same reasoning as Sitemap's `lastmod`: a missing field beats a field
  # holding a value that is not a date.
  def dates
    date = page.updated
    return {} unless date

    stamp = Time.utc(date.year, date.month, date.day)

    { CreationDate: stamp, ModDate: stamp }
  end
end
