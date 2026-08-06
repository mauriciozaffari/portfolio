require "rails_helper"

# Driven against the real corpus rather than a fixture, because on this site the
# corpus is the page: a synthetic tree would prove the template compiles and
# nothing about what ships. The one exception is the block at the end, which
# needs a draft record and data/ correctly holds none.
RSpec.describe "Landing page", type: :request do
  def page_document
    @page_document ||= Nokogiri::HTML5(response.body)
  end

  def profile
    Content.repository.site_profile(locale: "en").record
  end

  def sections
    [ "positioning", "impact", "experience", "work", "leadership", "projects", "skills", "contact" ]
  end

  def heading_levels
    page_document.css("h1, h2, h3, h4, h5, h6").map { |heading| heading.name.delete_prefix("h").to_i }
  end

  shared_examples "the landing page" do
    it "responds successfully" do
      expect(response).to have_http_status(:ok)
    end

    it "renders every section in narrative order" do
      expect(page_document.css("[id]").map { |node| node["id"] }).to include(*sections)
    end

    it "carries the landmark elements" do
      expect(page_document.at_css("header")).to be_present
      expect(page_document.at_css("nav")).to be_present
      expect(page_document.at_css("main")).to be_present
      expect(page_document.at_css("footer")).to be_present
    end

    it "has exactly one h1" do
      expect(page_document.css("h1").size).to eq(1)
    end

    it "opens at h1 and skips no heading level" do
      expect(heading_levels.first).to eq(1)
      expect(heading_levels.each_cons(2).select { |shallower, deeper| deeper - shallower > 1 }).to be_empty
    end

    it "takes the name and the headline from site_profile and nowhere else" do
      expect(page_document.at_css("h1").text.strip).to eq(profile[:name])
      expect(response.body).to include(profile[:headline])
    end

    it "resolves every in-page anchor to an element that exists" do
      targets = page_document.css("a[href^='#']").map { |anchor| anchor["href"].delete_prefix("#") }

      expect(targets).not_to be_empty
      expect(targets.reject { |id| page_document.at_css("##{id}") }).to be_empty
    end

    it "publishes only the approved contact links" do
      expect(page_document.css("footer a[href]:not([href^='#'])").map { |anchor| anchor["href"] })
        .to match_array(profile[:links].map { |link| link[:url] })
    end

    it "offers both canonical locale URLs and marks the current one" do
      switcher = page_document.css("nav[aria-label] a[href='/'], nav[aria-label] a[href='/pt-BR']")

      expect(switcher.map { |anchor| anchor["href"] }).to contain_exactly("/", "/pt-BR")
      expect(switcher.select { |anchor| anchor["aria-current"] == "page" }.size).to eq(1)
    end

    it "leaves no translation unresolved" do
      expect(response.body).not_to include("translation missing")
    end

    # Scoped to the rels that actually fetch something. `canonical` and
    # `alternate` are absolute by definition — an origin-relative canonical URL
    # is not one — and they cost no request, so including them here would have
    # forced site-metadata to choose between a correct canonical and a green
    # spec. What they point at is asserted in spec/requests/site_metadata_spec.rb.
    it "loads no third-party origin and no web font" do
      urls = page_document.css("link[rel~='stylesheet'], link[rel~='icon'], link[rel~='apple-touch-icon'], script[src]")
                          .map { |node| node["href"] || node["src"] }

      expect(urls).not_to be_empty
      expect(urls).to all(start_with("/"))
      expect(response.body).not_to include("@font-face")
    end
  end

  describe "GET /" do
    before { get root_path }

    include_examples "the landing page"

    it "declares the locale it serves" do
      expect(page_document.at_css("html")["lang"]).to eq("en")
    end

    it "substitutes nothing, because every record is already in this locale" do
      expect(page_document.css("[data-substituted]")).to be_empty
      expect(page_document.css(".marker")).to be_empty
    end

    it "cannot be switched to another locale by the query string" do
      get root_path(locale: "pt-BR")

      expect(Nokogiri::HTML5(response.body).at_css("html")["lang"]).to eq("en")
    end
  end

  describe "GET /pt-BR" do
    before { get portuguese_root_path }

    include_examples "the landing page"

    it "declares the locale it serves" do
      expect(page_document.at_css("html")["lang"]).to eq("pt-BR")
    end

    it "translates the page frame around the records it could not translate" do
      expect(page_document.at_css("nav[aria-label]")["aria-label"]).to eq(I18n.t("landing.navigation.label", locale: "pt-BR"))
    end

    it "tells the reader once that entries were substituted" do
      expect(response.body).to include(I18n.t("landing.substitution.notice", locale: "pt-BR"))
    end

    it "marks every substituted container and gives it the language actually shown" do
      substituted = page_document.css("[data-substituted]")

      expect(substituted).not_to be_empty
      expect(substituted.map { |node| node["lang"] }).to all(eq("en"))
      expect(page_document.css(".marker").size).to eq(substituted.size)
    end

    it "explains the substitution to a reader who cannot see the marker" do
      expect(page_document.at_css(".marker")["aria-hidden"]).to eq("true")
      expect(response.body).to include(I18n.t("landing.substitution.record", language: I18n.t("landing.languages.name.en", locale: "pt-BR"), locale: "pt-BR"))
    end
  end

  # The section index is chrome and is translated in full. It used to take the
  # leadership label from that record's `title`, which put an English heading in
  # the middle of a Portuguese navigation with no way to mark it as substituted —
  # an index entry cannot carry a marker the way a section can.
  describe "the section index across both locales" do
    def section_nav_labels
      Nokogiri::HTML5(response.body).css("header nav a[href^='#']").map { |anchor| anchor.text.strip }
    end

    it "indexes every section except the masthead, which is the page's own title" do
      get root_path

      expect(section_nav_labels.size).to eq(sections.size - 1)
    end

    it "leaves no label in English on the Portuguese page" do
      get root_path
      english = section_nav_labels

      get portuguese_root_path
      portuguese = section_nav_labels

      expect(portuguese.size).to eq(english.size)
      expect(portuguese & english).to be_empty
    end

    it "does not take the leadership label from the record whose heading it points at" do
      get portuguese_root_path

      title = Content.repository.leadership(locale: "pt-BR").record[:title]

      expect(section_nav_labels).to include(I18n.t("landing.leadership.heading", locale: "pt-BR"))
      expect(section_nav_labels).not_to include(title)
    end

    it "still renders the record's own title as the leadership heading, substituted and marked" do
      get portuguese_root_path

      heading = Nokogiri::HTML5(response.body).at_css("#leadership-heading")
      section = Nokogiri::HTML5(response.body).at_css("#leadership")

      expect(heading.text.strip).to eq(Content.repository.leadership(locale: "pt-BR").record[:title])
      expect(section["lang"]).to eq("en")
      expect(section.at_css(".marker")).to be_present
    end
  end

  describe "records the loader hides" do
    before do
      Content.remove_instance_variable(:@repository) if Content.instance_variable_defined?(:@repository)
      allow(Content).to receive(:root).and_return(content_root)

      write_record("site-profile", type: "site_profile", links: [ { "label" => "GitHub", "url" => "https://example.com" } ])
      write_record("leadership", type: "leadership")
      write_record("published-metric", type: "metric", label: "Published")
      write_record("draft-metric", type: "metric", label: "Draft", status: "draft")
      write_record("restricted-metric", type: "metric", label: "Restricted", status: "draft", confidentiality: "restricted")
    end

    after { Content.remove_instance_variable(:@repository) if Content.instance_variable_defined?(:@repository) }

    it "renders the published record and neither of the others" do
      get root_path

      expect(response.body).to include("Published")
      expect(response.body).not_to include("Draft")
      expect(response.body).not_to include("Restricted")
    end
  end
end
