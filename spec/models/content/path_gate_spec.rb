# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Content::PathGate do
  describe 'this application' do
    it 'names no filesystem path outside its own root' do
      findings = described_class.new(Rails.root).findings

      expect(findings.map(&:to_s)).to be_empty
    end

    it 'skips its own source, which necessarily spells out the literals it hunts' do
      own_source = Rails.root.join('app/models/content/path_gate.rb').read

      expect(described_class::PATTERNS).to include(satisfy { |pattern| pattern.match?(own_source) })
      expect(described_class::SKIPPED).to include('app/models/content/path_gate.rb')
    end
  end

  describe 'an application that does' do
    let(:tmpdir) { Dir.mktmpdir('path-gate-spec') }
    let(:root) { Pathname(tmpdir) }

    after do
      FileUtils.remove_entry(tmpdir)
    end

    def write(relative_path, contents)
      root.join(relative_path).tap do |path|
        path.dirname.mkpath
        path.write(contents)
      end
    end

    def findings
      described_class.new(root).findings
    end

    it 'reports an absolute path into a home directory, with its location' do
      write 'app/models/curation.rb', %(SOURCE = "/home/someone/private"\n)

      expect(findings.map(&:to_s)).to eq(["app/models/curation.rb:1: #{described_class::REASON}"])
    end

    it 'skips a file that is not valid UTF-8, which is bytes rather than code' do
      root.join('app/models').mkpath
      root.join('app/models/binary.rb').binwrite("/home/someone/private\n\xFF\xFE".b)

      expect(findings).to be_empty
    end

    it 'reports a tilde path' do
      write 'lib/curation.rb', %(SOURCE = "~/private"\n)

      expect(findings).not_to be_empty
    end

    it 'reports a mounted volume' do
      write 'config/initializers/curation.rb', %(SOURCE = "/media/volume/private"\n)

      expect(findings).not_to be_empty
    end

    it 'leaves a URL path that merely looks like one alone' do
      write 'app/views/link.rb', %(LINK = "https://example.com/home/page"\n)

      expect(findings).to be_empty
    end

    it 'looks no further than app, lib and config' do
      write 'spec/curation_spec.rb', %(SOURCE = "/home/someone/private"\n)

      expect(findings).to be_empty
    end

    it 'skips key material, which is opaque bytes rather than code' do
      write 'config/master.key', "0123456789abcdef0123456789abcdef\n"
      write 'config/credentials.yml.enc', "/home/is/just/base64/noise\n"

      expect(findings).to be_empty
    end
  end
end
