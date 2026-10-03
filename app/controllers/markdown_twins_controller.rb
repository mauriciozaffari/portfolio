# frozen_string_literal: true

# The `.md` twin of a machine-readable document.
#
# An agent that appends `.md` to a URL is asking for the same content as prose.
# For the two documents that are already Markdown or schema, that is a real
# convenience rather than a second source: the API guide is served unchanged,
# and the OpenAPI description is rendered from `OpenapiDocument` by
# `OpenapiMarkdown`, so neither can drift from the thing it describes.
class MarkdownTwinsController < ApplicationController
  include Localized

  layout false

  MARKDOWN_TYPE = 'text/markdown; charset=utf-8'

  # `/api.md` and `/api/llms.txt.md` are the same guide at two spellings: one is
  # the page URL, the other the URL with `.md` appended.
  def api_guide
    render template: 'site_metadata/api_llms', formats: [:text], content_type: MARKDOWN_TYPE
  end

  def openapi
    document = OpenapiDocument.new(origin: SiteMetadata.origin).to_h

    render plain: OpenapiMarkdown.new(document:).render, content_type: MARKDOWN_TYPE
  end
end
