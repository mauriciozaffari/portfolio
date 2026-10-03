# frozen_string_literal: true

require 'rails_helper'

RSpec.describe LandingPageMarkdown do
  subject(:document) { described_class.new(page:).render }

  let(:page) { LandingPage.new(repository: Content.repository, locale: 'en') }

  it 'opens with YAML front matter carrying the canonical URL and locale' do
    front_matter = document.split("---\n")[1]

    expect(document).to start_with("---\n")
    expect(front_matter).to include("canonical: #{SiteMetadata.url_for('en')}")
    expect(front_matter).to include('last-updated:')
    expect(front_matter).to include('locale: en')
  end

  it 'starts the body with the name and headline as an h1' do
    expect(document).to include("# #{page.profile.record[:name]} — #{page.profile.record[:headline]}")
  end

  it 'renders every section the page renders' do
    expect(document).to include(
      '## Impact', '## Experience', '## Selected work', '## How I work',
      '## Open source', '## Skills', '## Contact'
    )
  end

  it 'quotes the impact figures from the records rather than inventing any' do
    metric = page.metrics.first.record

    expect(document).to include(metric[:value].to_s)
    expect(document).to include(metric[:label].to_s)
  end

  it 'links each open-source project to its record URL' do
    project = page.projects.first.record

    expect(document).to include("[#{project[:name]}](#{project[:url]})")
  end

  it 'lists the education entries under skills' do
    education = page.education.first.record

    expect(document).to include(education[:credential], education[:institution], education[:year].to_s)
  end

  it 'offers the resume for the locale' do
    expect(document).to include("#{SiteMetadata.origin}#{Resume.path_for('en')}")
  end

  it 'serves the Portuguese document in that locale, with its own headings' do
    pt = described_class.new(page: LandingPage.new(repository: Content.repository, locale: 'pt-BR')).render

    expect(pt).to include('locale: pt-BR')
    expect(pt).to include('## Experiência')
  end
end
