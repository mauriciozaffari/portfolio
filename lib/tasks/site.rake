# frozen_string_literal: true

# Authoring tools, not runtime code.
#
# Both artifacts below are committed PNGs. Nothing in the request path generates
# an image, and the production container has no ImageMagick, no Node and no
# headless browser — see features/deployment/IMPLEMENTATION.md. The share card is
# fetched by a scraper once and cached for a long time, so an unfingerprinted
# static file at a stable URL is exactly right and a generated response would be
# a running cost paid for nothing.
#
# Run after editing the site_profile record's name or headline, or after editing
# public/icon.svg, and commit what changes.
namespace :site do
  desc 'Rebuild the favicon and the share card. Commit whatever they produce.'
  task images: :environment do
    # The palette and the type are DESIGN.md's, so the card that arrives in a
    # LinkedIn message is recognisably the same object as the page it links to.
    # The sans faces are the ones DESIGN.md already names in its own stack. The
    # mono face is `Liberation Mono`, also in that stack: a link-preview card
    # has one job — to survive a WhatsApp unfurl — and a card that only builds
    # on machines with a font WhatsApp may never see this composition needs is
    # not a card, it is a coin flip. Nothing here depends on a font this
    # machine does not have.
    paper = '#FBF9F5'
    ink = '#141210'
    ink_muted = '#5C554A'
    ink_faint = '#736B61'
    rule_strong = '#C7BFB0'
    accent = '#B03A1A'
    sans_bold = 'Noto-Sans-Bold'
    sans = 'Noto-Sans-Regular'
    mono = 'Liberation-Mono'

    # WhatsApp renders the link preview as a square thumbnail cropped off the
    # image's horizontal centre, which is what once cut this card's name at the
    # left margin into "auricio Zaffari". So every line a reader must be able
    # to read — host label, name, headline, the second ink — is composed
    # centred on the canvas inside that centre square. The hairline rules alone
    # stay full-bleed: cropped or whole, they read as structure.
    margin = 88
    safe_width = SiteMetadata::IMAGE_HEIGHT
    measure = safe_width - (5 * 8)

    # Array form throughout: a record value reaches ImageMagick as one argument
    # and never as shell input.
    run = lambda do |*command|
      abort "site:images: #{command.first} failed" unless system(*command)
    end

    # ImageMagick draws past the edge of the canvas without complaining, which
    # would ship a card with a clipped name and no warning. A record long enough
    # to overflow the WhatsApp crop should stop the build instead.
    fits = lambda do |font, size, kerning, text|
      width = IO.popen(['convert', '-font', font, '-pointsize', size.to_s, '-kerning', kerning.to_s,
                        "label:#{text}", '-format', '%w', 'info:'], &:read).to_i
      abort "site:images: #{text.inspect} renders #{width}px wide, past the #{measure}px measure" if width > measure
    end

    public_root = Rails.public_path
    profile = Content.repository.site_profile(locale: Content::Schema::DEFAULT_LOCALE).record

    run.call('convert', '-background', 'none', public_root.join('icon.svg').to_s,
             '-resize', '512x512', '-strip', public_root.join('icon.png').to_s)
    puts 'public/icon.png'

    # The card turns the headline into centred lines — "Lead / Staff Software
    # Engineer" over "Ruby on Rails" — so the centre square carries each line
    # whole; the separator the page renders as a pipe becomes the line break.
    headline_lines = profile[:headline].split(' | ')
    fits.call(sans_bold, 72, -2, profile[:name])
    headline_lines.each { |line| fits.call(sans, 34, 0, line) }

    host_label = SiteMetadata.host.upcase
    canvas_center = SiteMetadata::IMAGE_WIDTH / 2
    canvas_right = SiteMetadata::IMAGE_WIDTH - margin

    # One writer for every centred line: the same gravity, the same geometry,
    # only the face, the ink and the vertical position differ.
    annotate = lambda do |fill, font, pointsize, kerning, y, text|
      ['-fill', fill, '-font', font, '-pointsize', pointsize.to_s, '-kerning', kerning.to_s,
       '-annotate', "+0+#{y}", text]
    end

    run.call(
      'convert', '-size', "#{SiteMetadata::IMAGE_WIDTH}x#{SiteMetadata::IMAGE_HEIGHT}", "xc:#{paper}",
      '-gravity', 'North',

      # The mono gutter label, letter-spaced and uppercase, above the first rule.
      *annotate.call(ink_faint, mono, 26, 6, 92, host_label),
      '-kerning', '0', '-fill', rule_strong,

      # Two hairlines and nothing else. No shadow, no panel, no radius: the page
      # has one depth strategy and so does the card.
      '-draw', "rectangle #{margin},150 #{canvas_right - 1},151",
      '-draw', "rectangle #{margin},480 #{canvas_right - 1},481",
      *annotate.call(ink, sans_bold, 72, -2, 206, profile[:name]),
      *headline_lines.each_with_index.flat_map do |line, index|
        annotate.call(ink_muted, sans, 34, 0, 322 + (index * 56), line)
      end,

      # The second ink, sitting under the lower rule exactly as it sits under
      # the current locale in the switcher. One at-rest instance, as DESIGN.md
      # rations it.
      '-fill', accent, '-draw',
      "rectangle #{canvas_center - 59},478 #{canvas_center + 59},483",
      '-strip', '-depth', '8', public_root.join(SiteMetadata::IMAGE_PATH.delete_prefix('/')).to_s
    )
    puts "public#{SiteMetadata::IMAGE_PATH}"
  end
end
