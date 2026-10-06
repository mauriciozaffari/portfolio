# frozen_string_literal: true

class Resume
  # The type that sits in the margins rather than in the flow: the numbered
  # label in each section's gutter, and the running footer on every page.
  #
  # Held apart from Resume::Sheet so that the sheet owns where content goes and
  # this owns what is printed around it. Neither needs the other's state beyond
  # the Prawn document they both draw on.
  class Furniture
    attr_reader :pdf

    def initialize(pdf)
      @pdf = pdf
      @ordinal = 0
    end

    # Drawn at whatever cursor the caller has already positioned, which is the
    # only y that cannot disagree with the rule the caller drew. `text_box`
    # treats the y it is given as the top of the box, not the first baseline, so
    # a caller handing over the rule's own y would strike the ordinal through.
    def gutter_label(title)
      @ordinal += 1
      top = pdf.cursor

      pdf.font(Theme::MONO, style: :bold) do
        pdf.fill_color Theme::INK_FAINT
        pdf.text_box format('%02d', @ordinal), at: [0, top], width: Theme::GUTTER_WIDTH,
                                               size: Theme::SIZE_XS, character_spacing: Theme::TRACKING_XS
        pdf.fill_color Theme::INK_MUTED
        pdf.text_box title.to_s.upcase, at: [0, top - Theme::SIZE_XS - Theme::SPACE_TIGHT], width: Theme::GUTTER_WIDTH,
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
          footer_box I18n.t('resume.page', number:, total:), align: :right
        end
      end
    end

    private

    def footer_box(text, align: :left)
      pdf.text_box text, at: [0, -Theme::SPACE_BLOCK], width: pdf.bounds.width, height: Theme::SPACE_BLOCK,
                         size: Theme::SIZE_2XS, character_spacing: Theme::TRACKING_2XS, align:
    end
  end
end
