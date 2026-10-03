# frozen_string_literal: true

class Resume
  # Sets type onto a Prawn document: one face, one size, one ink at a time.
  #
  # Held apart from Resume::Sheet, which owns the page and its rules, so that
  # the way text is drawn is one object and the way a page is divided is
  # another. A sheet asks for a line of mono or a paragraph of sans and never
  # touches a font or a fill colour itself.
  class Typesetter
    attr_reader :pdf, :underline

    def initialize(pdf:, underline:)
      @pdf = pdf
      @underline = underline
    end

    def sans(text, **)
      plain(Theme::SANS, text, **)
    end

    def mono(text, **)
      plain(Theme::MONO, text, **)
    end

    # Prawn's inline format is parsed rather than handed straight to `text`, so
    # that every link fragment can carry the accent underline DESIGN.md 5 gives
    # a link at rest. The tag syntax has no way to say "underline this in a
    # different ink from the text", and colouring the words themselves would
    # spend the second ink on something that is not a state.
    def formatted(string, **)
      face, ink, extras = split(**)
      fragments = Prawn::Text::Formatted::Parser.format(string).map { |fragment| underlined(fragment) }

      pdf.font(face.fetch(:font, Theme::SANS), style: face.fetch(:style, :normal)) do
        pdf.fill_color ink
        pdf.formatted_text(fragments, leading: Theme::LEADING_PROSE, **extras)
      end
    end

    private

    def plain(font, text, **)
      face, ink, extras = split(**)

      pdf.font(font, style: face.fetch(:style, :normal)) do
        pdf.fill_color ink
        pdf.text(text.to_s, leading: Theme::LEADING_TIGHT, **extras)
      end
    end

    # `font` and `style` choose the face, `color` is the ink, and everything
    # else — size, spacing, width — is Prawn's own and passes straight through.
    def split(color:, **rest)
      [rest.slice(:font, :style), color, rest.except(:font, :style)]
    end

    def underlined(fragment)
      fragment[:link] ? fragment.merge(callback: underline) : fragment
    end
  end
end
