class Resume
  # A sheet of paper and the vocabulary for setting type on it.
  #
  # This half knows Prawn and DESIGN.md and nothing at all about resumes:
  # rules, the gutter grid, the ink ramp, the widow guards, the running footer.
  # Resume::Document knows the records and calls the methods below, which is the
  # same division the page makes between its partials and the template that
  # composes them.
  class Sheet
    # The fourteen base fonts cover WINDOWS-1252 and nothing else, and Prawn
    # says so once per font per document. The warning is addressed to somebody
    # who has not made the decision yet; this project has, in Theme, and a
    # record carrying a character outside that set raises rather than warns —
    # loudly, at build time, in spec/models/resume_spec.rb.
    Prawn::Fonts::AFM.hide_m17n_warning = true

    MIDDOT = " \u00B7 ".freeze
    NOTICE_PADDING = 9

    attr_reader :pdf

    def initialize(info:)
      @pdf = Prawn::Document.new(page_size: Theme::PAGE_SIZE, margin: Theme::MARGIN, info: info)
      @pdf.on_page_create { fill_paper }
      @underline = AccentUnderline.new(@pdf)
      @ordinal = 0
      fill_paper
    end

    def render
      footers
      pdf.render
    end

    def gap(points)
      pdf.move_down points
    end

    # DESIGN.md 5's twelve-column grid: an ordinal and a label in the mono
    # gutter, the content in the wider column beside it.
    #
    # An indent rather than a second bounding box. Prawn carries a margin box's
    # padding onto each new page it generates, so a section longer than a page
    # keeps its column without any page-break bookkeeping here — and `cursor`
    # keeps meaning "room left", which inside a stretchy bounding box it does
    # not.
    def section(title, &block)
      gap Theme::SPACE_SECTION
      pdf.start_new_page if pdf.cursor < Theme::SECTION_ORPHAN
      rule Theme::RULE_STRONG, Theme::HAIRLINE_STRONG
      gap Theme::SPACE_CLOSE
      gutter_label(title, pdf.cursor)

      pdf.indent(Theme::GUTTER_WIDTH + Theme::GUTTER_GAP, &block)
    end

    # The masthead and the colophon sit outside the gutter grid, so they have
    # the full page width available and must not use it: DESIGN.md 3 caps prose
    # at a measure, and a full-width A4 line runs to about 105 characters. Held
    # to the same width the sections get, which is where the eye is going next.
    def measured(&block)
      pdf.indent(0, pdf.bounds.width - Theme.column_width(pdf.bounds.width), &block)
    end

    # A rule divides entries, so the first one in a list does not get one — the
    # section's own rule is already immediately above it. `always` is for the two
    # lists that open under a sub-heading instead, which is the same
    # `first:border-t-0` split the page makes.
    #
    # The guard keeps an entry's heading from being stranded at the foot of a
    # page with its prose overleaf. Prawn has no widow control of its own.
    def divider(index, color: Theme::RULE, width: Theme::HAIRLINE, always: false)
      first = index.zero? && !always

      gap Theme::SPACE_BLOCK unless first
      pdf.start_new_page if pdf.cursor < Theme::ENTRY_ORPHAN
      return if first

      rule(color, width)
      gap Theme::SPACE_CLOSE
    end

    def rule(color = Theme::RULE, width = Theme::HAIRLINE)
      pdf.stroke_color color
      pdf.line_width width
      pdf.stroke_horizontal_rule
    end

    # The one at-rest instance of the second ink, matching the share card and
    # the underline under the current locale in the page's switcher.
    def accented_rule
      top = pdf.cursor
      rule(Theme::RULE_STRONG, Theme::HAIRLINE_STRONG)
      pdf.stroke_color Theme::ACCENT
      pdf.line_width Theme::HAIRLINE_STRONG
      pdf.stroke_line [ 0, top ], [ Theme::ACCENT_SEGMENT, top ]
    end

    # DESIGN.md 5: a bordered box, because it is the one element that is not
    # part of the document's argument. Everything else is divided by rules.
    def notice(text)
      width = Theme.column_width(pdf.bounds.width)
      inner = width - (NOTICE_PADDING * 2)
      height = measure(Theme::MONO) { pdf.height_of(text, width: inner, size: Theme::SIZE_XS, leading: Theme::LEADING_TIGHT) }
      top = pdf.cursor

      pdf.stroke_color Theme::RULE_STRONG
      pdf.line_width Theme::HAIRLINE
      pdf.stroke_rectangle [ 0, top ], width, height + (NOTICE_PADDING * 2)

      pdf.bounding_box([ NOTICE_PADDING, top - NOTICE_PADDING ], width: inner, height: height) do
        mono text, size: Theme::SIZE_XS, color: Theme::INK_MUTED
      end

      pdf.move_cursor_to top - height - (NOTICE_PADDING * 2)
    end

    def keep_together(points = Theme::ENTRY_ORPHAN)
      pdf.start_new_page if pdf.cursor < points
    end

    # A block in the left column with a mono value flush right on its first
    # baseline, which is the only two-column row in the document. The block is
    # given the width it has to stay inside.
    def row(right)
      top = pdf.cursor
      width = measure(Theme::MONO) { pdf.width_of(right, size: Theme::SIZE_SM) }

      yield pdf.bounds.width - width - Theme::SPACE_CLOSE

      pdf.font(Theme::MONO) do
        pdf.fill_color Theme::INK
        pdf.text_box right, at: [ pdf.bounds.width - width, top ], width: width, size: Theme::SIZE_SM
      end
    end

    def label(text)
      mono text.to_s.upcase, size: Theme::SIZE_XS, color: Theme::INK_FAINT, character_spacing: Theme::TRACKING_XS
    end

    def meta(values)
      items = values.compact_blank
      return if items.empty?

      mono items.join(MIDDOT), size: Theme::SIZE_SM, color: Theme::INK_FAINT, character_spacing: Theme::TRACKING_SM
    end

    def sans(text, size:, color:, style: :normal, **options)
      write(Theme::SANS, text, size: size, color: color, style: style, **options)
    end

    def mono(text, size:, color:, style: :normal, **options)
      write(Theme::MONO, text, size: size, color: color, style: style, **options)
    end

    # Prawn's inline format is parsed rather than handed straight to `text`, so
    # that every link fragment can carry the accent underline DESIGN.md 5 gives
    # a link at rest. The tag syntax has no way to say "underline this in a
    # different ink from the text", and colouring the words themselves would
    # spend the second ink on something that is not a state.
    def formatted(string, size:, color:, font: Theme::SANS, style: :normal, **options)
      fragments = Prawn::Text::Formatted::Parser.format(string).map do |fragment|
        fragment[:link] ? fragment.merge(callback: @underline) : fragment
      end

      pdf.font(font, style: style) do
        pdf.fill_color color
        pdf.formatted_text fragments, size: size, leading: Theme::LEADING_PROSE, **options
      end
    end

    private
      # DESIGN.md 7: the document is one sheet of paper from the first pixel to
      # the last. Drawn at page creation rather than afterwards, because a
      # rectangle painted later would cover the text it is meant to sit behind.
      def fill_paper
        previous = pdf.fill_color

        pdf.canvas do
          pdf.fill_color Theme::PAPER
          pdf.fill_rectangle [ pdf.bounds.left, pdf.bounds.top ], pdf.bounds.width, pdf.bounds.height
        end

        pdf.fill_color previous
      end

      def gutter_label(title, top)
        @ordinal += 1

        pdf.font(Theme::MONO, style: :bold) do
          pdf.fill_color Theme::INK_FAINT
          pdf.text_box format("%02d", @ordinal), at: [ 0, top ], width: Theme::GUTTER_WIDTH,
            size: Theme::SIZE_XS, character_spacing: Theme::TRACKING_XS
          pdf.fill_color Theme::INK_MUTED
          pdf.text_box title.to_s.upcase, at: [ 0, top - Theme::SIZE_XS - Theme::SPACE_TIGHT ], width: Theme::GUTTER_WIDTH,
            size: Theme::SIZE_XS, character_spacing: Theme::TRACKING_XS
        end
      end

      # Drawn once the content is complete, when the total is known. `text_box`
      # into the bottom margin rather than a repeater, so the page number is a
      # plain value rather than a deferred one.
      #
      # The explicit height is not optional: a box positioned below the margin
      # box works out a negative default height and silently draws nothing,
      # returning the text it did not set.
      def footers
        total = pdf.page_count

        1.upto(total) do |number|
          pdf.go_to_page(number)

          pdf.font(Theme::MONO) do
            pdf.fill_color Theme::INK_FAINT
            footer_box SiteMetadata.host
            footer_box I18n.t("resume.page", number: number, total: total), align: :right
          end
        end
      end

      def footer_box(text, align: :left)
        pdf.text_box text, at: [ 0, -Theme::SPACE_BLOCK ], width: pdf.bounds.width, height: Theme::SPACE_BLOCK,
          size: Theme::SIZE_2XS, character_spacing: Theme::TRACKING_2XS, align: align
      end

      # Prawn's block form of `font` returns the font rather than the block, so
      # a measurement taken inside one has to be carried back out by hand.
      def measure(font)
        value = nil
        pdf.font(font) { value = yield }
        value
      end

      def write(font, text, size:, color:, style:, **options)
        pdf.font(font, style: style) do
          pdf.fill_color color
          pdf.text text.to_s, size: size, leading: Theme::LEADING_TIGHT, **options
        end
      end
  end
end
