# frozen_string_literal: true

require 'rails_helper'

# The tools are also a Ruby API: the MCP transport validates arguments against
# each tool's JSON Schema before it calls one, so the guards inside the tools
# are defence for a direct caller. They are exercised here, where the schema
# layer is not in the way.
RSpec.describe Mcp::Tools do
  describe '.names' do
    it 'lists the read-only tools in a stable order' do
      expect(described_class.names).to eq(%w[get_profile get_experience search_records list_record_types])
    end
  end

  describe Mcp::Tools::GetProfile do
    it 'returns the profile record as a text payload' do
      response = described_class.call

      expect(response.error?).to be(false)
      expect(JSON.parse(response.content.first[:text])).to include('id' => 'site-profile')
    end
  end

  describe Mcp::Tools::GetExperience do
    it 'honours an explicit locale' do
      response = described_class.call(locale: 'pt-BR')
      payload = JSON.parse(response.content.first[:text])

      expect(payload).to all(include('locale' => 'pt-BR'))
    end
  end

  describe Mcp::Tools::SearchRecords do
    it 'returns the matching records' do
      response = described_class.call(query: 'PostgreSQL')

      expect(JSON.parse(response.content.first[:text])).not_to be_empty
    end

    it 'refuses a query too short to be meaningful, without asking the corpus' do
      response = described_class.call(query: 'a')

      expect(response.error?).to be(true)
      expect(response.content.first[:text]).to include('at least two characters')
    end
  end

  describe Mcp::Tools::ListRecordTypes do
    it 'returns the record vocabulary' do
      response = described_class.call

      expect(JSON.parse(response.content.first[:text])).to eq(RecordSet.type_names)
    end
  end

  describe Mcp::Tools::Base do
    it 'falls back to the default locale for a locale the corpus does not have' do
      response = Mcp::Tools::GetProfile.call(locale: 'xx')

      expect(JSON.parse(response.content.first[:text])['locale']).to eq('en')
    end
  end

  describe Mcp::Resources::AgentGuide do
    it 'serves the same text as /llms.txt over the protocol' do
      contents = described_class.contents

      expect(contents.mime_type).to eq('text/markdown')
      expect(contents.text).to include('## When to reach for')
    end
  end
end
