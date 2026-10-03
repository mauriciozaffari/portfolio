# frozen_string_literal: true

require 'rails_helper'

# The section renderer works from a record wrapper and a sheet. The schema
# requires a case study to name its technologies, so the "no technologies"
# guard is defensive: only a record built without validation can reach it, and
# that is exactly what this exercises.
RSpec.describe Resume::Sections do
  subject(:sections) { described_class.new(sheet:, helpers: ApplicationController.helpers) }

  let(:sheet) { Resume::Sheet.new(info: {}) }

  def localized(attributes, body: '')
    file = Content::RecordFile.new(source: 'en/example.md', directory_locale: 'en',
                                   filename_id: 'example', front_matter: attributes, body:)
    Content::Localized.new(record: Content::Record.new(file:), requested_locale: 'en')
  end

  it 'draws a case study that names no technologies without a technologies block' do
    entry = localized({ 'title' => 'A study', 'organization' => 'An org', 'period' => '2024',
                        'technologies' => [] }, body: '<p>What happened.</p>')

    sections.case_studies([entry])
    text = pdf_text(sheet.render)

    expect(text).to include('A study', 'What happened.')
    expect(text).not_to include(I18n.t('landing.work.technologies').upcase)
  end
end
