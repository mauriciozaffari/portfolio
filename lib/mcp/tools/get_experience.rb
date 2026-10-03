# frozen_string_literal: true

module Mcp
  module Tools
    # Roles, organizations, dates, and descriptions, newest first.
    class GetExperience < Base
      tool_name 'get_experience'
      title 'Get experience'
      description 'Return the employment history as role, organization, dates, and description, newest first.'
      annotations(read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      input_schema(properties: { locale: LOCALE_SCHEMA }, required: [])

      def self.call(locale: nil, **)
        success(record_set(locale).serialize('experience'))
      end
    end
  end
end
