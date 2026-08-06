require "rails_helper"

RSpec.describe HeadingLevels do
  it "demotes every heading by the offset" do
    html = "<h2>Problem</h2>\n<p>Body</p>\n<h3>Detail</h3>"

    expect(described_class.shift(html, by: 2)).to eq("<h4>Problem</h4>\n<p>Body</p>\n<h5>Detail</h5>")
  end

  it "leaves anything that is not a heading tag alone" do
    html = %(<p>A <code>h2</code> in prose, and <a href="/h3">a link</a>.</p>)

    expect(described_class.shift(html, by: 2)).to eq(html)
  end

  it "stops at h6 rather than inventing a level" do
    expect(described_class.shift("<h4>Deep</h4>", by: 4)).to eq("<h6>Deep</h6>")
  end

  it "returns markup a view renders rather than escapes" do
    expect(described_class.shift("<h2>Problem</h2>", by: 2)).to be_html_safe
  end

  # The offset of 2 the page uses is only correct while the sanitizer admits
  # nothing deeper than h4. If that allowlist widens, this fails first.
  it "covers every heading level the sanitizer admits" do
    expect(Content::Markdown::TAGS.grep(/\Ah\d\z/)).to eq([ "h2", "h3", "h4" ])
  end

  it "puts a real case study's own sections below the title the page gives it" do
    html = Content.repository.of_type(:case_study, locale: "en").first.record.html

    expect(html).to include("<h2>Problem</h2>")
    expect(described_class.shift(html, by: 2)).to include("<h4>Problem</h4>")
    expect(described_class.shift(html, by: 2)).not_to include("<h2>")
  end
end
