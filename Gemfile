# frozen_string_literal: true

source 'https://rubygems.org'

# This application deliberately runs without a database. Active Record, Active
# Job, Active Storage, Action Mailer, Action Cable, Action Mailbox, Action Text,
# jbuilder, and the Solid adapters are all absent by design — see
# features/app-foundation/SPEC.md. Do not re-add them.
gem 'rails', '~> 8.1.3', '>= 8.1.3.1'
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem 'propshaft'
# Use the Puma web server [https://github.com/puma/puma]
gem 'puma', '>= 5.0'
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem 'importmap-rails'
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem 'turbo-rails'
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem 'stimulus-rails'
# Renders the Markdown bodies under data/ [https://kramdown.gettalong.org].
# Pure Ruby, so it adds no native extension and no platform-specific rows to the
# lockfile. Its output is never trusted: see app/models/content/markdown.rb.
gem 'kramdown', '~> 2.5'
# Builds the downloadable resume [https://prawnpdf.org]. Pure Ruby, so the
# production image needs no headless browser and no Node — see
# features/resume-download/SPEC.md. Only the fourteen PDF base fonts are used,
# so nothing is embedded and no font file is vendored.
gem 'prawn', '~> 2.5'
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem 'tailwindcss-rails', '~> 4.6'
# Vendors the Tailwind standalone binary, so no Node toolchain is needed. Pinned
# explicitly because this gem's version *is* the Tailwind CLI version.
gem 'tailwindcss-ruby', '~> 4.3', '>= 4.3.3'
# The official Model Context Protocol Ruby SDK: an agent calls the profile as
# tools over Streamable HTTP instead of scraping the page. Pure Ruby, no
# database and no session, so it fits the stateless container.
gem 'mcp', '~> 0.25'
# Authors, validates, and serialises the JSON-LD in the page head, so the
# structured data is built from schema.org's vocabulary rather than from a hash
# literal that nothing checks. Pure Ruby.
gem 'ruby-structured-data', '~> 0.1.1'

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[windows jruby]

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', require: false

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem 'debug', platforms: %i[mri windows], require: 'debug/prelude'

  # ERB and HTML structure checking [https://github.com/marcoroth/herb]. Only
  # `herb analyze` is used: it runs on the native Ruby extension, while
  # `herb lint` shells out to npx and would drag in a Node toolchain.
  gem 'herb', '~> 0.10', require: false

  # Checks Gemfile.lock against the Ruby advisory database
  # [https://github.com/rubysec/bundler-audit]. Promised by
  # features/app-foundation/IMPLEMENTATION.md and deferred to deployment, which
  # never picked it up.
  #
  # config/ci.rb runs `bundle-audit check` without `--update`. The advisory
  # database is not vendored in the gem: it is cloned into the user's data
  # directory the first time the command runs, and reused untouched after that.
  # So the gate downloads once on a machine and never again, while a GitHub
  # Actions runner is new every time and therefore always reads a current
  # database — CI is the authority on freshness, and a workstation stays fast
  # and works offline.
  #
  # The tradeoff is that a local copy goes stale silently. `bundle-audit check
  # --update` is the command to run by hand when that matters; it is not the one
  # in the gate, because a gate that clones from GitHub on every run fails for
  # reasons that have nothing to do with the code being gated.
  gem 'bundler-audit', '~> 0.9', require: false

  # Test framework [https://github.com/rspec/rspec-rails]
  gem 'rspec-rails', '~> 8.0'

  # Reads the generated resume back out [https://github.com/yob/pdf-reader].
  # Test-only on purpose: the application writes PDFs and never parses one, and
  # the scan has to run over the bytes a reader downloads rather than over the
  # source that produced them.
  gem 'pdf-reader', '~> 2.15'

  # Loads .env [https://github.com/bkeepers/dotenv]. Deliberately not available
  # in production: the deployed container receives real environment variables
  # from Kamal, and a .env quietly overriding them would be a debugging trap.
  # BUNDLE_WITHOUT excludes this group from the image, so the gem is not merely
  # unused there — it is absent.
  gem 'dotenv-rails', '~> 3.1'

  # Opinionated quality assurance kit for Rails applications. Brings RuboCop,
  # Reek, Flay, Brakeman, bundler-audit, SimpleCov, and the bin/ci harness.
  # See features/app-foundation/SPEC.md.
  gem 'rails-quality-assurance'
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem 'web-console'

  # Deploys the container to the VPS [https://kamal-deploy.org]. Development
  # only: Kamal runs from a workstation and drives the server over SSH, so it is
  # never installed into the image it builds — see features/deployment/SPEC.md.
  gem 'kamal', '~> 2.12', require: false
end
