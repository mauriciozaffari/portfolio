# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SiteMetadata do
  subject(:metadata) { described_class.new(page:) }

  let(:page) { LandingPage.new(repository: load_repository, locale: 'en') }

  def write_profile(**overrides)
    write_record('site-profile', type: 'site_profile',
                                 links: [{ 'label' => 'GitHub', 'url' => 'https://github.com/example' }], **overrides)
    write_record('leadership', type: 'leadership')
  end

  describe 'the canonical origin' do
    it 'is fixed rather than taken from whichever host answered' do
      expect(described_class.origin).to eq('https://zaffari.casa')
      expect(described_class.url_for('en')).to eq('https://zaffari.casa/')
      expect(described_class.url_for('pt-BR')).to eq('https://zaffari.casa/pt-BR')
    end

    it 'takes both locale paths from the routing table, so the switcher cannot disagree with the canonical' do
      expect(described_class.path_for('en')).to eq(Rails.application.routes.url_helpers.root_path)
      expect(described_class.path_for('pt-BR')).to eq(Rails.application.routes.url_helpers.portuguese_root_path)
    end
  end

  describe 'alternates' do
    it 'advertises every locale reciprocally plus an x-default, whichever page is being rendered' do
      expect(described_class.alternates).to eq([
                                                 { hreflang: 'en', href: 'https://zaffari.casa/' },
                                                 { hreflang: 'pt-BR', href: 'https://zaffari.casa/pt-BR' },
                                                 { hreflang: 'x-default', href: 'https://zaffari.casa/' }
                                               ])
    end

    it 'covers every locale the schema admits, so adding one cannot leave it unadvertised' do
      advertised = described_class.alternates.pluck(:hreflang)

      expect(advertised).to include(*Content::Schema::LOCALES)
    end
  end

  describe '#description' do
    it "takes whole sentences from the profile's opening paragraph, up to the budget" do
      write_profile(body: "One. Two is longer than one. #{'Three ' * 60}.\n\nA second paragraph.")

      expect(metadata.description).to eq('One. Two is longer than one.')
    end

    it 'keeps the first sentence even when it alone exceeds the budget, rather than emitting nothing' do
      write_profile(body: "#{'A sentence that will not fit ' * 12}end.")

      expect(metadata.description.length).to be > described_class::DESCRIPTION_BUDGET
      expect(metadata.description).to end_with('end.')
    end

    it 'reads the rendered body, so a link in the record becomes words rather than syntax' do
      write_profile(body: 'Ships [a gem](https://example.com/gem) that people use.')

      expect(metadata.description).to eq('Ships a gem that people use.')
    end

    it 'describes a profile whose body opens with no paragraph at all' do
      write_profile(body: '# A heading and nothing else')

      expect(metadata.description).to eq('')
    end

    it 'stays inside the budget against the corpus that actually ships' do
      real = described_class.new(page: LandingPage.new(repository: Content.repository, locale: 'en'))

      expect(real.description.length).to be <= described_class::DESCRIPTION_BUDGET
    end
  end

  describe '#person' do
    it 'builds every field from the record and invents none of them' do
      write_profile(name: 'Example Person', headline: 'Example headline')

      expect(metadata.person).to eq(
        '@context' => 'https://schema.org',
        '@type' => 'Person',
        '@id' => 'https://zaffari.casa/#person',
        'name' => 'Example Person',
        'jobTitle' => 'Example headline',
        'url' => 'https://zaffari.casa/',
        'sameAs' => ['https://github.com/example']
      )
    end

    # The allowlist's fourth entry is a mailto:, and schema.org's field for one
    # is `email`. Selecting sameAs by scheme keeps it out structurally, so this
    # holds for a link the record has not grown yet.
    it 'keeps a mailto out of sameAs, which is for profiles rather than contact channels' do
      write_profile(links: [
                      { 'label' => 'GitHub', 'url' => 'https://github.com/example' },
                      { 'label' => 'Email', 'url' => 'mailto:someone@example.com' }
                    ])

      expect(metadata.person['sameAs']).to eq(['https://github.com/example'])
      expect(metadata.person_json).not_to include('mailto')
    end

    it 'escapes a closing script tag hidden in a record value' do
      write_profile(name: 'Example </script><script>alert(1)</script>')

      expect(metadata.person_json).not_to include('</script>')
      expect(JSON.parse(metadata.person_json)['name']).to include('</script>')
    end
  end

  describe 'open graph locales' do
    it "names the current locale and every other one in Facebook's territory form" do
      expect(metadata.open_graph_locale).to eq('en_US')
      expect(metadata.alternate_open_graph_locales).to eq(['pt_BR'])
    end

    it 'has a mapping for every locale the schema admits' do
      expect(described_class::OPEN_GRAPH_LOCALES.keys).to match_array(Content::Schema::LOCALES)
    end
  end
end
