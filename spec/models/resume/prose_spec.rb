# frozen_string_literal: true

require 'rails_helper'

# The PDF's own view of a record body. Tested directly rather than only through
# a generated PDF, because the conversion is where a new inline element or a
# list shape either survives or is dropped, and reading it out of extracted PDF
# text cannot tell those apart.
RSpec.describe Resume::Prose do
  let(:prose) { described_class }

  it 'maps each block element the sanitizer admits to its kind' do
    html = <<~HTML
      <h2>Heading</h2>
      <p>Paragraph</p>
      <pre>code</pre>
      <ul><li>Item</li></ul>
    HTML

    expect(prose.blocks(html).map(&:kind)).to eq(%i[heading paragraph code item])
    expect(prose.blocks(html).map(&:text)).to eq(%w[Heading Paragraph code Item])
  end

  # A loose list arrives as `<li><p>text</p></li>`; without the ancestor check
  # it would be collected twice, once as the item and once as the paragraph.
  it 'collects a loose list item once, not also as the paragraph inside it' do
    expect(prose.blocks('<ul><li><p>Only once</p></li></ul>').map(&:text)).to eq(['Only once'])
  end

  it 'keeps the inline formatting Prawn understands' do
    expect(prose.blocks('<p>a <strong>bold</strong> and <em>italic</em> claim</p>').first.text)
      .to eq('a <b>bold</b> and <i>italic</i> claim')
    expect(prose.blocks('<p>run <code>bin/ci</code></p>').first.text).to include('<font name="Courier"')
  end

  it 'turns a line break into a hard break and a link into a Prawn link' do
    expect(prose.blocks('<p>one<br>two</p>').first.text).to eq("one\ntwo")
    expect(prose.blocks('<p>see <a href="https://example.com/x">the site</a></p>').first.text)
      .to eq('see <link href="https://example.com/x">the site</link>')
  end

  it 'leaves an anchor with no destination as its own text' do
    expect(prose.blocks('<p><a>plain</a></p>').first.text).to eq('plain')
  end

  it 'drops a block whose text is only whitespace' do
    expect(prose.blocks('<p>   </p><h2></h2>')).to be_empty
  end

  it 'ignores a non-element child such as a comment' do
    expect(prose.blocks('<p>before<!-- a comment -->after</p>').first.text).to eq('beforeafter')
  end
end
