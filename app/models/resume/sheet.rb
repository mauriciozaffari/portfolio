# frozen_string_literal: true

require 'forwardable'

class Resume
  # A sheet of paper and the vocabulary for setting type on it.
  #
  # This half knows Prawn and DESIGN.md and nothing at all about resumes:
  # rules, the gutter grid, the ink ramp, the widow guards, the running footer.
  # Resume::Document knows the records and calls the methods below, which is the
  # same division the page makes between its partials and the template that
  # composes them.
  #
  # Type itself is set by Resume::Typesetter and the margin furniture by
  # Resume::Furniture; both are delegated below so a caller sees one sheet.
  class Sheet
    extend Forwardable

    # The fourteen base fonts cover WINDOWS-1252 and nothing else, and Prawn
    # says so once per font per document. The warning is addressed to somebody
    # who has not made the decision yet; this project has, in Theme, and a
    # record carrying a character outside that set raises rather than warns —
    # loudly, at build time, in spec/models/resume_spec.rb.
    Prawn::Fonts::AFM.hide_m17n_warning = true

    MIDDOT = " \u00B7 "
    NOTICE_PADDING = 9

    attr_reader :pdf

    def_delegators :typesetter, :sans, :mono, :formatted
    def_delegator :furniture, :gutter_label
    def_delegator :furniture, :footers

    def initialize(info:)
      @pdf = Prawn::Document.new(page_size: Theme::PAGE_SIZE, margin: Theme::MARGIN, info:)
      @pdf.on_page_create { fill_paper }
      @underline = AccentUnderline.new(@pdf)
      fill_paper
    end

    def render
      footers
      pdf.render
    end

    def gap(points)
      pdf.move_down points
    end

    # The two small steps the document spaces entries with.
    def tight_gap
      gap Theme::SPACE_TIGHT
    end

    def close_gap
      gap Theme::SPACE_CLOSE
    end

    # The accent segment sits on a rule with the same room above and below it.
    def accented_rule_with_room
      close_gap
      accented_rule
      close_gap
    end

    # A small-caps label over the text it names, with tight room between them and
    # after, which is how a metric and a technology list are both set.
    def captioned(caption, &)
      label caption
      tight_gap
      yield
    end

    # DESIGN.md 5's twelve-column grid: an ordinal and a label in the mono
    # gutter, the content in the wider column beside it.
    #
    # An indent rather than a second bounding box. Prawn carries a margin box's
    # padding onto each new page it generates, so a section longer than a page
    # keeps its column without any page-break bookkeeping here — and `cursor`
    # keeps meaning "room left", which inside a stretchy bounding box it does
    # not.
    def section(title, &)
      gap Theme::SPACE_SECTION
      cursor = pdf.cursor
      pdf.start_new_page if cursor < Theme::SECTION_ORPHAN
      rule Theme::RULE_STRONG, Theme::HAIRLINE_STRONG
      gap Theme::SPACE_CLOSE
      gutter_label(title)

      pdf.indent(Theme::GUTTER_WIDTH + Theme::GUTTER_GAP, &)
    end

    # The masthead and the colophon sit outside the gutter grid, so they have
    # the full page width available and must not use it: DESIGN.md 3 caps prose
    # at a measure, and a full-width A4 line runs to about 105 characters. Held
    # to the same width the sections get, which is where the eye is going next.
    def measured(&)
      width = pdf.bounds.width
      pdf.indent(0, width - Theme.column_width(width), &)
    end

    # A rule divides entries, so the first one in a list does not get one — the
    # section's own rule is already immediately above it. `always` is for the two
    # lists that open under a sub-heading instead, which is the same
    # `first:border-t-0` split the page makes.
    #
    # The guard keeps an entry's heading from being stranded at the foot of a
    # page with its prose overleaf. Prawn has no widow control of its own.
    def divider(index, always: false)
      separate(index, always:, strong: false)
    end

    # The same divider in the stronger stroke, which the page gives the entries
    # it foregrounds: current roles and case studies.
    def strong_divider(index)
      separate(index, always: false, strong: true)
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
      pdf.stroke_line [0, top], [Theme::ACCENT_SEGMENT, top]
    end

    # DESIGN.md 5: a bordered box, because it is the one element that is not
    # part of the document's argument. Everything else is divided by rules.
    def notice(text)
      padding = NOTICE_PADDING * 2
      width = Theme.column_width(pdf.bounds.width)
      inner = width - padding
      height = text_height(text, inner)
      top = pdf.cursor

      pdf.stroke_color Theme::RULE_STRONG
      pdf.line_width Theme::HAIRLINE
      pdf.stroke_rectangle [0, top], width, height + padding

      pdf.bounding_box([NOTICE_PADDING, top - NOTICE_PADDING], width: inner, height:) do
        mono text, size: Theme::SIZE_XS, color: Theme::INK_MUTED
      end

      pdf.move_cursor_to top - height - padding
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
      right_edge = pdf.bounds.width - width

      yield right_edge - Theme::SPACE_CLOSE

      pdf.font(Theme::MONO) do
        pdf.fill_color Theme::INK
        pdf.text_box right, at: [right_edge, top], width:, size: Theme::SIZE_SM
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

    private

    def separate(index, always:, strong:)
      first = index.zero? && !always

      gap Theme::SPACE_BLOCK unless first
      pdf.start_new_page if pdf.cursor < Theme::ENTRY_ORPHAN
      return if first

      rule(*stroke(strong))
      gap Theme::SPACE_CLOSE
    end

    def stroke(strong)
      strong ? [Theme::RULE_STRONG, Theme::HAIRLINE_STRONG] : [Theme::RULE, Theme::HAIRLINE]
    end

    def text_height(text, width)
      measure(Theme::MONO) do
        pdf.height_of(text, width:, size: Theme::SIZE_XS, leading: Theme::LEADING_TIGHT)
      end
    end

    # DESIGN.md 7: the document is one sheet of paper from the first pixel to
    # the last. Drawn at page creation rather than afterwards, because a
    # rectangle painted later would cover the text it is meant to sit behind.
    #
    # The bounds are read inside the canvas, where they are the page: outside
    # it they are the margin box, and its `left` and `top` are relative to
    # itself — a rectangle built from those lands on the page origin at
    # margin-box size, leaving the top and right margins as bare white paper.
    def fill_paper
      previous = pdf.fill_color

      pdf.canvas do
        page = pdf.bounds
        pdf.fill_color Theme::PAPER
        pdf.fill_rectangle [page.left, page.top], page.width, page.height
      end

      pdf.fill_color previous
    end

    # Prawn's block form of `font` returns the font rather than the block, so
    # a measurement taken inside one has to be carried back out by hand.
    def measure(font)
      value = nil
      pdf.font(font) { value = yield }
      value
    end

    def typesetter
      @typesetter ||= Typesetter.new(pdf:, underline: @underline)
    end

    def furniture
      @furniture ||= Furniture.new(pdf)
    end
  end
end
