# frozen_string_literal: true

# Serves the OpenAPI 3.1 description of the read-only API.
module Api
  class DocsController < ApplicationController
    layout false

    def openapi
      document = OpenapiDocument.new(origin: SiteMetadata.origin).to_h
      headers = response.headers
      headers['Cache-Control'] = 'public, max-age=3600'
      headers['Vary'] = 'Accept'

      render plain: JSON.pretty_generate(document), content_type: 'application/openapi+json; charset=utf-8'
    end
  end
end
