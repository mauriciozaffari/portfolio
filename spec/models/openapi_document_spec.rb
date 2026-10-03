# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OpenapiDocument do
  subject(:document) { described_class.new(origin: SiteMetadata.origin).to_h }

  it 'is an OpenAPI 3.1 document titled for this site' do
    expect(document['openapi']).to eq('3.1.0')
    expect(document.dig('info', 'title')).to include('profile API')
  end

  it 'serves the API under the canonical origin' do
    expect(document['servers'].first['url']).to eq("#{SiteMetadata.origin}/api/v1")
  end

  it 'documents a path for every record type, plus the catch-all' do
    expect(document['paths'].keys).to include('/profile', '/experience', '/records', '/{type}')
  end

  it 'gives every operation an id, a description, and a typed success response' do
    document['paths'].each_value do |path|
      operation = path['get']

      expect(operation['operationId']).to be_present
      expect(operation['description']).to be_present
      expect(operation.dig('responses', '200', 'content', 'application/json', 'schema')).to be_present
    end
  end

  it 'declares a locale parameter on every operation' do
    document['paths'].each_value do |path|
      names = path['get']['parameters'].pluck('name')

      expect(names).to include('locale')
    end
  end

  it 'rejects an unknown type on the catch-all route with a documented enum' do
    parameter = document.dig('paths', '/{type}', 'get', 'parameters').find { |item| item['name'] == 'type' }

    expect(parameter.dig('schema', 'enum')).to eq(RecordSet.type_names)
  end

  it 'documents the error shape its 404 responses reference' do
    expect(document.dig('components', 'schemas', 'Error')).to include('required' => ['error'])
  end
end
