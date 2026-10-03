# frozen_string_literal: true

require 'rails_helper'

# The Model Context Protocol endpoint, driven over its real Streamable HTTP
# transport: a JSON-RPC message in, a JSON-RPC response out.
RSpec.describe 'Model Context Protocol endpoint' do
  # An MCP client connects to the canonical host, and the transport's
  # rebinding protection only answers that host. The Accept header is the
  # Streamable HTTP contract: a client must say it can read the response.
  def mcp_headers
    { 'Accept' => 'application/json, text/event-stream', 'Host' => SiteMetadata.host }
  end

  def rpc(method, params: nil, id: 1)
    payload = { jsonrpc: '2.0', method: }
    payload[:id] = id if id
    payload[:params] = params if params
    post mcp_path, params: payload, as: :json, headers: mcp_headers
  end

  def call_tool(name, arguments = {})
    rpc('tools/call', params: { name:, arguments: })
  end

  describe 'POST /mcp initialize' do
    before do
      rpc('initialize',
          params: { protocolVersion: '2025-06-18', capabilities: {}, clientInfo: { name: 'spec', version: '1' } })
    end

    let(:result) { response.parsed_body['result'] }

    it 'answers with the server identity and instructions' do
      expect(response).to have_http_status(:ok)
      expect(result.dig('serverInfo', 'name')).to eq('zaffari-profile')
      expect(result['instructions']).to include("Mauricio Zaffari's curated professional profile")
      expect(result['capabilities']).to have_key('tools')
    end
  end

  describe 'POST /mcp tools/list' do
    before { rpc('tools/list') }

    let(:tools) { response.parsed_body.dig('result', 'tools') }

    it 'lists every read-only tool with a schema and annotations' do
      expect(tools.pluck('name')).to eq(Mcp::Tools.names)
      expect(tools).to all(include('title', 'description', 'inputSchema'))
      expect(tools).to all(include('annotations' => include('readOnlyHint' => true)))
    end
  end

  describe 'POST /mcp tools/call' do
    it 'returns the profile record for get_profile' do
      call_tool('get_profile')

      payload = JSON.parse(response.parsed_body.dig('result', 'content', 0, 'text'))

      expect(payload).to include('id' => 'site-profile', 'name' => 'Mauricio Zaffari')
      expect(response.parsed_body.dig('result', 'isError')).to be(false)
    end

    it 'returns the employment history for get_experience' do
      call_tool('get_experience')

      payload = JSON.parse(response.parsed_body.dig('result', 'content', 0, 'text'))

      expect(payload).to be_an(Array)
      expect(payload).to all(include('type' => 'experience'))
    end

    it 'honours a locale argument' do
      call_tool('get_profile', { locale: 'pt-BR' })

      payload = JSON.parse(response.parsed_body.dig('result', 'content', 0, 'text'))

      expect(payload['locale']).to eq('pt-BR')
    end

    it 'searches every record for a keyword' do
      call_tool('search_records', { query: 'PostgreSQL' })

      payload = JSON.parse(response.parsed_body.dig('result', 'content', 0, 'text'))

      expect(payload).not_to be_empty
      expect(payload.to_s).to include('PostgreSQL')
    end

    it 'rejects a query that is too short to be meaningful' do
      call_tool('search_records', { query: 'a' })

      # The transport's schema check rejects it before the tool body runs.
      expect(response.parsed_body.dig('result', 'isError')).to be(true)
      expect(response.parsed_body.dig('result', 'content', 0, 'text')).to include('Invalid arguments')
    end

    it 'lists the record vocabulary for list_record_types' do
      call_tool('list_record_types')

      payload = JSON.parse(response.parsed_body.dig('result', 'content', 0, 'text'))

      expect(payload).to eq(RecordSet.type_names)
    end

    it 'answers an unknown tool with a JSON-RPC error' do
      call_tool('delete_everything')

      expect(response.parsed_body.dig('error', 'code')).to eq(-32_602)
      expect(response.parsed_body.dig('error', 'message')).to eq('Invalid params')
    end
  end

  describe 'POST /mcp protocol edges' do
    it 'accepts a notification with no id and returns no body' do
      rpc('notifications/initialized', id: nil)

      expect(response).to have_http_status(:accepted)
      expect(response.body).to be_empty
    end

    it 'answers ping' do
      rpc('ping')

      expect(response.parsed_body['result']).to eq({})
    end

    it 'answers an unknown method with a JSON-RPC error' do
      rpc('resources/subscribe')

      expect(response.parsed_body.dig('error', 'code')).to eq(-32_603)
    end

    it 'refuses a request that does not accept the media types it can return' do
      post mcp_path, params: { jsonrpc: '2.0', id: 1, method: 'ping' }, as: :json,
                     headers: mcp_headers.merge('Accept' => 'text/html')

      expect(response).to have_http_status(:not_acceptable)
    end
  end

  describe 'GET /mcp' do
    it 'refuses the idle stream it never opens' do
      get mcp_path

      expect(response).to have_http_status(:method_not_allowed)
      expect(response.headers['Allow']).to eq('POST')
    end
  end
end
