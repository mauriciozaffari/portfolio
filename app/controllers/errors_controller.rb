# frozen_string_literal: true

# The error pages an agent is most likely to meet first, because it guessed a
# URL. An HTML error page is a dead end for a client that cannot read HTML, so
# this one speaks Markdown when Markdown is what was asked for, and points at
# the index it should have started from.
#
# Reached through `config.exceptions_app = routes`, which is what makes a
# routing failure arrive at a controller at all. ShowExceptions rewrites the
# path to `/404` or `/500` before calling the router, which is why those two
# routes exist. A *direct* request to `/404` never gets here: Rack::Static
# serves `public/404.html` for that path first.
class ErrorsController < ApplicationController
  layout false

  PAGES = { not_found: '404.html', internal_server_error: '500.html' }.freeze

  def not_found
    respond_with_error(:not_found)
  end

  def server_error
    respond_with_error(:internal_server_error)
  end

  private

  # Rails' own page, served unchanged: it is already noindex and self-contained,
  # and it carries no policy of its own because ShowExceptions sits above the
  # CSP middleware.
  def respond_with_error(status)
    respond_to do |format|
      format.html { render file: Rails.public_path.join(PAGES.fetch(status)), status:, layout: false }
      format.md { render plain: markdown_body(status), status:, content_type: 'text/markdown; charset=utf-8' }
      format.any { head status }
    end
  end

  def markdown_body(status)
    status == :not_found ? not_found_markdown : server_error_markdown
  end

  def not_found_markdown
    origin = SiteMetadata.origin

    <<~MARKDOWN
      # 404 — no such page

      That path does not exist on this site. Nothing here was moved; the record
      you were probably looking for is one of these:

      - [Profile and background](#{origin}/index.md)
      - [Perfil completo](#{origin}/pt-BR/index.md)
      - [Agent guide](#{origin}/llms.txt)
      - [OpenAPI 3.1 description](#{origin}/openapi.json)
      - [API guide](#{origin}/api/llms.txt)
      - [Sitemap](#{origin}/sitemap.xml)

      If a link brought you here, it is wrong and worth fixing.
    MARKDOWN
  end

  def server_error_markdown
    origin = SiteMetadata.origin

    <<~MARKDOWN
      # 500 — the server could not answer

      This is a fault on the site, not a wrong URL. Nothing about the records
      changed; retry in a moment. The published source is still readable at:

      - [Profile and background](#{origin}/index.md)
      - [Agent guide](#{origin}/llms.txt)
      - [Sitemap](#{origin}/sitemap.xml)
    MARKDOWN
  end
end
