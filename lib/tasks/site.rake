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
    # The two faces are the ones DESIGN.md already names in its own stacks, so
    # the card matches what a Linux reader sees rather than a third face nobody
    # chose.
    paper = '#FBF9F5'
    ink = '#141210'
    ink_muted = '#5C554A'
    ink_faint = '#736B61'
    rule_strong = '#C7BFB0'
    accent = '#B03A1A'
    sans_bold = 'Noto-Sans-Bold'
    sans = 'Noto-Sans-Regular'
    mono = 'DejaVu-Sans-Mono'

    margin = 88
    card_right = SiteMetadata::IMAGE_WIDTH - margin
    measure = card_right - margin

    # Array form throughout: a record value reaches ImageMagick as one argument
    # and never as shell input.
    run = lambda do |*command|
      abort "site:images: #{command.first} failed" unless system(*command)
    end

    # ImageMagick draws past the edge of the canvas without complaining, which
    # would ship a card with a clipped name and no warning. A record long enough
    # to overflow should stop the build instead.
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

    fits.call(sans_bold, 96, -2, profile[:name])
    fits.call(sans, 42, 0, profile[:headline])

    run.call(
      'convert', '-size', "#{SiteMetadata::IMAGE_WIDTH}x#{SiteMetadata::IMAGE_HEIGHT}", "xc:#{paper}",
      '-gravity', 'NorthWest',

      # The mono gutter label, letter-spaced and uppercase, above the first rule.
      '-fill', ink_faint, '-font', mono, '-pointsize', '26', '-kerning', '6',
      '-annotate', "+#{margin}+92", SiteMetadata.host.upcase,

      # Two hairlines and nothing else. No shadow, no panel, no radius: the page
      # has one depth strategy and so does the card.
      '-kerning', '0', '-fill', rule_strong,
      '-draw', "rectangle #{margin},150 #{card_right - 1},151",
      '-draw', "rectangle #{margin},480 #{card_right - 1},481",
      '-fill', ink, '-font', sans_bold, '-pointsize', '96', '-kerning', '-2',
      '-annotate', "+#{margin}+225", profile[:name],
      '-fill', ink_muted, '-font', sans, '-pointsize', '42', '-kerning', '0',
      '-annotate', "+#{margin}+360", profile[:headline],

      # The second ink, sitting on the lower rule exactly as it sits under the
      # current locale in the switcher. One at-rest instance, as DESIGN.md
      # rations it.
      '-fill', accent, '-draw', "rectangle #{margin},478 #{margin + 119},483",
      '-strip', '-depth', '8', public_root.join(SiteMetadata::IMAGE_PATH.delete_prefix('/')).to_s
    )
    puts "public#{SiteMetadata::IMAGE_PATH}"
  end
end
