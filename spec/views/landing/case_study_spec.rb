# frozen_string_literal: true

require 'rails_helper'

# The partial branches on whether a case study names any technologies. The
# schema requires the key, so the empty case can only be built without
# validation; the populated one is here so the assertion above means something.
RSpec.describe 'landing/case_study' do
  def entry(technologies)
    file = Content::RecordFile.new(source: 'en/example.md', directory_locale: 'en', filename_id: 'example',
                                   front_matter: { 'title' => 'A study', 'organization' => 'An org',
                                                   'period' => '2024', 'technologies' => technologies },
                                   body: '<p>Body.</p>')
    Content::Localized.new(record: Content::Record.new(file:), requested_locale: 'en')
  end

  it 'renders a case study that names no technologies without a technologies list' do
    render partial: 'landing/case_study', locals: { entry: entry([]) }

    expect(rendered).to include('A study')
    expect(rendered).not_to include(I18n.t('landing.work.technologies'))
  end

  it 'renders the technologies a case study does name' do
    render partial: 'landing/case_study', locals: { entry: entry(['Ruby']) }

    expect(rendered).to include(I18n.t('landing.work.technologies'), 'Ruby')
  end
end
