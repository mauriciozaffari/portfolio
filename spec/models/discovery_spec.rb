# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Discovery do
  subject(:discovery) { described_class.new(page: LandingPage.new(repository: Content.repository, locale: 'en')) }

  describe '#ai_catalog' do
    let(:catalog) { discovery.ai_catalog }

    it 'declares the spec version and names the host' do
      expect(catalog).to include('specVersion' => '1.0')
      expect(catalog.dig('host', 'displayName')).to eq('Mauricio Zaffari')
      expect(catalog.dig('host', 'identifier')).to eq(SiteMetadata.host)
    end

    it 'gives every entry a domain-anchored urn:air identifier and one locator' do
      catalog['entries'].each do |entry|
        expect(entry['identifier']).to start_with("urn:air:#{SiteMetadata.host}:")
        expect(entry.key?('url') ^ entry.key?('data')).to be(true)
      end
    end
  end

  describe '#agent_skills' do
    let(:index) { discovery.agent_skills }

    it 'declares the v0.2.0 schema and lists every skill' do
      expect(index['$schema']).to eq(described_class::SKILL_SCHEMA)
      expect(index['skills'].size).to eq(discovery.skills.size)
    end

    it 'hashes the artifact bytes it advertises' do
      skill = index['skills'].first

      expect(skill['digest']).to eq("sha256:#{Digest::SHA256.hexdigest(discovery.skills_by_name.fetch(skill['name'])['markdown'])}")
    end

    it 'keeps the Markdown artifact out of the index it serves' do
      expect(index['skills'].first).not_to have_key('markdown')
    end
  end

  describe '#skills_by_name' do
    it 'returns the skill and its artifact' do
      expect(discovery.skills_by_name.fetch('profile-and-cv')).to include('name' => 'profile-and-cv',
                                                                          'markdown' => a_string_matching(/\A---/))
    end

    it 'raises for a skill that does not exist, so a route can answer 404 itself' do
      expect { discovery.skills_by_name.fetch('no-such-skill') }.to raise_error(KeyError)
    end
  end

  describe '#mcp_server_card' do
    let(:card) { discovery.mcp_server_card }

    it 'names the transport and points at the MCP endpoint' do
      expect(card).to include('name' => 'zaffari-profile', 'transport' => 'streamable-http')
      expect(card['serverUrl']).to eq("#{SiteMetadata.origin}/mcp")
    end

    it 'carries the real tool definitions' do
      expect(card['tools'].pluck('name')).to eq(Mcp::Tools.names)
    end
  end

  describe '#a2a_agent_card' do
    it 'describes the site and each skill an agent can ask for' do
      card = discovery.a2a_agent_card

      expect(card['url']).to eq("#{SiteMetadata.origin}/")
      expect(card['skills'].pluck('id')).to eq(discovery.skills.pluck('name'))
    end
  end

  describe '#api_catalog' do
    it 'is an RFC 9727 linkset naming the service description and docs' do
      linkset = discovery.api_catalog['linkset'].first

      expect(linkset['anchor']).to eq("#{SiteMetadata.origin}/mcp")
      expect(linkset).to include('item', 'service-desc', 'service-doc')
    end
  end

  describe '#protected_resource' do
    it 'names the resource and states that no authorization server exists' do
      expect(discovery.protected_resource).to include(
        'resource' => "#{SiteMetadata.origin}/api/v1",
        'authorization_servers' => []
      )
    end
  end
end
