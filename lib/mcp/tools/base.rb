# frozen_string_literal: true

module Mcp
  module Tools
    # Shared behaviour for the profile tools: every one of them reads the same
    # curated records through the same serializer the REST API uses.
    class Base < ::MCP::Tool
      LOCALE_SCHEMA = {
        type: 'string',
        enum: Content::Schema::LOCALES,
        default: Content::Schema::DEFAULT_LOCALE,
        description: 'Language of the records to read.'
      }.freeze

      class << self
        def success(payload)
          ::MCP::Tool::Response.new([{ type: 'text', text: JSON.pretty_generate(payload) }])
        end

        def failure(message)
          ::MCP::Tool::Response.new([{ type: 'text', text: message }], error: true)
        end

        def record_set(locale)
          RecordSet.new(locale: locale.presence_in(Content::Schema::LOCALES) || Content::Schema::DEFAULT_LOCALE)
        end
      end
    end
  end
end
