# frozen_string_literal: true

# The OpenAPI description as Markdown, for an agent that would rather read prose
# than parse a schema. Deliberately derived from OpenapiDocument rather than
# written beside it, so the two cannot disagree about an endpoint.
class OpenapiMarkdown
  def initialize(document:)
    @document = document
  end

  attr_reader :document

  def render
    body = [
      "# #{title}",
      '',
      description,
      '',
      "Base URL: `#{base_url}`",
      '',
      '## Endpoints',
      '',
      '| Method | Path | Summary |',
      '| --- | --- | --- |',
      *endpoint_rows
    ].join("\n")

    "#{body}\n"
  end

  private

  def info = document.fetch('info')

  def title = info.fetch('title')

  # The description already carries the versioning and deprecation policy, which
  # is exactly what an agent needs before it depends on the shape.
  def description = info.fetch('description')

  def base_url = document.fetch('servers').first.fetch('url')

  # A path with no GET has nothing to list, so it yields no row. The lookup is
  # an `andand` on a defaulted hash rather than a nil check, because absence is
  # a shape here, not an error.
  def endpoint_rows
    document.fetch('paths').filter_map { |path, operations| endpoint_row(path, operations) }
  end

  def endpoint_row(path, operations)
    operations.fetch('get', {})['summary']&.then { |summary| "| GET | `#{path}` | #{summary} |" }
  end
end
