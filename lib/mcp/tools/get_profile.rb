# frozen_string_literal: true

module Mcp
  module Tools
    # The identity record: name, headline, region, working mode, and links.
    class GetProfile < Base
      tool_name 'get_profile'
      title 'Get profile'
      description 'Return the profile identity: name, headline, region, working mode, and professional links.'
      annotations(read_only_hint: true, destructive_hint: false, idempotent_hint: true, open_world_hint: false)

      input_schema(properties: { locale: LOCALE_SCHEMA }, required: [])

      def self.call(locale: nil, **)
        success(record_set(locale).serialize('profile'))
      end
    end
  end
end
