# frozen_string_literal: true

module Mcp
  # The tool catalog an agent sees over POST /mcp.
  #
  # Every tool here is reachable by anyone on the internet, so the list is
  # deliberately read-only: there is nothing to write and nothing to protect.
  # Each tool returns the same JSON the REST API serves, from RecordSet.
  module Tools
    ALL = [GetProfile, GetExperience, SearchRecords, ListRecordTypes].freeze

    def self.all = ALL

    def self.names = ALL.map(&:tool_name)
  end
end
