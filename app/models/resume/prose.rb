class Resume
  # A record body, converted from HTML into the blocks Prawn draws.
  #
  # The input is `Content::Record#html` — the same sanitized markup the page
  # renders, not the Markdown source. That matters twice over: a link or an
  # emphasis added to a record later becomes formatting here rather than
  # syntax, and the conversion inherits Content::Markdown's allowlist instead of
  # trusting whatever kramdown was handed.
  #
  # Prawn's inline format looks like HTML and is not HTML: it understands six
  # tags and three entities, so the text is re-escaped on the way through with
  # Prawn's own escaper rather than with a general HTML one. `&quot;` and
  # `&#39;` would arrive on the page as literal character sequences.
  module Prose
    Block = Data.define(:kind, :text)

    # The block elements the sanitizer admits, and how each is set. `blockquote`
    # is absent on purpose: it is not in this set, so the paragraphs inside it
    # are collected on their own and set as prose. No record quotes anything
    # today, and inventing a pull-quote treatment for a case that does not exist
    # is the abstraction this project's style rules out.
    KINDS = {
      "h2" => :heading, "h3" => :heading, "h4" => :heading,
      "p" => :paragraph, "pre" => :code, "li" => :item
    }.freeze

    SELECTOR = KINDS.keys.join(", ").freeze

    # kramdown emits `<li>text</li>` for a tight list and `<li><p>text</p></li>`
    # for a loose one. Without this the second shape would be collected twice,
    # once as the item and once as the paragraph inside it.
    def self.blocks(html)
      Nokogiri::HTML5.fragment(html.to_s).css(SELECTOR).filter_map do |node|
        next if node.ancestors.any? { |ancestor| KINDS.key?(ancestor.name) }

        text = inline(node).strip
        Block.new(kind: KINDS.fetch(node.name), text: text) if text.present?
      end
    end

    def self.inline(node)
      node.children.map { |child| markup(child) }.join
    end

    def self.markup(node)
      return escape(node.text) if node.text?
      return "" unless node.element?

      case node.name
      when "strong", "b" then "<b>#{inline(node)}</b>"
      when "em", "i" then "<i>#{inline(node)}</i>"
      when "code" then %(<font name="#{Theme::MONO}" size="#{Theme::SIZE_SM}">#{inline(node)}</font>)
      when "br" then "\n"
      when "a" then link(node)
      else inline(node)
      end
    end
    private_class_method :markup

    # Left in the ink of the text around it, exactly as `.prose a` sets it. The
    # accent belongs on the underline rather than on the words, and that line is
    # drawn per fragment by Resume::AccentUnderline.
    def self.link(node)
      href = node["href"].to_s
      text = inline(node)
      return text if href.blank?

      %(<link href="#{escape(href)}">#{text}</link>)
    end
    private_class_method :link

    # Source line breaks are an artifact of how the Markdown was typed, and a
    # newline is a hard break to Prawn. Collapsed rather than squished, so the
    # single space between a `<strong>` and the word after it survives.
    def self.escape(text)
      Prawn::Text::Formatted::Parser.escape(text.gsub(/\s+/, " "))
    end
    private_class_method :escape
  end
end
