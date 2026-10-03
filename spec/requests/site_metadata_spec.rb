# frozen_string_literal: true

require 'rails_helper'

# Driven against the real corpus, like the landing page spec, because what is
# being asserted is what ships. The metadata layer is the quieter of this site's
# two public surfaces: none of it is visible in a browser window, so a contact
# field added here would survive every review that consists of looking at the
# page.
RSpec.describe 'Site metadata' do
  # schema.org's contact and identity vocabulary, which is what a helpful edit
  # reaches for. None of it is on the four-entry allowlist in
  # features/curated-content/SPEC.md, and JSON-LD is exactly where a stray
  # `telephone` would go unnoticed.
  let(:forbidden_fields) do
    %w[
      telephone faxNumber email contactPoint
      address streetAddress postalCode addressLocality addressRegion addressCountry
      homeLocation workLocation birthDate birthPlace nationality
      taxID vatID duns globalLocationNumber
    ]
  end

  let(:person_fields) { %w[@context @type @id name jobTitle url sameAs] }

  let(:document) { response.parsed_body }

  def profile(locale) = Content.repository.site_profile(locale:).record

  def property(name) = document.css("meta[property='#{name}']").map { |node| node['content'] }

  def named(name) = document.at_css("meta[name='#{name}']")&.[]('content')

  def json_ld = JSON.parse(document.at_css("script[type='application/ld+json']").text)

  def alternates
    document.css("link[rel='alternate']").to_h { |node| [node['hreflang'], node['href']] }
  end

  # Every absolute URL any record publishes, so the allowlist below is derived
  # from the corpus rather than transcribed from it.
  def record_urls
    Content.repository.renderable.flat_map do |record|
      [record[:url], *Array(record[:links]).map { |link| link[:url] }]
    end.compact
  end

  shared_examples 'a page that describes itself' do |locale|
    it 'names one absolute canonical URL, built from the fixed origin' do
      expect(document.at_css("link[rel='canonical']")['href']).to eq(SiteMetadata.url_for(locale))
      expect(document.css("link[rel='canonical']").size).to eq(1)
    end

    it 'advertises both locales and an x-default, reciprocally' do
      expect(alternates).to eq(
        'en' => 'https://zaffari.casa/',
        'pt-BR' => 'https://zaffari.casa/pt-BR',
        'x-default' => 'https://zaffari.casa/'
      )
    end

    it 'unfurls with the title, description and URL the page itself carries' do
      expect(property('og:title')).to eq([document.at_css('title').text])
      expect(property('og:url')).to eq([SiteMetadata.url_for(locale)])
      expect(property('og:type')).to eq(['profile'])
      expect(property('og:description').first).to eq(named('description'))
      expect(named('description')).to be_present
    end

    it 'declares the locale it is in and the one it is not' do
      expect(property('og:locale')).to eq([SiteMetadata::OPEN_GRAPH_LOCALES.fetch(locale)])
      expect(property('og:locale:alternate'))
        .to match_array(SiteMetadata::OPEN_GRAPH_LOCALES.except(locale).values)
    end

    it 'offers a large card whose image is described for a reader who cannot see it' do
      expect(named('twitter:card')).to eq('summary_large_image')
      expect(named('twitter:image')).to eq(SiteMetadata.image_url)
      expect(property('og:image')).to eq([SiteMetadata.image_url])
      expect(named('twitter:image:alt')).to be_present
      expect(property('og:image:alt').first).to eq(named('twitter:image:alt'))
    end

    it 'names an image that exists, at the size it claims' do
      file = Rails.public_path.join(SiteMetadata::IMAGE_PATH.delete_prefix('/'))

      expect(file).to exist
      expect(file.binread(24).unpack('@16N2'))
        .to eq([SiteMetadata::IMAGE_WIDTH, SiteMetadata::IMAGE_HEIGHT])
    end

    it 'describes the person entirely from the record' do
      expect(json_ld).to include(
        '@type' => 'Person',
        'name' => profile(locale)[:name],
        'jobTitle' => profile(locale)[:headline],
        'url' => SiteMetadata.url_for(locale)
      )
      expect(json_ld['sameAs']).to eq(profile(locale)[:links].pluck(:url).grep(%r{\Ahttps?://}))
    end

    it 'carries no contact field outside the four-entry allowlist' do
      expect(json_ld.keys).to match_array(person_fields)

      forbidden_fields.each do |field|
        expect(json_ld.to_json).not_to match(/"#{field}"/i), "JSON-LD publishes a #{field}"
      end
    end

    it 'publishes no direct address anywhere in the head' do
      head = document.at_css('head').to_s

      expect(head).not_to include('mailto:')
      expect(head).not_to include('tel:')
      expect(Content::SafetyScanner.new.scan_html(head, source: 'head').map(&:to_s)).to be_empty
    end

    it 'references no origin but its own, the approved profile links, and the schema vocabulary' do
      allowed = [SiteMetadata.origin, 'https://schema.org'] + record_urls
      found = response.body.scan(%r{https?://[^"'\s<>]+})

      expect(found).not_to be_empty
      expect(found.reject { |url| allowed.any? { |prefix| url.start_with?(prefix) } }).to be_empty
    end
  end

  describe 'GET /' do
    before { get root_path }

    it_behaves_like 'a page that describes itself', 'en'
  end

  describe 'GET /pt-BR' do
    before { get portuguese_root_path }

    it_behaves_like 'a page that describes itself', 'pt-BR'

    it 'describes itself in the language it is serving' do
      get root_path
      english = response.parsed_body.at_css("meta[name='twitter:image:alt']")['content']

      get portuguese_root_path

      expect(named('twitter:image:alt')).not_to eq(english)
    end
  end

  describe 'GET /robots.txt' do
    before { get robots_path }

    it 'is served by the application as plain text' do
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/plain')
    end

    it 'allows every crawler, with the health check as the only exclusion' do
      expect(response.body).to match(/^User-agent: \*$/)
      expect(response.body).to match(%r{^Allow: /$})
      expect(response.body.scan(/^Disallow: (.+)$/).flatten).to contain_exactly('/up')
    end

    # The SPEC asks for a deliberate policy rather than an inherited default,
    # and a decision nobody wrote down is indistinguishable from an oversight.
    it 'records the AI crawler decision in the file a reader will look in' do
      expect(response.body).to match(/^#.*AI and LLM crawlers are allowed/)
    end

    it 'points a crawler at the sitemap, absolutely' do
      expect(response.body).to match(/^Sitemap: #{Regexp.escape(SiteMetadata.sitemap_url)}$/)
    end

    it 'publishes nothing unpublishable' do
      expect(Content::SafetyScanner.new.scan(response.body, source: '/robots.txt').map(&:to_s)).to be_empty
    end
  end

  describe 'GET /sitemap.xml' do
    before { get sitemap_path }

    let(:sitemap) { Nokogiri::XML(response.body, &:strict) }

    it 'is served by the application as XML' do
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/xml')
    end

    it 'parses strictly' do
      expect { sitemap }.not_to raise_error
      expect(sitemap.errors).to be_empty
      expect(sitemap.root.name).to eq('urlset')
    end

    it 'covers both locales at their canonical URLs' do
      expect(sitemap.css('url loc').map(&:text))
        .to eq(Content::Schema::LOCALES.map { |locale| SiteMetadata.url_for(locale) })
    end

    it 'dates every URL from the records behind it' do
      newest = Content.repository.renderable.map { |record| Date.parse(record.updated.to_s) }.max

      expect(sitemap.css('url lastmod').map(&:text)).to all(eq(newest.iso8601))
      expect(sitemap.css('url lastmod').size).to eq(Content::Schema::LOCALES.size)
    end

    it 'annotates each URL with the same alternates the pages carry' do
      annotations = sitemap.css('url').first.css('xhtml|link')

      expect(annotations.pluck('hreflang'))
        .to eq(SiteMetadata.alternates.pluck(:hreflang))
    end

    it 'publishes nothing unpublishable' do
      expect(Content::SafetyScanner.new.scan(response.body, source: '/sitemap.xml').map(&:to_s)).to be_empty
    end
  end

  # `lastmod` is omitted rather than invented when no record dates itself. The
  # published corpus always dates a record, so this is driven from a fixture.
  describe 'GET /sitemap.xml when no record carries a readable date' do
    before do
      serve_fixture_corpus

      %w[en pt-BR].each do |locale|
        write_record('site-profile', type: 'site_profile', locale:, updated: 'not-a-date')
        write_record('leadership', type: 'leadership', locale:, updated: 'not-a-date')
      end

      get sitemap_path
    end

    it 'publishes every URL and no lastmod at all' do
      sitemap = Nokogiri::XML(response.body, &:strict)

      expect(sitemap.css('url loc')).not_to be_empty
      expect(sitemap.css('url lastmod')).to be_empty
    end
  end

  # `allow_browser` on ApplicationController used to answer both of these with
  # 406 for any User-Agent it read as an old browser. Several crawlers send
  # exactly that to look innocuous, and a crawler told the sitemap does not
  # exist is the one failure this feature cannot afford.
  describe 'a crawler that looks like an old browser' do
    let(:ancient) do
      {
        'HTTP_USER_AGENT' => 'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 ' \
                             '(KHTML, like Gecko) Chrome/49.0.2623.112 Safari/537.36'
      }
    end

    it 'still gets robots.txt and the sitemap' do
      get robots_path, headers: ancient
      expect(response).to have_http_status(:ok)

      get sitemap_path, headers: ancient
      expect(response).to have_http_status(:ok)
    end

    it 'is still turned away from the page, which is what the gate is for' do
      get root_path, headers: ancient

      expect(response).to have_http_status(:not_acceptable)
    end

    it 'gets the hardened headers on the crawler documents too' do
      get sitemap_path

      expect(response.headers['X-Content-Type-Options']).to eq('nosniff')
      expect(response.headers['Content-Security-Policy']).to include("default-src 'none'")
    end
  end

  describe 'the icons' do
    it 'ships no Rails generator artwork, whose red is not in the palette' do
      expect(Rails.public_path.join('icon.svg').read).not_to include('red')
      expect(Rails.public_path.join('icon.png')).to exist
    end
  end
end
