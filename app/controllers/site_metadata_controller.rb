# frozen_string_literal: true

class SiteMetadataController < ApplicationController
  include Localized

  layout false

  def robots
    render formats: :text, content_type: 'text/plain'
  end

  def sitemap
    @sitemap = Sitemap.new(repository: Content.repository)

    render formats: :xml, content_type: 'application/xml'
  end

  # The AI-crawler counterpart to robots.txt: what this site is, what an agent
  # can do with it, and where the machine-readable documents live.
  def llms
    render plain: AgentGuide.new(locale:).text, content_type: 'text/plain; charset=utf-8'
  end

  # The whole corpus as one document, for an agent that would rather read once
  # than follow an index.
  def llms_full
    @documents = Content::Schema::LOCALES.map do |code|
      { locale: code, markdown: LandingPageMarkdown.new(page: page_for(code)).render }
    end

    render formats: :text, content_type: 'text/plain; charset=utf-8'
  end

  def api_llms
    render formats: :text, content_type: 'text/plain; charset=utf-8'
  end

  def skills_llms
    render formats: :text, content_type: 'text/plain; charset=utf-8'
  end

  private

  def page_for(locale)
    LandingPage.new(repository: Content.repository, locale:)
  end
end
