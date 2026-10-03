# frozen_string_literal: true

require 'rails_helper'

# The manifest is a template the application ships even though no route renders
# it yet (see config/routes.rb). Rendering it directly keeps it compiling and
# its JSON valid; a template that only exists on disk is a template that rots.
RSpec.describe 'pwa/manifest' do
  before { render template: 'pwa/manifest', formats: [:json] }

  it 'renders valid JSON that names the site' do
    expect(JSON.parse(rendered)['name']).to eq('Portfolio')
  end

  it 'declares at least one icon' do
    expect(JSON.parse(rendered)['icons']).not_to be_empty
  end
end
