# frozen_string_literal: true

require_relative 'boot'

require 'rails'
# Only these railties are loaded. Active Record, Active Job, Active Storage,
# Action Mailer, Action Mailbox, Action Text, and Action Cable are deliberately
# absent: this site renders Markdown from the repository, stores nothing, and
# deploys as one stateless container. Adding any of them back supersedes
# features/app-foundation/SPEC.md.
require 'active_model/railtie'
require 'action_controller/railtie'
require 'action_view/railtie'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Portfolio
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 8.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

    # Don't generate system test files.
    config.generators.system_tests = nil

    # A routing failure goes through the router rather than straight to the
    # static page in public/, so `ErrorsController` can answer a client that
    # asked for Markdown. `config/exceptions_app = routes` is the supported
    # way to make an exception reach a controller at all.
    config.exceptions_app = routes

    # Response headers.
    #
    # This lives here rather than in config/initializers because it has to:
    # ActionDispatch::Response.default_headers is captured by the
    # `action_dispatch.configure` railtie initializer, which runs before
    # config/initializers/* are loaded. Set from an initializer, this hash is
    # built and then ignored. The Content Security Policy is the exception and
    # does live in config/initializers/content_security_policy.rb, because that
    # one is read per request rather than at boot.
    #
    # Rails already sends all of these but `Permissions-Policy`. They are
    # restated rather than inherited so that a Rails upgrade changing a default
    # cannot quietly relax this site, and so that
    # spec/requests/security_headers_spec.rb has one place to point at.
    config.action_dispatch.default_headers = {
      'X-Content-Type-Options' => 'nosniff',

      # Bare origin cross-origin, nothing at all when leaving HTTPS. The
      # footer's outbound profile links are the only navigations this affects.
      'Referrer-Policy' => 'strict-origin-when-cross-origin',

      # Stricter than the Rails default of SAMEORIGIN, because nothing here is
      # ever framed. `frame-ancestors 'none'` in the CSP is the modern
      # spelling; this is what browsers too old to read it still honour.
      'X-Frame-Options' => 'DENY',

      'X-Permitted-Cross-Domain-Policies' => 'none',

      # Rails' own default. The legacy XSS auditor is disabled rather than set
      # to block mode: it is gone from current browsers and was itself an
      # information-disclosure vector. The CSP is its replacement.
      'X-XSS-Protection' => '0',

      # Features this site does not use, denied outright. `()` is an empty
      # allowlist: not this origin, not an embedded frame, nobody.
      #
      # Written by hand rather than through Rails' `config.permissions_policy`,
      # which is a real DSL that emits the wrong header: actionpack 8.1.3.1
      # still writes the superseded `Feature-Policy` name in its
      # `camera 'none'` syntax, and says so at
      # action_dispatch/http/permissions_policy.rb:26. No current browser reads
      # that header, and its value is not valid in a `Permissions-Policy`.
      # Revisit when Rails ships the renamed implementation.
      'Permissions-Policy' => %w[
        accelerometer
        ambient-light-sensor
        autoplay
        battery
        browsing-topics
        camera
        display-capture
        encrypted-media
        fullscreen
        geolocation
        gyroscope
        hid
        idle-detection
        local-fonts
        magnetometer
        microphone
        midi
        payment
        picture-in-picture
        publickey-credentials-get
        screen-wake-lock
        serial
        usb
        xr-spatial-tracking
      ].map { |feature| "#{feature}=()" }.join(', ')
    }
  end
end
