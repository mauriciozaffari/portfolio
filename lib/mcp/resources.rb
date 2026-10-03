# frozen_string_literal: true

module Mcp
  # Documents agents can read over MCP. Every entry must be content that is
  # already public on the site: `resources/read` is reachable without auth.
  module Resources
    ALL = [AgentGuide].freeze

    def self.all = ALL
  end
end
