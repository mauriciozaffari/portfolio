# frozen_string_literal: true

require 'rails_helper'

# The `.md` twin of a machine-readable document. An agent appends `.md` to a URL
# it already knows, so the twins must be real Markdown and must agree with the
# document they mirror.
RSpec.describe 'Markdown twins' do
  it 'serves the API guide as Markdown at /api.md' do
    get api_markdown_path

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq('text/markdown')
    expect(response.body).to start_with('# API guide')
  end

  it 'serves the same guide when .md is appended to the guide URL' do
    get api_llms_markdown_path

    expect(response.media_type).to eq('text/markdown')
    expect(response.body).to start_with('# API guide')
  end

  describe 'GET /openapi.json.md' do
    before { get openapi_markdown_path }

    it 'is Markdown, not the schema' do
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('text/markdown')
      expect(response.body).to start_with('# mauricio.zaffari.casa profile API')
    end

    it 'carries the same versioning policy the schema states' do
      expect(response.body).to include('Versioning', 'Sunset')
    end

    it 'lists the endpoints the schema documents, from the schema' do
      schema = OpenapiDocument.new(origin: SiteMetadata.origin).to_h

      schema['paths'].each_key do |path|
        expect(response.body).to include("| GET | `#{path}` |")
      end
    end
  end

  describe OpenapiMarkdown do
    subject(:markdown) do
      described_class.new(document: OpenapiDocument.new(origin: SiteMetadata.origin).to_h)
    end

    it 'names the base URL every path is relative to' do
      expect(markdown.render).to include("Base URL: `#{SiteMetadata.origin}/api/v1`")
    end

    it 'skips a path that has no GET operation' do
      document = { 'info' => { 'title' => 'T', 'description' => 'D' },
                   'servers' => [{ 'url' => 'https://example.test' }],
                   'paths' => { '/thing' => { 'post' => { 'summary' => 'nope' } } } }

      expect(described_class.new(document:).render).not_to include('/thing')
    end
  end
end
