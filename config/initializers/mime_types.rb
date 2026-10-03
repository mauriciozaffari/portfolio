# frozen_string_literal: true

# The two structured media types this site serves beyond plain JSON. Registering
# them with Mime is what lets a controller declare the exact type an agent sees
# without Rails rewriting it.
Mime::Type.register 'application/openapi+json', :openapi
Mime::Type.register 'application/linkset+json', :linkset

# `ActionDispatch::TestResponse#parsed_body` picks its parser from the media
# type, and an unregistered one falls back to an identity parser that hands back
# the raw body — so a spec asking for `parsed_body` would silently receive a
# String. The encoder lives in Action Dispatch's testing code, which is loaded
# only here, in the test environment, so production never carries it.
if Rails.env.test?
  require 'action_dispatch/testing/request_encoder'

  ActionDispatch::RequestEncoder.register_encoder(
    :openapi,
    response_parser: ->(body) { JSON.parse(body) }
  )

  ActionDispatch::RequestEncoder.register_encoder(
    :linkset,
    response_parser: ->(body) { JSON.parse(body) }
  )
end
