# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Concise resume download' do
  before { get authored_resume_path }

  let(:reader) { PDF::Reader.new(StringIO.new(response.body)) }
  let(:scanner) { Content::SafetyScanner.new }

  it 'serves the reviewed file as a named attachment' do
    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq('application/pdf')
    expect(response.body).to eq(Rails.root.join('downloads/mauricio-zaffari-resume.pdf').binread)
    expect(response.headers['Content-Disposition']).to include('attachment', 'mauricio-zaffari-resume.pdf')
  end

  it 'contains exactly two Letter pages' do
    expect(reader.page_count).to eq(2)
    expect(reader.pages.map { |page| page.attributes[:MediaBox] }).to all(eq([0, 0, 612, 792]))
  end

  it 'publishes scanner-clean text and deliberately limited metadata' do
    expect(scanner.scan(pdf_text(response.body), source: 'concise resume').map(&:to_s)).to be_empty
    expect(reader.info.keys).to contain_exactly(:Title, :Author, :Subject, :Creator, :Producer)
    expect(scanner.scan(reader.info.values.join("\n"), source: 'concise resume metadata').map(&:to_s)).to be_empty
    expect(reader.info.values_at(:Creator, :Producer)).to all(eq(SiteMetadata.host))
  end

  it 'ties selected facts to the published records' do
    text = pdf_text(response.body)
    profile = Content.repository.site_profile(locale: 'en').record

    metrics = Content.repository.of_type(:metric, locale: 'en').map(&:record)
    selected_values = metrics.select { |record| %w[test-coverage all-time-contribution].include?(record.id) }
                             .pluck(:value)

    expect(reader.info[:Author]).to eq(profile[:name])
    expect(reader.info[:Subject]).to eq('Lead / Staff Software Engineer | Ruby on Rails & AI Systems')
    expect(text).to include(reader.info[:Subject])
    expect(text).to include('Looper Insights', 'Lead Software Engineer', '81.7%', *selected_values)
    expect(text).not_to include('Senior Lead Software Engineer', 'Peter Cunningham')
  end

  it 'is available to legacy clients with hardened headers' do
    get authored_resume_path, headers: { 'HTTP_USER_AGENT' => 'Chrome/49.0.2623.112' }

    expect(response).to have_http_status(:ok)
    expect(response.headers['X-Content-Type-Options']).to eq('nosniff')
    expect(response.headers['Content-Security-Policy']).to include("default-src 'none'")
  end

  it 'offers the concise document before the complete locale-specific profile' do
    [root_path, portuguese_root_path, contact_path, portuguese_contact_path].each do |path|
      get path
      document = response.parsed_body
      links = document.css("a[href$='.pdf']").pluck('href')
      full_path = path.start_with?('/pt-BR') ? portuguese_resume_path : resume_path

      expect(links).to eq([authored_resume_path, full_path])
    end
  end
end
