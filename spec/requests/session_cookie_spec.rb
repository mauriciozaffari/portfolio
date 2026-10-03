# frozen_string_literal: true

require 'rails_helper'

# This site stores nothing about a reader, and the layout says so in a comment.
# The claim needs a gate, because the way it was broken was invisible: a
# csrf_meta_tags call in the layout touched the session on every render, and
# CookieStore turned that into a Set-Cookie nobody asked for.
#
# It has to be asserted with forgery protection on. config/environments/test.rb
# sets allow_forgery_protection = false, which makes csrf_meta_tags render
# nothing and the cookie disappear — so a spec written against the default test
# configuration would have passed against the bug it exists to catch.
RSpec.describe 'Session cookies' do
  around do |example|
    original = ActionController::Base.allow_forgery_protection
    ActionController::Base.allow_forgery_protection = true
    example.run
  ensure
    ActionController::Base.allow_forgery_protection = original
  end

  # Driven by the routing table rather than by today's page list, so a route a
  # later feature adds is covered the moment it exists.
  def reachable_paths
    Rails.application.routes.routes.filter_map do |route|
      next if route.internal
      next unless route.verb.include?('GET')
      next unless route.path.required_names.empty?

      route.path.spec.to_s.delete_suffix('(.:format)')
    end.uniq
  end

  it 'has pages to check' do
    expect(reachable_paths).to include('/', '/pt-BR')
  end

  it 'is off by default in the test environment, which is why the block above turns it on' do
    expect(Rails.application.config.action_controller.allow_forgery_protection).to be(false)
    expect(ActionController::Base.allow_forgery_protection).to be(true)
  end

  it 'sets no cookie on any page' do
    cookies_set = reachable_paths.to_h do |path|
      get path
      [path, response.headers['Set-Cookie']]
    end

    expect(cookies_set.compact).to be_empty
  end

  it 'starts no session at all' do
    get root_path

    expect(response.cookies).to be_empty
    expect(session.to_hash).to be_empty
  end

  it 'renders no CSRF token, because there is no form to protect' do
    get root_path
    document = response.parsed_body

    expect(document.css('form')).to be_empty
    expect(document.css("meta[name='csrf-token'], meta[name='csrf-param']")).to be_empty
  end

  # An empty nonce is not a nonce. It shipped on every page and told a reader's
  # browser nothing, because no nonce generator is configured and none is wanted:
  # nonces exist to permit inline script and inline style, and the policy in
  # config/initializers/content_security_policy.rb permits neither.
  it 'renders no empty CSP nonce' do
    get root_path

    expect(response.parsed_body.css("meta[name='csp-nonce']")).to be_empty
  end
end
