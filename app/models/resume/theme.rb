# frozen_string_literal: true

class Resume
  # DESIGN.md, expressed in points.
  #
  # DESIGN.md is binding on the stylesheet, and this is the second surface that
  # consumes it. Every value below traces to a token named there, so the PDF and
  # the page can be checked against one document rather than against each other.
  # A value that is not derived from a DESIGN.md token does not belong here.
  #
  # The one systematic departure is the type scale. Screen sizes are given in
  # px against a 16px base; print is read closer and denser, so the ramp is
  # compressed rather than converted (a literal px * 0.75 would set the body at
  # 12.75pt, which is a large-print resume). The *relationships* survive: nine
  # steps, the same roles, and the same negative tracking as size grows.
  module Theme
    # A4 rather than US Letter. Letter is standard in one country; A4 is
    # standard everywhere else this document is read, including the two regions
    # the profile names alongside the US. The margins are wide enough that
    # either sheet prints without clipping.
    module Page
      PAGE_SIZE = 'A4'

      # Top, right, bottom, left. The deeper bottom margin is the footer's.
      MARGIN = [48, 48, 54, 48].freeze

      # DESIGN.md 5 sets the page on a twelve-column grid with the section label
      # in a three-column gutter. Same proportion here: 120pt of gutter, 20pt of
      # gap, and the rest for content. The measure that falls out is ~72
      # characters at the body size, inside DESIGN.md 3's 60-75 target — which a
      # full-width A4 text block would badly overrun.
      GUTTER_WIDTH = 120
      GUTTER_GAP = 20
    end

    # A section label stranded at the foot of a page with its content overleaf
    # reads as a bug. Below this much room, start the section on a fresh page.
    module Orphans
      SECTION_ORPHAN = 120

      # The same guard for an entry's own heading and its first line of prose.
      ENTRY_ORPHAN = 76
    end

    # The fourteen fonts every PDF reader has. No file is embedded, no file is
    # vendored, and the document carries zero font bytes — the same budget
    # DESIGN.md 3 declares for the page, arrived at the same way. Helvetica is
    # what its sans stack asks for and Courier is the mono counterpart.
    module Fonts
      SANS = 'Helvetica'
      MONO = 'Courier'
    end

    # DESIGN.md 3's nine steps, compressed for print as explained above.
    module TypeSmall
      SIZE_2XS = 6.5
      SIZE_XS = 7.5
      SIZE_SM = 8.5
      SIZE_BASE = 9
    end

    module TypeLarge
      SIZE_LG = 9.5
      SIZE_XL = 11
      SIZE_2XL = 13
      SIZE_3XL = 17
      SIZE_4XL = 22
    end

    # DESIGN.md 3 gives tracking in em; Prawn's character_spacing is in points,
    # so these are the em values multiplied through at the size each is used at.
    module Tracking
      TRACKING_2XS = 0.78   # 0.12em at SIZE_2XS
      TRACKING_XS = 0.68    # 0.09em at SIZE_XS
      TRACKING_SM = 0.09    # 0.01em at SIZE_SM
      TRACKING_4XL = -0.48  # -0.022em at SIZE_4XL
    end

    # Prawn's leading is added on top of the font's own line height, which for
    # these faces is about 1.15em. 3.6pt at the body size lands the line box at
    # roughly 1.5 — DESIGN.md 3 asks for 1.7 on screen, and print wants tighter.
    module Leading
      LEADING_PROSE = 3.6
      LEADING_TIGHT = 1.5
    end

    # DESIGN.md 4's four multiples of the 4px base unit, in points.
    module Space
      SPACE_TIGHT = 5
      SPACE_CLOSE = 9
      SPACE_BLOCK = 18
      SPACE_SECTION = 26
    end

    # DESIGN.md 2. Hex without the leading `#`, which is what Prawn takes.
    module Paper
      PAPER = 'FBF9F5'
    end

    module Ink
      INK_FAINT = '736B61'
      INK_MUTED = '5C554A'
      INK_BODY = '2E2A25'
      INK = '141210'
    end

    module Rules
      RULE = 'E5DFD3'
      RULE_STRONG = 'C7BFB0'
    end

    # DESIGN.md 7: hairline rules are the entire depth system. There are no
    # shadows, no fills and no radii to define, because none exists.
    module Strokes
      HAIRLINE = 0.5
      HAIRLINE_STRONG = 0.75

      # The single at-rest instance of the second ink, matching the share card's
      # accent segment described in features/site-metadata/IMPLEMENTATION.md.
      ACCENT = 'B03A1A'
      ACCENT_SEGMENT = 60
    end

    include Page
    include Orphans
    include Fonts
    include TypeSmall
    include TypeLarge
    include Tracking
    include Leading
    include Space
    include Paper
    include Ink
    include Rules
    include Strokes

    def self.column_width(page_width)
      page_width - GUTTER_WIDTH - GUTTER_GAP
    end
  end
end
