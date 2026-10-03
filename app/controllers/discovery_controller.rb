# frozen_string_literal: true

# Serves the discovery documents an agent asks for before it reads a page:
# catalogs, skill indexes, server cards, and the Markdown guides beside them.
#
# Every document is built from the curated records by Discovery, and every URL
# in one is generated from SiteMetadata.origin, so nothing here can advertise a
# path the application does not serve.
class DiscoveryController < ApplicationController
  include Localized

  layout false

  def ai_catalog
    render_discovery_json(discovery.ai_catalog)
  end

  def agent_skills
    render_discovery_json(discovery.agent_skills)
  end

  def agent_skill
    skill = discovery.skills_by_name.fetch(params[:skill]) { return head :not_found }

    render plain: skill['markdown'], content_type: 'text/markdown; charset=utf-8'
  end

  def mcp_server_card
    render_discovery_json(discovery.mcp_server_card)
  end

  def agent_card
    render_discovery_json(discovery.a2a_agent_card)
  end

  def api_catalog
    render_discovery_json(discovery.api_catalog, content_type: LINKSET_TYPE)
  end

  def protected_resource
    render_discovery_json(discovery.protected_resource)
  end

  # RFC 9727 names this media type with its profile parameter, and the check an
  # agent runs compares the whole string, so it is set verbatim.
  LINKSET_TYPE = 'application/linkset+json;profile="https://www.rfc-editor.org/info/rfc9727"'

  private

  def page
    @page ||= LandingPage.new(repository: Content.repository, locale:)
  end

  def discovery = Discovery.new(page:)

  def render_discovery_json(document, content_type: 'application/json')
    render plain: JSON.pretty_generate(document), content_type:
  end
end
