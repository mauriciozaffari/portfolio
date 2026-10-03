# frozen_string_literal: true

require 'rails_helper'

# config/initializers/content.rb is loaded rather than restated here. Loading it
# runs its `after_initialize` block straight away — this process has already
# booted, so ActiveSupport replays the hook against the running application —
# which means these examples observe the real initializer taking the same branch
# production takes, rather than a copy of it that can drift.
RSpec.describe 'Boot', type: :request do
  def load_content_initializer
    load Rails.root.join('config/initializers/content.rb').to_s
  end

  describe 'the corpus' do
    before { serve_fixture_corpus }

    it 'stops the boot when a record is invalid, rather than the first request' do
      write_record('leadership', type: 'leadership')

      expect { load_content_initializer }
        .to raise_error(Content::InvalidRecord, /needs exactly one site_profile record/)
    end

    it 'is already in memory once the boot finishes' do
      write_locale_singletons

      load_content_initializer

      expect(Content.instance_variable_get(:@repository)).to be_a(Content::Repository)
    end

    it 'is left to rebuild per request where reloading is on, so development still picks up an edit' do
      allow(Rails.application.config).to receive(:enable_reloading).and_return(true)
      write_record('leadership', type: 'leadership')

      expect { load_content_initializer }.not_to raise_error
      expect(Content.instance_variable_defined?(:@repository)).to be(false)
    end
  end

  # The healthcheck is what a deploy waits on, and it is polled for the life of
  # the container. It is green because the corpus already loaded, not because it
  # loads one itself.
  describe 'GET /up' do
    it 'answers without reading the corpus' do
      allow(Content).to receive(:repository)

      get rails_health_check_path

      expect(response).to have_http_status(:ok)
      expect(Content).not_to have_received(:repository)
    end
  end
end
