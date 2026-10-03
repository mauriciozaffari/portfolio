# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AgentGuide do
  subject(:guide) { described_class.new(locale: 'en') }

  it 'opens with the name and headline' do
    expect(guide.text).to start_with("# #{guide.name} — #{guide.profile[:headline]}")
  end

  it 'tells an agent when to use this profile' do
    expect(guide.text).to include('## When to use', 'Staff, Principal, or Tech Lead')
  end

  it 'links the machine-readable entry points, absolutely' do
    expect(guide.text).to include(
      "[Full profile and background](#{SiteMetadata.origin}/index.md)",
      "[OpenAPI 3.1](#{SiteMetadata.origin}/openapi.json)",
      "[#{SiteMetadata.origin}/mcp](#{SiteMetadata.origin}/.well-known/mcp/server-card.json)"
    )
  end

  it 'states where he is based and how he works, from the record' do
    expect(guide.text).to include(guide.profile[:region], guide.profile[:work_mode])
  end

  it 'warns an agent not to infer what the pages do not state' do
    expect(guide.text).to include('Do not infer employers, clients, compensation')
  end

  it 'closes with the approved contact links' do
    guide.profile[:links].each do |link|
      expect(guide.text).to include("- **#{link[:label]}**: #{link[:url]}")
    end
  end
end
