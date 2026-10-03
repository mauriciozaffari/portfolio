# frozen_string_literal: true

# JSON-RPC endpoint speaking the Model Context Protocol (Streamable HTTP,
# stateless), using the official `mcp` gem's server and transport.
#
# Every method here is public and read-only: the site has nothing to write and
# no accounts, so there is no authorization server, no token, and no session to
# keep between calls. `stateless: true` is what makes that explicit — an agent
# may treat each request as the whole conversation.
class McpController < ApplicationController
  include Localized

  layout false

  # The transport owns the request body, reads it itself, and is the thing that
  # decides a JSON-RPC notification gets no response body. Rails' forgery check
  # would reject every honest call before the transport ever sees it.
  skip_forgery_protection

  # Streamable HTTP does not require GET to be supported, and this server never
  # pushes, so an idle SSE stream is refused rather than opened.
  def show
    response.set_header('Allow', 'POST')
    head :method_not_allowed
  end

  def create
    status, headers, body = transport.handle_request(request)

    headers.each { |name, value| response.set_header(name, value) }
    render body: body.join, status:, content_type: headers['content-type']
  end

  private

  def transport
    MCP::Server::Transports::StreamableHTTPTransport.new(
      server,
      stateless: true,
      enable_json_response: true,
      # DNS-rebinding protection: the SDK only answers a request whose Host is
      # one it was told to trust, so the canonical host is the allowlist.
      allowed_hosts: [SiteMetadata.host]
    )
  end

  def server
    MCP::Server.new(
      name: 'zaffari-profile',
      title: "#{profile[:name]} — profile",
      version: '1.0.0',
      instructions:,
      tools: Mcp::Tools.all,
      resources: Mcp::Resources.all
    )
  end

  def profile
    LandingPage.new(repository: Content.repository, locale:).profile.record
  end

  def instructions
    "Read-only access to #{profile[:name]}'s curated professional profile: " \
      'identity, roles, case studies, skills, and impact figures. ' \
      'Use get_profile for identity and contact links, get_experience for roles and dates, ' \
      'and search_records to find whether a technology, client, or responsibility appears ' \
      'anywhere in the published records. Everything returned is published on ' \
      "#{SiteMetadata.origin}; nothing is generated."
  end
end
