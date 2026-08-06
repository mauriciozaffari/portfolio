source "https://rubygems.org"

# This application deliberately runs without a database. Active Record, Active
# Job, Active Storage, Action Mailer, Action Cable, Action Mailbox, Action Text,
# jbuilder, and the Solid adapters are all absent by design — see
# features/app-foundation/SPEC.md. Do not re-add them.
gem "rails", "~> 8.1.3", ">= 8.1.3.1"
# The modern asset pipeline for Rails [https://github.com/rails/propshaft]
gem "propshaft"
# Use the Puma web server [https://github.com/puma/puma]
gem "puma", ">= 5.0"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Renders the Markdown bodies under data/ [https://kramdown.gettalong.org].
# Pure Ruby, so it adds no native extension and no platform-specific rows to the
# lockfile. Its output is never trusted: see app/models/content/markdown.rb.
gem "kramdown", "~> 2.5"
# Use Tailwind CSS [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails", "~> 4.6"
# Vendors the Tailwind standalone binary, so no Node toolchain is needed. Pinned
# explicitly because this gem's version *is* the Tailwind CLI version.
gem "tailwindcss-ruby", "~> 4.3", ">= 4.3.3"

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Reduces boot times through caching; required in config/boot.rb
gem "bootsnap", require: false

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"

  # Omakase Ruby styling [https://github.com/rails/rubocop-rails-omakase/]
  gem "rubocop-rails-omakase", require: false

  # ERB and HTML structure checking [https://github.com/marcoroth/herb]. Only
  # `herb analyze` is used: it runs on the native Ruby extension, while
  # `herb lint` shells out to npx and would drag in a Node toolchain.
  gem "herb", "~> 0.10", require: false

  # Test framework [https://github.com/rspec/rspec-rails]
  gem "rspec-rails", "~> 8.0"
end

group :development do
  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Deploys the container to the VPS [https://kamal-deploy.org]. Development
  # only: Kamal runs from a workstation and drives the server over SSH, so it is
  # never installed into the image it builds — see features/deployment/SPEC.md.
  gem "kamal", "~> 2.12", require: false
end
