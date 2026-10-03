# frozen_string_literal: true

module Mcp
  module Tools
    # Case-insensitive keyword search across every published record, so an
    # agent can ask "does this person know Terraform?" without knowing which
    # record type would carry the answer.
    class SearchRecords < Base
      tool_name 'search_records'
      title 'Search records'
      description 'Search every published record for a keyword and return the matching entries.'
      annotations(read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      input_schema(
        properties: {
          query: { type: 'string', minLength: 2, description: 'Keyword to look for.' },
          locale: LOCALE_SCHEMA
        },
        required: %w[query]
      )

      def self.call(query:, locale: nil, **)
        return failure('The query must be at least two characters.') if query.to_s.strip.length < 2

        success(record_set(locale).search(query))
      end
    end
  end
end
