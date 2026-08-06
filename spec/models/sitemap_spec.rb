require "rails_helper"

RSpec.describe Sitemap do
  subject(:sitemap) { described_class.new(repository: load_repository) }

  def entry_for(locale) = sitemap.entries.find { |entry| entry.url == SiteMetadata.url_for(locale) }

  it "covers every locale, at its canonical URL" do
    write_locale_singletons

    expect(sitemap.entries.map(&:url)).to eq(Content::Schema::LOCALES.map { |locale| SiteMetadata.url_for(locale) })
  end

  # The whole point of the field. Build time would mark both URLs as modified on
  # every deploy, which teaches a crawler to ignore lastmod entirely.
  it "reports when the content changed rather than when the container was built" do
    write_locale_singletons
    write_record("newest-metric", type: "metric", updated: "2019-03-04")

    expect(entry_for("en").last_modified).to eq(Date.new(2026, 1, 1))
    expect(sitemap.entries.map(&:last_modified)).not_to include(Date.current)
  end

  it "takes the newest date among the records the page actually renders" do
    write_locale_singletons
    write_record("older", type: "metric", label: "Older", updated: "2020-05-06")
    write_record("newer", type: "metric", label: "Newer", updated: "2026-07-08")

    expect(entry_for("en").last_modified).to eq(Date.new(2026, 7, 8))
  end

  it "ignores a record no reader can reach" do
    write_locale_singletons
    write_record("draft", type: "metric", label: "Draft", status: "draft", updated: "2030-01-01")

    expect(entry_for("en").last_modified).to eq(Date.new(2026, 1, 1))
  end

  # /pt-BR serves the English records under the loader's fallback, so its
  # lastmod is theirs. Reporting nothing would tell a crawler the URL has no
  # content, which is not what it serves.
  it "dates a fallback locale from the records it actually shows" do
    write_locale_singletons
    write_record("only-english", type: "metric", label: "Only English", updated: "2026-09-10")

    expect(entry_for("pt-BR").last_modified).to eq(entry_for("en").last_modified)
  end

  it "matches the corpus that actually ships" do
    newest = Content.repository.renderable.map { |record| Date.parse(record.updated.to_s) }.max

    expect(described_class.new(repository: Content.repository).entries.map(&:last_modified)).to all(eq(newest))
  end
end
