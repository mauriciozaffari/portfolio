# frozen_string_literal: true

require 'rails_helper'

# The discovery documents and the two prose walkthroughs. Each is driven through
# the router, because the failure mode this guards against is a document that
# advertises a URL the application does not serve.
RSpec.describe 'Agent discovery documents' do
  describe 'GET /.well-known/ard.json' do
    before { get ard_catalog_path }

    let(:catalog) { response.parsed_body }

    it 'is served as JSON' do
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/json')
    end

    it 'names the host and every agentic resource with a urn:air identifier' do
      expect(catalog.dig('host', 'displayName')).to eq('Mauricio Zaffari')
      expect(catalog['specVersion']).to eq('1.0')

      identifiers = catalog['entries'].pluck('identifier')

      expect(identifiers).to all(start_with("urn:air:#{SiteMetadata.host}:"))
    end

    it 'gives every entry a display name, a media type, and exactly one locator' do
      catalog['entries'].each do |entry|
        expect(entry['displayName']).to be_present
        expect(entry['type']).to be_present
        expect(entry.key?('url') ^ entry.key?('data')).to be(true)
      end
    end

    it 'points each entry at a path this application actually serves' do
      paths = catalog['entries'].pluck('url').map { |url| URI.parse(url).path }
      served = Rails.application.routes.routes.map { |route| route.path.spec.to_s.sub(/\(\.:format\).*\z/, '') }

      paths.each do |path|
        expect(served).to include(path)
      end
    end
  end

  it 'serves the same catalog at the AI Catalog alias' do
    get ard_catalog_path
    canonical = response.body

    get ai_catalog_path

    expect(response.body).to eq(canonical)
  end

  describe 'GET /.well-known/agent-skills/index.json' do
    before { get agent_skills_path }

    let(:index) { response.parsed_body }

    it 'declares the v0.2.0 schema' do
      expect(index['$schema']).to eq('https://schemas.agentskills.io/discovery/0.2.0/schema.json')
    end

    it 'lists each skill with a name, a description, a type, a url, and a digest' do
      expect(index['skills']).to all(
        include('name', 'description', 'type' => 'skill-md', 'url' => a_string_starting_with('https://'))
      )
      expect(index['skills'].pluck('digest')).to all(match(/\Asha256:[0-9a-f]{64}\z/))
    end

    it 'serves each advertised skill artifact as Markdown' do
      path = URI.parse(index['skills'].first['url']).path

      get path

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/markdown')
      expect(response.body).to start_with('---')
    end
  end

  describe 'GET /agent-skills/:skill.md' do
    it 'answers 404 for a skill that does not exist' do
      get agent_skill_path(skill: 'no-such-skill')

      expect(response).to have_http_status(:not_found)
    end
  end

  describe 'GET /.well-known/mcp/server-card.json' do
    before { get mcp_server_card_path }

    let(:card) { response.parsed_body }

    it 'describes the server and its tools' do
      expect(card['name']).to eq('zaffari-profile')
      expect(card['serverUrl']).to eq("#{SiteMetadata.origin}/mcp")
      expect(card['transport']).to eq('streamable-http')
      expect(card['tools'].pluck('name')).to eq(Mcp::Tools.names)
    end

    it 'gives every tool a description and an input schema' do
      card['tools'].each do |tool|
        expect(tool['title']).to be_present
        expect(tool['description'].length).to be >= 20
        expect(tool['inputSchema']).to include('type' => 'object')
      end
    end
  end

  describe 'GET /.well-known/agent-card.json' do
    before { get agent_card_path }

    let(:card) { response.parsed_body }

    it 'describes the agent and the skills it answers for' do
      expect(card['name']).to include('Mauricio Zaffari')
      expect(card['url']).to eq("#{SiteMetadata.origin}/")
      expect(card['skills'].pluck('id')).to include('profile-and-cv', 'career-history', 'technical-skills',
                                                    'case-studies')
    end
  end

  describe 'GET /.well-known/api-catalog' do
    before { get api_catalog_path }

    it 'is a linkset pointing at the service description and the OpenAPI document' do
      expect(response.headers['Content-Type']).to include('application/linkset+json', 'rfc9727')
      expect(response.parsed_body['linkset'].first).to include('anchor', 'item', 'service-desc', 'service-doc')
    end
  end

  describe 'GET /.well-known/oauth-protected-resource' do
    before { get protected_resource_path }

    it 'names the resource and states honestly that no authorization server exists' do
      expect(response.parsed_body).to include(
        'resource' => "#{SiteMetadata.origin}/api/v1",
        'authorization_servers' => [],
        'bearer_methods_supported' => []
      )
    end
  end

  describe 'Markdown and text walkthroughs' do
    it 'serves /llms.txt as plain text with the when-to-use guidance' do
      get llms_path

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/plain')
      expect(response.body).to include('When to reach for')
      expect(response.body).to include("#{SiteMetadata.origin}/index.md")
    end

    it 'serves /llms-full.txt with every record in both locales' do
      get llms_full_path

      expect(response.body.scan(/^## Locale: /).size).to eq(Content::Schema::LOCALES.size)
    end

    it 'serves /api/llms.txt as a plain-text API guide' do
      get api_llms_path

      expect(response.body).to include("#{SiteMetadata.origin}/openapi.json")
      expect(response.media_type).to eq('text/plain')
    end

    it 'serves /agent-skills/llms.txt naming each skill' do
      get skills_llms_path

      expect(response.body).to include('`profile-and-cv`', '## How to use these')
      expect(response.media_type).to eq('text/plain')
    end

    it 'serves /auth.md as a Markdown walkthrough that says no credentials are needed' do
      get auth_path

      expect(response.media_type).to eq('text/markdown')
      expect(response.body).to start_with('# Authentication')
      expect(response.body).to include('There is nothing to authenticate with.')
      expect(response.body).to include('## Discover', '## Pick a method', '## Errors', '## Revocation')
    end

    it 'serves /agents.md as repository guidance for coding agents' do
      get agents_path

      expect(response.media_type).to eq('text/markdown')
      expect(response.body).to include('bin/ci', 'AGENTS.md')
      expect(response.body).to include('may not')
    end
  end

  describe 'GET /openapi.json' do
    before { get openapi_path }

    # The media type is not one Rack parses into a Hash, so the spec is read
    # from the body the way an agent would.
    let(:spec) { response.parsed_body }

    it 'is served as an OpenAPI 3.1 document' do
      expect(response.media_type).to eq('application/openapi+json')
      expect(spec['openapi']).to eq('3.1.0')
    end

    it 'documents every API path with an operation id and a typed response' do
      expect(spec['paths'].keys).to include('/profile', '/experience', '/records')

      spec['paths'].each_value do |operation|
        expect(operation.dig('get', 'operationId')).to be_present
        expect(operation.dig('get', 'responses', '200', 'content')).to be_present
      end
    end

    it 'declares the components its responses reference' do
      expect(spec.dig('components', 'schemas').keys).to include('Record', 'Error')
    end
  end
end
