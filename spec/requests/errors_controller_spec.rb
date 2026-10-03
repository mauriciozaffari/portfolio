# frozen_string_literal: true

require 'rails_helper'

# The 404. An agent that guesses a URL meets this page first, so it has to be
# useful to a client that cannot read HTML.
RSpec.describe ErrorsController do
  # A request spec runs the real middleware stack, but the test environment
  # renders exceptions as debug pages unless this is turned on — and the whole
  # point of this controller is what happens when it is.
  around do |example|
    env_config = Rails.application.env_config
    show_exceptions = env_config['action_dispatch.show_exceptions']
    detailed = env_config['action_dispatch.show_detailed_exceptions']

    env_config['action_dispatch.show_exceptions'] = :all
    env_config['action_dispatch.show_detailed_exceptions'] = false
    example.run
  ensure
    env_config['action_dispatch.show_exceptions'] = show_exceptions
    env_config['action_dispatch.show_detailed_exceptions'] = detailed
  end

  it 'serves the static HTML page to a browser that guessed a URL' do
    get '/no-such-page'

    expect(response).to have_http_status(:not_found)
    expect(response.media_type).to eq('text/html')
    expect(response.body).to include("doesn't exist")
  end

  it 'serves a Markdown dead end to a client that asked for Markdown' do
    get '/no-such-page', headers: { 'Accept' => 'text/markdown' }

    expect(response).to have_http_status(:not_found)
    expect(response.media_type).to eq('text/markdown')
    expect(response.body).to start_with('# 404')
  end

  it 'points the Markdown body at the index and the machine-readable documents' do
    get '/no-such-page', headers: { 'Accept' => 'text/markdown' }
    origin = SiteMetadata.origin

    expect(response.body).to include(
      "#{origin}/index.md", "#{origin}/llms.txt", "#{origin}/openapi.json", "#{origin}/sitemap.xml"
    )
  end

  it 'sends no body to a client that accepts neither HTML nor Markdown' do
    get '/no-such-page', headers: { 'Accept' => 'application/pdf' }

    expect(response).to have_http_status(:not_found)
    expect(response.body).to be_empty
  end

  # POST, because Rack::Static answers GET /500 from public/500.html before the
  # router sees it — a direct request never reaches this controller, only an
  # exception does.
  it 'answers a server error in Markdown for an agent' do
    post '/500', headers: { 'Accept' => 'text/markdown' }

    expect(response).to have_http_status(:internal_server_error)
    expect(response.media_type).to eq('text/markdown')
    expect(response.body).to start_with('# 500')
  end

  it 'wires a routing failure through the router rather than the static file' do
    expect(Rails.application.config.exceptions_app).to eq(Rails.application.routes)
  end
end
