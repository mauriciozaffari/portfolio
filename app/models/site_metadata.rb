# frozen_string_literal: true

require 'forwardable'

# What the document's head says about one locale of the page, and the shared
# facts the crawler documents repeat.
#
# Every value below is selected out of the `site_profile` record and formatted;
# none is restated. That is the whole point of the class. The unfurled card in a
# LinkedIn message is frequently the only thing a reader sees, and a card that
# names a headline the page no longer claims is worse than no card at all.
#
# It is also the quieter of the two disclosure surfaces. Nothing here is visible
# in a browser window, which is exactly why a contact field added carelessly to
# the JSON-LD would survive every review that consists of looking at the page.
# spec/requests/site_metadata_spec.rb asserts the absence rather than trusting
# it.
class SiteMetadata
  extend Forwardable

  # The canonical origin, fixed rather than read from the request.
  #
  # `request.base_url` would reflect whatever host answered — a staging name, a
  # bare IP, a proxy's internal hostname — and a canonical URL that varies by
  # responder is not a canonical URL. This is the same value as `proxy.host` in
  # config/deploy.yml, and those two are the only places the origin is written
  # down.
  ORIGIN = 'https://mauricio.zaffari.casa'

  # A static file rather than a generated response: a scraper fetches it once
  # and caches it for a long time, and an unfingerprinted path is what lets that
  # cache stay valid across deploys. Built by `bin/rails site:images`; see
  # lib/tasks/site.rake for how, and why it is a build-time tool rather than a
  # runtime one.
  module Image
    IMAGE_PATH = '/og-image.png'
    IMAGE_WIDTH = 1200
    IMAGE_HEIGHT = 630
    IMAGE_TYPE = 'image/png'
  end

  include Image

  # `og:locale` takes Facebook's `language_TERRITORY` form, which has no way to
  # spell "English, no territory in particular". `en_US` is the format's own
  # default and the value every consumer recognises; it claims nothing about the
  # page that the page does not already say in its own words.
  OPEN_GRAPH_LOCALES = { 'en' => 'en_US', 'pt-BR' => 'pt_BR' }.freeze

  # `sameAs` is for pages that identify the same person. A `mailto:` is a
  # contact channel rather than a profile, and schema.org's field for one is
  # `email`, which the publication policy forbids outright. Selecting by scheme
  # keeps the address out structurally: a fifth link added to the record is
  # included or excluded by the same rule, with no name to keep in sync.
  PROFILE_SCHEMES = ['https://', 'http://'].freeze

  # A share card is truncated by whoever renders it, so the description is
  # trimmed here on a sentence boundary instead — a card that ends mid-word
  # reads as broken markup. Whole sentences from the profile's opening
  # paragraph, up to this many characters, and always at least one.
  #
  # 250 rather than the ~160 a search result shows: the consumers that truncate
  # hardest are the ones that truncate for us, and stopping at one sentence
  # would drop the named clients — the strongest thing the paragraph says — from
  # every unfurl. The profile's opening paragraph currently lands at 246.
  DESCRIPTION_BUDGET = 250

  SENTENCE_BOUNDARY = /(?<=\.)\s+/

  class << self
    def origin = ENV.fetch('SITE_ORIGIN', ORIGIN)

    def host = URI.parse(origin).host

    def image_url = "#{origin}#{Image::IMAGE_PATH}"

    def sitemap_url = url_for_path(Rails.application.routes.url_helpers.sitemap_path)

    def url_for(locale) = url_for_path(path_for(locale))

    def markdown_url_for(locale) = url_for_path(markdown_path_for(locale))

    # The routing table stays the single source of both locale paths, so a route
    # rename cannot leave the canonical URL, the sitemap and the page's own
    # language switcher disagreeing about where a locale lives.
    def path_for(locale)
      routes = Rails.application.routes.url_helpers

      locale.to_s == 'pt-BR' ? routes.portuguese_root_path : routes.root_path
    end

    def markdown_path_for(locale)
      locale.to_s == 'pt-BR' ? '/pt-BR/index.md' : '/index.md'
    end

    # Reciprocal and complete: both pages advertise both locales plus the
    # `x-default` a crawler falls back to, so neither page is the only one that
    # knows the other exists. Independent of which locale is being rendered,
    # which is why it lives here rather than on an instance.
    def alternates
      Content::Schema::LOCALES.map { |code| { hreflang: code, href: url_for(code) } } +
        [{ hreflang: 'x-default', href: url_for(Content::Schema::DEFAULT_LOCALE) }]
    end

    private

    def url_for_path(path) = "#{origin}#{path}"
  end

  attr_reader :page, :path

  # `path` names the page when it is not the locale root — /about, /privacy —
  # so the canonical URL an agent follows is the one it actually fetched.
  def initialize(page:, path: nil)
    @page = page
    @path = path
  end

  def_delegator :page, :locale
  def_delegator :'self.class', :alternates

  def profile = page.profile.record

  # The same string the page puts in its own <title>, from the same I18n key, so
  # the tab and the card cannot say different things.
  def title
    I18n.t('landing.document_title', name: profile[:name], headline: profile[:headline])
  end

  def description
    @description ||= sentences.drop(1).inject(sentences.first.to_s) do |taken, sentence|
      candidate = "#{taken} #{sentence}"
      break taken if candidate.length > DESCRIPTION_BUDGET

      candidate
    end
  end

  def image_alt
    I18n.t('metadata.image_alt', name: profile[:name], headline: profile[:headline])
  end

  def canonical_url
    klass = self.class

    path ? "#{klass.origin}#{path}" : klass.url_for(locale)
  end

  def open_graph_locale = OPEN_GRAPH_LOCALES.fetch(locale)

  def alternate_open_graph_locales
    OPEN_GRAPH_LOCALES.except(locale).values
  end

  # Only the two landing pages have a Markdown twin of their own. A prose page
  # names the site's Markdown entry point rather than claiming a twin it does
  # not have.
  def markdown_url
    klass = self.class

    path ? "#{klass.origin}/index.md" : klass.markdown_url_for(locale)
  end

  def profile_urls
    Array(profile[:links]).pluck(:url).select { |url| url.to_s.start_with?(*PROFILE_SCHEMES) }
  end

  # The JSON-LD documents. The builder lives in StructuredData::Pages::Profile,
  # which owns schema.org's vocabulary; these readers keep the page and its spec
  # speaking to SiteMetadata.
  # Forwardable is already extended for the `delegate`-style readers elsewhere
  # in this file, so the delegations use its method rather than ActiveSupport's
  # same-named one, which would otherwise be shadowed.
  def_delegators :structured_data, :person_document, :graph_document

  def structured_data = StructuredData::Pages::Profile.new(metadata: self)

  private

  # The profile's opening paragraph as plain text. Taken from the rendered and
  # sanitized body rather than from the Markdown source, so a link or an
  # emphasis added to the record later becomes words here instead of syntax.
  def opening_paragraph
    @opening_paragraph ||= Nokogiri::HTML5.fragment(profile.html).at_css('p')&.text.to_s.squish
  end

  def sentences = opening_paragraph.split(SENTENCE_BOUNDARY)
end
