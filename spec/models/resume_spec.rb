require "rails_helper"

RSpec.describe Resume do
  # The PDF is built lazily and reads I18n while it draws, so the locale has to
  # still be in force when the bytes are asked for — not only when the object is
  # constructed.
  def with_resume(locale, repository: Content.repository)
    I18n.with_locale(locale) do
      yield described_class.new(page: LandingPage.new(repository: repository, locale: locale))
    end
  end

  def profile(locale = "en")
    Content.repository.site_profile(locale: locale).record
  end

  describe ".path_for" do
    let(:routes) { Rails.application.routes.url_helpers }

    it "takes both locale paths from the routing table" do
      expect(described_class.path_for("en")).to eq(routes.resume_path)
      expect(described_class.path_for("pt-BR")).to eq(routes.portuguese_resume_path)
    end

    it "builds an absolute URL on the canonical origin" do
      expect(described_class.url_for("en")).to eq("#{SiteMetadata::ORIGIN}#{routes.resume_path}")
    end
  end

  describe ".display_address" do
    it "shows an address the way a printed page has to" do
      expect(described_class.display_address("https://www.linkedin.com/in/example")).to eq("linkedin.com/in/example")
      expect(described_class.display_address("https://example.com/")).to eq("example.com")
      expect(described_class.display_address("mailto:someone@example.com")).to eq("someone@example.com")
    end
  end

  describe "#filename" do
    it "names the file after the person, not after the route" do
      with_resume("en") { |resume| expect(resume.filename).to eq("#{profile[:name].parameterize}-resume.pdf") }
    end

    it "uses the locale's own noun" do
      with_resume("pt-BR") { |resume| expect(resume.filename).to eq("#{profile[:name].parameterize}-curriculo.pdf") }
    end
  end

  describe "#info" do
    subject(:info) { with_resume("en", &:info) }

    it "sets exactly the fields it intends to set" do
      expect(info.keys).to contain_exactly(:Title, :Author, :Subject, :Creator, :Producer, :CreationDate, :ModDate)
    end

    it "takes every value a reader can see from the record" do
      expect(info[:Author]).to eq(profile[:name])
      expect(info[:Subject]).to eq(profile[:headline])
      expect(info[:Title]).to eq(I18n.t("landing.document_title", name: profile[:name], headline: profile[:headline]))
    end

    # Prawn writes its own name into both fields when they are left alone. A
    # tool name is not a disclosure on its own, but the two fields that would
    # otherwise carry a default are the two nobody reviews.
    it "replaces the generator's own signature with the canonical host" do
      expect(info.values_at(:Creator, :Producer)).to all(eq(SiteMetadata.host))
      expect(info.values.join(" ")).not_to include("Prawn")
    end

    it "dates the document from the corpus rather than from the clock" do
      updated = with_resume("en") { |resume| resume.page.updated }

      expect(info[:CreationDate]).to eq(Time.utc(updated.year, updated.month, updated.day))
      expect(info[:ModDate]).to eq(info[:CreationDate])
      expect(info[:CreationDate].to_date).not_to eq(Date.current) if updated != Date.current
    end
  end

  describe "#pdf" do
    it "produces a PDF both locales can render" do
      %w[en pt-BR].each do |locale|
        with_resume(locale) do |resume|
          expect(resume.pdf).to start_with("%PDF")
          expect(pdf_reader(resume.pdf).page_count).to be_positive
        end
      end
    end

    # The base fonts cover WINDOWS-1252 and raise on anything else, so this is
    # the gate that turns a record carrying an unrepresentable character into a
    # failing build rather than a 500 on a download.
    it "can set every renderable record in the fonts it uses" do
      %w[en pt-BR].each do |locale|
        expect { with_resume(locale, &:pdf) }.not_to raise_error
      end
    end

    # Nothing is written to disk and nothing is cached, so the same corpus has
    # to produce the same file every time — otherwise two people comparing
    # downloads would see a diff that means nothing.
    it "produces the same bytes for the same corpus" do
      first = with_resume("en", &:pdf)
      second = with_resume("en") { |resume| described_class.new(page: resume.page).pdf }

      expect(first).to eq(second)
    end
  end

  describe "the records it draws from" do
    before do
      serve_fixture_corpus

      write_record("site-profile", type: "site_profile", name: "Example Person", headline: "Example headline",
        links: [ { "label" => "GitHub", "url" => "https://example.com/profile" } ])
      write_record("leadership", type: "leadership", title: "Leadership title", body: "Leadership prose.")
      write_record("published-metric", type: "metric", label: "Published label", value: "42", context: "Published context")
      write_record("published-skill", type: "skill_group", label: "Published skills", items: [ "Published item" ])
      write_record("published-school", type: "education", institution: "Published school", credential: "Published credential", year: "2011")
      write_record("draft-metric", type: "metric", label: "Draft label", value: "1", context: "Draft context", status: "draft")
      write_record("restricted-metric", type: "metric", label: "Restricted label", value: "2", context: "Restricted context",
        status: "draft", confidentiality: "restricted")
    end

    let(:text) { with_resume("en", repository: Content.repository, &:pdf).then { |bytes| pdf_text(bytes) } }

    # The SPEC's mitigation for the layout diverging from the page: every fact
    # in the document is selected out of a record, so the two surfaces cannot
    # disagree about what they say even while they disagree about how it looks.
    # The leadership record's `title` is the section's own label, and a section
    # label is set uppercase in both surfaces — the page does it in CSS, this
    # does it in Ruby.
    it "carries every renderable record" do
      expect(text).to include("Example Person", "Example headline", "LEADERSHIP TITLE", "Leadership prose.")
      expect(text).to include("42", "PUBLISHED LABEL", "Published context")
      expect(text).to include("PUBLISHED SKILLS", "Published item", "Published credential", "Published school")
    end

    it "cannot carry a draft or a restricted record" do
      expect(text).not_to include("Draft label", "Draft context", "Restricted label", "Restricted context")
    end

    it "shows the approved link as the address itself, so printing does not lose it" do
      expect(text).to include("example.com/profile")
    end
  end
end
