# frozen_string_literal: true

require 'rails_helper'

# The empty sides of the Markdown renderer. The published corpus holds every
# record type, so the branches that only fire on a thin corpus — no metrics, no
# education, a project with no download count, and no readable date on any
# record — are described here with a throwaway tree rather than by adding a
# record to data/ that exists only to be counted.
RSpec.describe LandingPageMarkdown do
  context 'with a minimal corpus' do
    subject(:document) { described_class.new(page:).render }

    let(:page) { LandingPage.new(repository: load_repository, locale: 'en') }

    before do
      write_record('site-profile', type: 'site_profile', updated: 'not-a-date', body: 'Opening paragraph.')
      write_record('leadership', type: 'leadership', updated: 'not-a-date', body: 'How I work.')
      write_record('a-project', type: 'open_source', updated: 'not-a-date', body: 'A project.')
    end

    it 'omits last-updated rather than inventing a date' do
      expect(document).not_to include('last-updated:')
      expect(document).to include('locale: en')
    end

    it 'still renders the masthead, the leadership statement, and the project' do
      expect(document).to include('# Example Person — Example headline')
      expect(document).to include('## Example title')
      expect(document).to include('A project.')
    end

    it 'omits the sections the corpus has nothing for' do
      expect(document).not_to include('## Impact', '## Experience', '## Selected work', '## Skills', '### Education')
    end

    it 'omits the download count for a project that has none' do
      expect(document).not_to include('downloads')
    end

    it 'omits dateModified from the structured data when no record carries a readable date' do
      node = SiteMetadata.new(page:).graph_document.to_h['@graph'].find { |item| item['@type'] == 'ProfilePage' }

      expect(node).not_to have_key('dateModified')
    end
  end
end
