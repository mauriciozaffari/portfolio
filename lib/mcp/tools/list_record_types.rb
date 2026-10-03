# frozen_string_literal: true

module Mcp
  module Tools
    # The record vocabulary, so a caller can build its own queries against the
    # REST API without guessing a path.
    class ListRecordTypes < Base
      tool_name 'list_record_types'
      title 'List record types'
      description 'List the record types this server can return, for callers building their own queries.'
      annotations(read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      input_schema(properties: {}, required: [])

      def self.call(**)
        success(RecordSet.type_names)
      end
    end
  end
end
