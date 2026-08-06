module Content
  # Turns a record body into HTML that is safe to embed.
  #
  # kramdown passes raw HTML through verbatim, so the renderer is not the
  # control here: the allowlist is. Anything a body contains that is not on it
  # never reaches a page, whatever the Markdown source looked like.
  module Markdown
    # Prose only. No embedded media, no tables, no ids or classes — a record
    # describes what it says, and the page decides how it looks.
    TAGS = [ "p", "br", "hr", "h2", "h3", "h4", "ul", "ol", "li", "strong", "em", "code", "pre", "blockquote", "a" ].freeze
    ATTRIBUTES = [ "href", "title" ].freeze

    # Heading ids are off because several case studies share "## Problem"; a
    # page composing them would emit duplicate ids.
    OPTIONS = { auto_ids: false }.freeze

    class << self
      def to_html(text)
        return ActiveSupport::SafeBuffer.new if text.blank?

        rendered = Kramdown::Document.new(text, **OPTIONS).to_html
        ActiveSupport::SafeBuffer.new(sanitizer.sanitize(rendered, tags: TAGS, attributes: ATTRIBUTES))
      end

      private
        def sanitizer
          @sanitizer ||= Rails::HTML5::SafeListSanitizer.new
        end
    end
  end
end
