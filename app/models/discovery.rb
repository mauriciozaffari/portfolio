# frozen_string_literal: true

# The machine-readable discovery documents an AI agent looks for before it
# reads a single page: where the API is, what the MCP server offers, which
# skills exist, and how a crawler may use the content.
#
# Every URL in every document is derived from SiteMetadata.origin and the
# routing table, so a document cannot advertise an endpoint the application
# does not serve. The prose is chrome; the identity values come from the
# curated site_profile record.
class Discovery
  extend Forwardable

  include Vocabulary

  def initialize(page:)
    @page = page
  end

  attr_reader :page

  def profile = page.profile.record

  def_delegator :page, :locale

  def name = profile[:name]

  # The catalog at the ARD v0.91 canonical path. The media type for a nested
  # catalog is the one the AI Catalog standard registers for it.
  def ai_catalog
    {
      'specVersion' => '1.0',
      'host' => {
        'displayName' => name,
        'identifier' => SiteMetadata.host,
        'documentationUrl' => "#{origin}/llms.txt",
        'logoUrl' => "#{origin}/icon.png"
      },
      'entries' => catalog_entries
    }
  end

  def catalog_entries
    CATALOG_ENTRIES.map { |entry| catalog_entry(entry) }
  end

  def catalog_entry(entry)
    {
      'identifier' => "urn:air:#{SiteMetadata.host}:#{entry[:namespace]}:#{entry[:artifact]}",
      'displayName' => "#{name} — #{entry[:display_name]}",
      'type' => entry[:type],
      'description' => entry[:description],
      'url' => "#{origin}#{entry[:path]}"
    }
  end

  # The Agent Skills discovery index. The v0.2.0 fields sit alongside the v0.1
  # `skills` array so a consumer following either revision finds what it expects.
  def agent_skills
    {
      '$schema' => SKILL_SCHEMA,
      'skills' => skills.map { |skill| skill.except('markdown') }
    }
  end

  # Each skill is a Markdown file the site serves, so the digest below is over
  # bytes a client can actually fetch and verify.
  def skills
    SKILLS.map { |skill| skill_record(skill) }
  end

  def skills_by_name = skills.index_by { |skill| skill['name'] }

  def mcp_server_card
    {
      'name' => 'zaffari-profile',
      'title' => "#{name} — profile",
      'description' => "Read-only access to #{name}'s curated professional profile: " \
                       'identity, roles, case studies, skills, and impact figures.',
      'version' => '1.0.0',
      'serverUrl' => "#{origin}/mcp",
      'transport' => 'streamable-http',
      'protocolVersion' => '2025-06-18',
      'icon' => "#{origin}/icon.png",
      'tools' => Mcp::Tools.all.map { |tool| tool.to_h.deep_stringify_keys }
    }
  end

  def a2a_agent_card
    {
      'name' => "#{name} — professional profile",
      'description' => "Answers recruiter and evaluator questions about #{name} from curated records.",
      'version' => '1.0.0',
      'protocolVersion' => '0.3.0',
      'url' => "#{origin}/",
      'preferredTransport' => 'JSONRPC',
      'capabilities' => { 'streaming' => false, 'pushNotifications' => false },
      'defaultInputModes' => ['text/markdown', 'text/plain'],
      'defaultOutputModes' => ['text/markdown'],
      'skills' => skills.map { |skill| skill_summary(skill) }
    }
  end

  def api_catalog
    {
      'linkset' => [
        {
          'anchor' => "#{origin}/mcp",
          'item' => [
            { 'href' => "#{origin}/openapi.json", 'type' => 'application/openapi+json',
              'title' => 'OpenAPI description' },
            { 'href' => "#{origin}/.well-known/mcp/server-card.json", 'type' => 'application/json',
              'title' => 'MCP server card' }
          ],
          'service-desc' => [
            { 'href' => "#{origin}/.well-known/mcp/server-card.json", 'type' => 'application/json',
              'title' => 'MCP server card' }
          ],
          'service-doc' => [
            { 'href' => "#{origin}/llms.txt", 'type' => 'text/plain', 'title' => 'Agent instructions' },
            { 'href' => "#{origin}/api/llms.txt", 'type' => 'text/plain', 'title' => 'API guide' }
          ]
        }
      ]
    }
  end

  # RFC 9728. The API is public and needs no credentials, so there is no
  # authorization server to name; saying so explicitly is the useful answer for
  # an agent that would otherwise hunt for one.
  def protected_resource
    {
      'resource' => "#{origin}/api/v1",
      'authorization_servers' => [],
      'scopes_supported' => [],
      'bearer_methods_supported' => [],
      'resource_documentation' => "#{origin}/auth.md"
    }
  end

  def_delegator :SiteMetadata, :origin

  private

  def skill_record(skill)
    slug = skill[:name]
    markdown = skill_markdown(slug, skill[:title], skill_body(skill))

    {
      'name' => slug,
      'description' => "Retrieve #{name}'s #{skill[:description]}.",
      'type' => 'skill-md',
      'url' => "#{origin}/agent-skills/#{slug}.md",
      'digest' => "sha256:#{Digest::SHA256.hexdigest(markdown)}",
      'markdown' => markdown
    }
  end

  def skill_body(skill)
    format(skill[:body], api: "#{origin}/api/v1/#{skill[:name]}", markdown: "#{origin}/index.md")
  end

  def skill_summary(skill)
    slug = skill['name']

    { 'id' => slug, 'name' => slug, 'description' => skill['description'] }
  end

  def skill_markdown(name, title, body)
    [
      '---',
      "name: #{name}",
      "description: #{body}",
      '---',
      '',
      "# #{title}",
      '',
      body
    ].join("\n")
  end
end
