class Resume
  # A hairline in the second ink under a link, drawn per text fragment.
  #
  # DESIGN.md 5 sets a link as ink text with an accent underline, and DESIGN.md
  # 2 rations the accent to states rather than to words. Prawn's inline `<u>`
  # strokes the underline in the fragment's own colour, so honouring both rules
  # at once means drawing the line here: Prawn hands a callback the fragment's
  # measured box after it is laid out, including the right one when a link wraps
  # across two lines.
  class AccentUnderline
    attr_reader :pdf

    def initialize(pdf)
      @pdf = pdf
    end

    def render_in_front(fragment)
      pdf.save_graphics_state do
        pdf.line_width Theme::HAIRLINE
        pdf.stroke_color Theme::ACCENT
        pdf.stroke_line fragment.underline_points
      end
    end
  end
end
