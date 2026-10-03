# frozen_string_literal: true

require 'rails_helper'

# The download is scanned here rather than in a `bin/ci` step of its own, for the
# same reason spec/requests/rendered_html_safety_spec.rb is a spec: the artifact
# does not exist on disk. `data/**` can be swept by a rake task because it is a
# directory; the PDF only exists once the application has built it, which needs
# the application booted. `bin/ci` runs the suite, so a leak still fails the
# build — it just fails at the step that can produce the bytes.
RSpec.describe 'Resume download' do
  subject(:bytes) { response.body }

  let(:scanner) { Content::SafetyScanner.new }

  # Every schema.org and PDF-metadata shape that would carry a contact channel
  # or an identity document. The scanner catches the values; this catches a
  # field added to the dictionary under a name nobody scans for.
  let(:forbidden_info_keys) do
    %i[Keywords Contact Telephone Phone Email Address Author_Email Location Company]
  end

  # A User-Agent Rails reads as too old to render the page. Several crawlers and
  # ingestion tools send one exactly like it.
  let(:legacy_browser) do
    'Mozilla/5.0 (Windows NT 6.1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/49.0.2623.112 Safari/537.36'
  end

  shared_examples 'a publication-safe download' do
    it 'responds with a PDF' do
      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/pdf')
      expect(bytes).to start_with('%PDF')
    end

    it 'offers it as a named file rather than rendering it in the tab' do
      expect(response.headers['Content-Disposition']).to include('attachment', %(filename="#{expected_filename}"))
    end

    it 'publishes nothing that must never be published' do
      findings = scanner.scan(pdf_text(bytes), source: expected_filename)

      expect(findings.map(&:to_s)).to be_empty
    end

    it 'carries the approved contact surface and nothing beside it' do
      text = pdf_text(bytes)

      expect(text).to include('mauricio@zaffari.casa')
      expect(text).not_to match(/\btel:/i)
      expect(text).to include(*Content.repository.site_profile(locale: 'en').record[:links]
        .map { |link| Resume.display_address(link[:url]) })
    end

    describe 'the document information dictionary' do
      subject(:info) { pdf_info(bytes) }

      it 'sets exactly the fields the application intends to set' do
        expect(info.keys).to contain_exactly(:Title, :Author, :Subject, :Creator, :Producer, :CreationDate, :ModDate)
      end

      it 'holds no field outside that set that could carry a contact channel' do
        expect(info.keys & forbidden_info_keys).to be_empty
      end

      # The two dates are excluded and asserted by shape instead. A PDF date
      # literal is fourteen consecutive digits by definition, which the
      # unpunctuated-document-number rule is right to object to in prose and
      # cannot usefully object to here.
      it 'publishes nothing in its values that must never be published' do
        readable = info.except(:CreationDate, :ModDate).values.join("\n")

        expect(scanner.scan(readable, source: "#{expected_filename}:info").map(&:to_s)).to be_empty
      end

      it 'carries a date and only a date in its date fields' do
        expect(info.values_at(:CreationDate, :ModDate)).to all(match(/\AD:\d{14}\+00'00'\z/))
      end

      it 'names no tool and no version' do
        expect(info.values.join(' ')).not_to include('Prawn', 'Ruby on Rails 8', RUBY_VERSION)
      end
    end

    # The base fonts are not embedded, so nothing about this machine should be
    # reachable from the file. Asserted against the raw bytes, because a font
    # path or a working directory would sit outside the text layer where the
    # scan above cannot see it.
    it 'discloses no filesystem path from the machine that built it' do
      expect(bytes).not_to include(Rails.root.to_s)
      expect(bytes).not_to include(Dir.home)
      expect(bytes).not_to match(%r{/(?:home|Users|var|usr|tmp)/})
      expect(bytes).not_to include('.afm', '.ttf')
    end

    it 'embeds no font file, so nothing about this machine travels with it' do
      expect(bytes).not_to include('FontFile')
    end

    it 'carries the same hardened headers as every other response' do
      expect(response.headers['X-Content-Type-Options']).to eq('nosniff')
      expect(response.headers['Content-Security-Policy']).to include("default-src 'none'")
    end

    # The defect site-metadata found on robots.txt and sitemap.xml, locked here
    # too: `allow_browser` gates on the User-Agent, and an applicant tracking
    # system fetching this file is not a browser. A 406 would be
    # indistinguishable from the document not existing.
    it 'answers a client that does not look like a modern browser' do
      get request.path, headers: { 'HTTP_USER_AGENT' => legacy_browser }

      expect(response).to have_http_status(:ok)
      expect(response.media_type).to eq('application/pdf')
    end
  end

  describe 'GET /resume.pdf' do
    before { get resume_path }

    let(:expected_filename) { 'mauricio-zaffari-resume.pdf' }

    it_behaves_like 'a publication-safe download'

    it 'is set in the locale it was asked for' do
      expect(pdf_text(bytes)).to include(I18n.t('landing.impact.heading', locale: 'en').upcase)
    end

    it 'marks nothing as substituted, because every record is already in this locale' do
      expect(pdf_text(bytes)).not_to include(I18n.t('landing.substitution.notice', locale: 'pt-BR'))
    end
  end

  describe 'GET /pt-BR/resume.pdf' do
    before { get portuguese_resume_path }

    let(:expected_filename) { 'mauricio-zaffari-curriculo.pdf' }

    it_behaves_like 'a publication-safe download'

    it 'sets the chrome in Portuguese, not only the records' do
      expect(pdf_text(bytes)).to include(I18n.t('landing.impact.heading', locale: 'pt-BR').upcase)
    end
  end

  # The page's substitution notice and per-entry marks, in the surface that cannot
  # be corrected once it has been fetched. Both locales in data/ are complete now,
  # so the document substitutes nothing and this is driven from a fixture rather
  # than from the accident of a corpus that was still being translated. See the
  # same move in spec/requests/landing_spec.rb.
  describe 'GET /pt-BR/resume.pdf when a record has no counterpart in that locale' do
    before do
      serve_fixture_corpus
      write_locale_singletons(locale: 'en')
      write_record('rails-years', type: 'metric', locale: 'en')

      get portuguese_resume_path
    end

    # The page marks a borrowed record in two places and so does the document:
    # once at the top for the reader who reads it as a whole, and once per entry
    # for the reader who lands in the middle of it.
    it 'says out loud which entries are not in the language it promised' do
      expect(pdf_flowed(bytes)).to include(I18n.t('landing.substitution.notice', locale: 'pt-BR'))
      expect(pdf_text(bytes)).to include("[#{I18n.t('landing.languages.code.en', locale: 'pt-BR')}]")
    end
  end

  describe "the landing page's offer of it" do
    it 'links to the document for the locale it is serving' do
      get root_path
      expect(response.body).to include(%(href="#{resume_path}"))

      get portuguese_root_path
      expect(response.body).to include(%(href="#{portuguese_resume_path}"))
    end
  end

  # A scan that cannot fail is decoration. This builds a PDF out of the same
  # synthetic fixture that proves the scanner's rules still fire over `data/**`,
  # then asserts the round trip through Prawn and back through the text
  # extractor launders none of them — which is the only thing that makes the
  # clean result above mean anything.
  describe 'the scan that guards it' do
    let(:fixture) { Rails.root.join('spec/fixtures/unsafe-record.md') }

    def unsafe_document
      lines = fixture.read.lines.map(&:chomp)

      Prawn::Document.new(page_size: 'A4', margin: 24) do |document|
        document.font('Helvetica', size: 8) { lines.each { |line| document.text(line.presence || ' ') } }
      end.render
    end

    it 'finds in the extracted text every shape it finds in the source' do
      from_source = scanner.scan_file(fixture, source: 'unsafe-record.md').map(&:reason).uniq.sort
      from_pdf = scanner.scan(pdf_text(unsafe_document), source: 'unsafe-record.pdf').map(&:reason).uniq.sort

      expect(from_source).to match_array(Content::SafetyScanner::RULES.map(&:name))
      expect(from_pdf).to eq(from_source)
    end
  end
end
