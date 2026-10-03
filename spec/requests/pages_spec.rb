# frozen_string_literal: true

require 'rails_helper'

# The three trust pages an agent checks before it recommends a person, plus the
# Markdown landing twins and the agent-mode view.
RSpec.describe 'Prose pages' do
  shared_examples 'a trust page' do |path, heading|
    it 'returns a substantial page with exactly one h1' do
      get path

      expect(response).to have_http_status(:ok)
      expect(response.parsed_body.css('h1').size).to eq(1)
      expect(response.parsed_body.at_css('h1').text).to include(heading)
      expect(response.body.length).to be > 2_000
    end

    it 'names itself canonically rather than claiming to be the homepage' do
      get path

      canonical = response.parsed_body.at_css("link[rel='canonical']")['href']

      expect(canonical).to end_with(path)
      expect(canonical).not_to eq("#{SiteMetadata.origin}/")
    end
  end

  describe 'GET /about' do
    it_behaves_like 'a trust page', '/about', 'About'

    it 'renders the profile and the how-I-work records rather than new prose' do
      get '/about'

      body = response.body

      expect(body).to include(Content.repository.site_profile(locale: 'en').record[:name])
      expect(body).to include(Content.repository.leadership(locale: 'en').record[:title])
    end
  end

  describe 'GET /contact' do
    it_behaves_like 'a trust page', '/contact', 'Contact'

    it 'lists only the approved contact links' do
      get '/contact'

      links = response.parsed_body.css('a[href]').pluck('href').uniq
      offsite = links.reject { |href| href.start_with?('#', '/') }
      profile = Content.repository.site_profile(locale: 'en').record

      expect(offsite).to match_array(profile[:links].pluck(:url))
    end
  end

  describe 'GET /privacy' do
    it_behaves_like 'a trust page', '/privacy', 'Privacy'

    it 'states the no-cookie and no-tracking position' do
      get '/privacy'

      expect(response.body).to include('no analytics script', 'none is set', 'anonymous by')
    end
  end

  describe 'GET /pt-BR/privacy' do
    it 'serves the Portuguese wording' do
      get '/pt-BR/privacy'

      expect(response.parsed_body.at_css('html')['lang']).to eq('pt-BR')
      expect(response.body).to include('Nada coleta informações')
    end
  end

  describe 'Markdown twins' do
    it 'serves /index.md as Markdown with front matter' do
      get english_markdown_path

      expect(response.media_type).to eq('text/markdown')
      expect(response.body).to start_with("---\n")
      expect(response.body).to include("canonical: #{SiteMetadata.url_for('en')}")
      expect(response.body).to include('# Mauricio Zaffari')
    end

    it 'serves /pt-BR/index.md in Portuguese' do
      get portuguese_markdown_path

      expect(response.media_type).to eq('text/markdown')
      expect(response.body).to include('locale: pt-BR')
    end

    it 'negotiates Markdown from an Accept header on the landing page' do
      get root_path, headers: { 'Accept' => 'text/markdown' }

      expect(response.media_type).to eq('text/markdown')
      expect(response.body).to start_with("---\n")
    end

    it 'still serves HTML to a browser Accept header' do
      get root_path, headers: { 'Accept' => 'text/html' }

      expect(response.media_type).to eq('text/html')
    end
  end

  describe 'GET /?mode=agent' do
    before { get "#{root_path}?mode=agent" }

    it 'returns a machine-readable overview instead of the marketing page' do
      expect(response.media_type).to eq('text/markdown')
      expect(response.body).to include('# Agent Overview', '## Available Endpoints', '## Authentication')
      expect(response.body).to include("#{SiteMetadata.origin}/api/v1/profile", "#{SiteMetadata.origin}/mcp")
    end
  end

  describe 'Link headers' do
    it 'advertises the sitemap, the Markdown twin, the API catalog, and the ARD catalog' do
      get root_path

      links = response.headers['Link']

      expect(links).to include('rel="sitemap"', 'rel="alternate"; type="text/markdown"',
                               'rel="service-desc"', 'rel="describedby"')
      expect(response.headers['Vary']).to include('Accept')
    end
  end
end
