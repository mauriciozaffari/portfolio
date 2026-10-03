# frozen_string_literal: true

class LandingController < ApplicationController
  include Localized

  # Only allow modern browsers supporting webp images, web push, badges, import
  # maps, CSS nesting, and CSS :has. Scoped to HTML browser requests only so
  # text clients and AI agents negotiating markdown are never rejected.
  allow_browser versions: :modern, if: -> { !request.format.md? && params[:mode] != 'agent' }

  after_action :set_discovery_headers

  def show
    page = LandingPage.new(repository: Content.repository, locale:)
    metadata = SiteMetadata.new(page:)

    @page = page
    @metadata = metadata

    if params[:mode] == 'agent'
      render_agent_mode
      return
    end

    respond_to do |format|
      format.html
      format.md { render_markdown(page, metadata) }
    end
  end

  # The `.md` twin of the page, at a URL a crawler can guess without sending an
  # Accept header it does not know to send.
  def markdown
    page = LandingPage.new(repository: Content.repository, locale:)
    metadata = SiteMetadata.new(page:)

    render_markdown(page, metadata)
  end

  private

  def render_markdown(page, metadata)
    render plain: LandingPageMarkdown.new(page:, metadata:).render,
           content_type: 'text/markdown; charset=utf-8'
  end

  def set_discovery_headers
    headers = response.headers
    headers['Vary'] = [headers['Vary'], 'Accept'].compact_blank.uniq.join(', ')

    origin = SiteMetadata.origin
    links = [
      %(<#{SiteMetadata.sitemap_url}>; rel="sitemap"),
      %(<#{SiteMetadata.markdown_url_for(locale)}>; rel="alternate"; type="text/markdown"),
      %(<#{origin}/.well-known/api-catalog>; rel="service-desc"),
      %(<#{origin}/.well-known/ard.json>; rel="describedby")
    ]
    headers['Link'] = links.join(', ')
  end

  # The machine-readable overview a cold-arrival agent can ask for with
  # `?mode=agent`, so it does not have to parse the marketing page.
  def render_agent_mode
    origin = SiteMetadata.origin
    profile = LandingPage.new(repository: Content.repository, locale:).profile.record
    links = Array(profile[:links]).map { |link| "- #{link[:label]}: #{link[:url]}" }

    agent_view = [
      "# Agent Overview — #{origin}",
      '',
      "> #{profile[:headline]}",
      '',
      '## Capabilities',
      '- Profile & Background retrieval',
      '- Experience & Career history search',
      '- Technical Skills & Architecture competencies',
      '- Engineering Case Studies',
      '',
      '## Available Endpoints',
      *endpoints(origin),
      '',
      '## Authentication',
      'Public read-only. No API key or bearer token required.',
      '',
      '## Contact',
      *links
    ].join("\n")

    render plain: agent_view, content_type: 'text/markdown; charset=utf-8'
  end

  def endpoints(origin)
    [
      "- API Catalog: #{origin}/.well-known/api-catalog",
      "- OpenAPI 3.1 Spec: #{origin}/openapi.json",
      "- Profile API: #{origin}/api/v1/profile",
      "- Experience API: #{origin}/api/v1/experience",
      "- Skills API: #{origin}/api/v1/skills",
      "- MCP Server: #{origin}/mcp",
      "- Agent Skills Index: #{origin}/.well-known/agent-skills/index.json",
      "- LLMs Context Index: #{origin}/llms.txt"
    ]
  end
end
