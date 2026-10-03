# frozen_string_literal: true

class SiteMetadataController < ApplicationController
  layout false

  def robots
    render formats: :text, content_type: 'text/plain'
  end

  def sitemap
    @sitemap = Sitemap.new(repository: Content.repository)

    render formats: :xml, content_type: 'application/xml'
  end
end
