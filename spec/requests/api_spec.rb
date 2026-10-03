# frozen_string_literal: true

require 'rails_helper'

# The read-only API, driven against the real corpus: what it returns is what
# ships, and the response shape is the contract an agent codes against.
RSpec.describe 'Read-only profile API' do
  let(:document) { response.parsed_body }

  def expected_locale(locale) = Content.repository.site_profile(locale:).record

  describe 'GET /api/v1/profile' do
    before { get api_v1_profile_path }

    it 'is served as JSON' do
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/json')
    end

    it 'returns the identity record the page renders' do
      expect(document['data']).to include(
        'id' => 'site-profile',
        'name' => expected_locale('en')[:name],
        'headline' => expected_locale('en')[:headline]
      )
      expect(document.dig('meta', 'locale')).to eq('en')
    end

    it 'serves the Portuguese record when asked for that locale' do
      get api_v1_profile_path(locale: 'pt-BR')

      expect(document.dig('meta', 'locale')).to eq('pt-BR')
      expect(document.dig('data', 'headline')).to eq(expected_locale('pt-BR')[:headline])
    end

    it 'caches publicly and names the representation' do
      expect(response.headers['Cache-Control']).to include('public', 'max-age=300')
      expect(response.headers['Vary']).to include('Accept')
      expect(response.headers['ETag']).to be_present
    end
  end

  describe 'GET /api/v1/experience' do
    before { get api_v1_experience_path }

    it 'returns the roles as an array' do
      expect(response).to have_http_status(:ok)
      expect(document['data']).to be_an(Array)
      expect(document['data']).to all(
        include('id' => a_string_matching(/\S/), 'type' => 'experience', 'locale' => 'en')
      )
      expect(document.dig('meta', 'type')).to eq('experience')
    end
  end

  describe 'GET /api/v1/records' do
    before { get api_v1_records_path }

    it 'returns every record of every type' do
      types = document['data'].pluck('type').uniq

      expect(document.dig('meta', 'types')).to eq(RecordSet.type_names)
      expect(types).to include('site_profile', 'experience', 'case_study', 'skill_group')
    end
  end

  describe 'GET /api/v1/:type' do
    it 'answers a named type through the catch-all segment' do
      get api_v1_type_path(type: 'skills')

      expect(response).to have_http_status(:ok)
      expect(document.dig('meta', 'type')).to eq('skills')
    end

    it 'answers an unknown type with one JSON error shape' do
      get api_v1_type_path(type: 'widgets')

      expect(response).to have_http_status(:not_found)
      expect(response.media_type).to eq('application/json')
      expect(document.dig('error', 'code')).to eq('not_found')
      expect(document.dig('error', 'details')).to eq(RecordSet.type_names)
    end
  end

  describe 'conditional requests' do
    it 'answers 304 for a matching If-None-Match' do
      get api_v1_profile_path
      etag = response.headers['ETag']

      get api_v1_profile_path, headers: { 'If-None-Match' => etag }

      expect(response).to have_http_status(:not_modified)
      expect(response.body).to be_empty
    end

    it 'serves the body again when the tag does not match' do
      get api_v1_profile_path, headers: { 'If-None-Match' => '"stale"' }

      expect(response).to have_http_status(:ok)
      expect(document['data']).to be_present
    end
  end
end
