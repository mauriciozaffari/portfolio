# frozen_string_literal: true

module Mcp
  module Resources
    # The published agent instructions, so an agent can pull the same guidance
    # it would fetch from /llms.txt without leaving MCP.
    class AgentGuide < ::MCP::Resource
      uri "#{SiteMetadata.origin}/llms.txt"
      resource_name 'agent_guide'
      title 'Mauricio Zaffari — agent instructions'
      description 'When to reach for Mauricio, which records to read, and what not to infer.'
      mime_type 'text/markdown'

      def self.contents
        ::MCP::Resource::TextContents.new(
          uri: uri_value,
          mime_type: mime_type_value,
          text: ::AgentGuide.new.text
        )
      end
    end
  end
end
