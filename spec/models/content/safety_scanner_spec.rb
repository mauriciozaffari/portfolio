# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Content::SafetyScanner do
  subject(:scanner) { described_class.new }

  let(:unsafe_fixture) { Rails.root.join('spec/fixtures/unsafe-record.md') }

  describe 'the rule set' do
    it 'fires every rule it declares against the unsafe fixture' do
      reasons = scanner.scan_file(unsafe_fixture, source: 'unsafe-record.md').map(&:reason).uniq

      expect(reasons).to match_array(described_class::RULES.map(&:name))
    end

    it 'names the file and the line, and never the value it caught' do
      finding = scanner.scan('Write to nobody@example.invalid.', source: 'data/en/x.md').first

      expect(finding.to_s).to eq('data/en/x.md:1: email address')
    end
  end

  describe 'the published corpus' do
    it 'carries nothing that must never be published' do
      findings = scanner.scan_tree(Rails.root.join('data'))

      expect(findings.map(&:to_s)).to be_empty
    end
  end

  describe 'the contact allowlist' do
    it 'admits the one approved address' do
      expect(scanner.scan('Write to mauricio@zaffari.casa.', source: 'x')).to be_empty
    end

    it 'rejects another address on the same domain' do
      expect(scanner.scan('Write to someone.else@zaffari.casa.', source: 'x')).not_to be_empty
    end

    it 'rejects a second address sharing a line with the approved one' do
      line = 'mauricio@zaffari.casa and nobody@example.invalid'

      expect(scanner.scan(line, source: 'x')).not_to be_empty
    end
  end

  describe 'content that legitimately looks risky' do
    it 'passes figures, percentages and currency' do
      line = 'R$ 482,800+ across 3,603 charges, 720,962 downloads, 98.6% coverage, 244,000 lines.'

      expect(scanner.scan(line, source: 'x')).to be_empty
    end

    it 'passes prose about authentication' do
      line = 'OIDC integration, bearer-token verification, and token handling.'

      expect(scanner.scan(line, source: 'x')).to be_empty
    end

    it 'passes a date range written with spaces' do
      expect(scanner.scan('period: 2021 - 2022', source: 'x')).to be_empty
    end
  end

  describe 'rendered HTML' do
    it 'catches a value that only becomes visible once the Markdown is rendered' do
      html = Content::Markdown.to_html('Reach me at <nobody@example.invalid>.')

      expect(scanner.scan_html(html, source: '/').map(&:reason)).to include('email address')
    end

    it 'ignores a Propshaft asset digest that happens to be all digits' do
      html = %(<link href="/assets/tailwind-03422800.css"><script src="/assets/application-12345678.js"></script>)

      expect(scanner.scan_html(html, source: '/')).to be_empty
    end

    it 'still catches an unpunctuated document number in the page itself' do
      expect(scanner.scan_html('<p>00000000000</p>', source: '/').map(&:reason))
        .to include('unpunctuated document number')
    end
  end

  describe 'scanning a tree' do
    it 'reports a file it cannot read as text, because data/ holds Markdown only' do
      write_file('en/clean.md', "Nothing to see.\n")
      content_root.join('en/scan.md').binwrite("\xFF\xFE not text".b)

      expect(scanner.scan_tree(content_root).map(&:reason)).to include('is not UTF-8 text')
    end

    # Ruby's glob skips a leading dot unless asked not to, so the scan used to
    # walk straight past a file named to be inconspicuous. Both gates over data/
    # shared that blind spot; see Content.files_under.
    it 'reads a file hidden behind a leading dot' do
      write_file('en/.private-source.md', "CPF 123.456.789-00\n")

      expect(scanner.scan_tree(content_root).map(&:reason)).to include('CPF')
    end

    it 'reads a file inside a hidden directory' do
      write_file('en/.sources/notes.md', "Write to nobody@example.invalid.\n")

      expect(scanner.scan_tree(content_root).map(&:reason)).to include('email address')
    end
  end
end
