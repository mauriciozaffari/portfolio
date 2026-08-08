require "rails_helper"

RSpec.describe Content::Repository do
  describe "the published corpus" do
    it "loads every record under data/" do
      repository = described_class.load(Rails.root.join("data"))

      expect(repository.records).to all(be_a(Content::Record))
      expect(repository.locales).to include("en")
    end
  end

  describe "what belongs in the tree" do
    it "rejects a file that is not a Markdown record" do
      write_locale_singletons
      write_file("en/resume.pdf", "not really a PDF")

      expect { load_repository }.to raise_error(Content::InvalidRecord, /Markdown records and nothing else.+en\/resume\.pdf/m)
    end

    # The stray-file gate walked the tree with a plain `glob("**/*")`, which
    # skips anything whose name begins with a dot. A private source document
    # dropped in as a dotfile was therefore invisible to the one check that
    # exists to catch it — on a repository that is public.
    it "rejects a stray file hidden behind a leading dot" do
      write_locale_singletons
      write_file("en/.private-source.pdf", "not really a PDF")

      expect { load_repository }.to raise_error(Content::InvalidRecord, %r{en/\.private-source\.pdf})
    end

    it "rejects a stray file inside a hidden directory" do
      write_locale_singletons
      write_file("en/.sources/resume.pdf", "not really a PDF")

      expect { load_repository }.to raise_error(Content::InvalidRecord, %r{en/\.sources/resume\.pdf})
    end
  end

  describe "cardinality" do
    it "rejects a locale with no site profile" do
      write_record("leadership", type: "leadership")

      expect { load_repository }.to raise_error(Content::InvalidRecord, /needs exactly one site_profile record, found 0/)
    end

    it "rejects a locale with two of a singular type" do
      write_locale_singletons
      write_record("second-profile", type: "site_profile")

      expect { load_repository }.to raise_error(Content::InvalidRecord, /needs exactly one site_profile record, found 2/)
    end

    it "counts each locale separately" do
      write_locale_singletons(locale: "en")
      write_locale_singletons(locale: "pt-BR")

      expect(load_repository.locales).to eq([ "en", "pt-BR" ])
    end
  end

  describe "what a view can reach" do
    before { write_locale_singletons }

    it "hides a draft record" do
      write_record("rails-years", type: "metric", status: "draft")

      expect(load_repository.of_type(:metric, locale: "en")).to be_empty
    end

    it "hides a restricted record" do
      write_record("rails-years", type: "metric", status: "draft", confidentiality: "restricted")

      expect(load_repository.of_type(:metric, locale: "en")).to be_empty
    end

    it "returns published, unrestricted records in id order" do
      write_record("zeta", type: "metric")
      write_record("alpha", type: "metric")

      ids = load_repository.of_type(:metric, locale: "en").map { |item| item.record.id }

      expect(ids).to eq([ "alpha", "zeta" ])
    end

    it "reaches the singular records by name" do
      repository = load_repository

      expect(repository.site_profile(locale: "en").record.type).to eq("site_profile")
      expect(repository.leadership(locale: "en").record.type).to eq("leadership")
    end
  end

  describe "locale fallback" do
    before do
      write_locale_singletons(locale: "en")
      write_locale_singletons(locale: "pt-BR")
    end

    it "serves the requested locale untouched when it exists" do
      write_record("rails-years", type: "metric", locale: "en")
      write_record("rails-years", type: "metric", locale: "pt-BR")

      item = load_repository.of_type(:metric, locale: "pt-BR").first

      expect(item).not_to be_substituted
      expect(item.language).to eq("pt-BR")
      expect(item.record.locale).to eq("pt-BR")
    end

    it "serves the other locale's record rather than an empty section" do
      write_record("rails-years", type: "metric", locale: "en")

      item = load_repository.of_type(:metric, locale: "pt-BR").first

      expect(item).to be_substituted
      expect(item.language).to eq("en")
    end

    it "pairs records across locales by shared id" do
      write_record("rails-years", type: "metric", locale: "en")
      write_record("rails-years", type: "metric", locale: "pt-BR")
      write_record("gem-downloads", type: "metric", locale: "en")

      items = load_repository.of_type(:metric, locale: "pt-BR")

      expect(items.map { |item| [ item.record.id, item.substituted? ] })
        .to eq([ [ "gem-downloads", true ], [ "rails-years", false ] ])
    end

    it "never substitutes a draft counterpart" do
      write_record("rails-years", type: "metric", locale: "en", status: "draft")

      expect(load_repository.of_type(:metric, locale: "pt-BR")).to be_empty
    end
  end

  describe "Content.repository" do
    before do
      serve_fixture_corpus
      write_locale_singletons
    end

    it "reads from disk once when reloading is off" do
      allow(Rails.application.config).to receive(:enable_reloading).and_return(false)
      first = Content.repository
      write_record("rails-years", type: "metric")

      expect(Content.repository).to equal(first)
      expect(Content.repository.of_type(:metric, locale: "en")).to be_empty
    end

    it "picks up an edit without a restart when reloading is on" do
      allow(Rails.application.config).to receive(:enable_reloading).and_return(true)
      expect(Content.repository.of_type(:metric, locale: "en")).to be_empty

      write_record("rails-years", type: "metric")

      expect(Content.repository.of_type(:metric, locale: "en").map { |item| item.record.id }).to eq([ "rails-years" ])
    end
  end
end
