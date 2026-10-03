# frozen_string_literal: true

class Discovery
  # The fixed vocabulary the discovery documents are built from.
  #
  # It is data, not logic: the skill list and the catalog entries change when a
  # document is added, and keeping them in one place is what stops the ARD
  # catalog, the skills index, and the agent card from describing different
  # sets.
  module Vocabulary
    SKILL_SCHEMA = 'https://schemas.agentskills.io/discovery/0.2.0/schema.json'

    # The four capabilities the records support. The prose around each value is
    # chrome; the values themselves come from the profile record.
    SKILLS = [
      { name: 'profile-and-cv', title: 'Profile and CV',
        description: 'identity, headline, region, working mode, and professional links',
        body: 'Fetch the canonical profile through %<api>s, or read %<markdown>s.' },
      { name: 'career-history', title: 'Career history',
        description: 'roles, organizations, dates, and engineering responsibilities',
        body: 'Query roles and organizations through %<api>s, or read %<markdown>s for the narrative version.' },
      { name: 'technical-skills', title: 'Technical skills',
        description: 'competency groups: languages, frameworks, architecture practice, databases, and performance work',
        body: 'Query competency groups through %<api>s, or read the skills section of %<markdown>s.' },
      { name: 'case-studies', title: 'Case studies',
        description: 'the selected engineering work, the approach, and the technologies used',
        body: 'Query selected work through %<api>s, or read the case-study section of %<markdown>s.' }
    ].freeze

    # The agentic resources this domain publishes. Every `path` here is a route
    # the application serves, and a spec recognizes each one.
    CATALOG_ENTRIES = [
      { namespace: 'mcp', artifact: 'profile', display_name: 'profile and CV',
        type: 'application/mcp-server-card+json', path: '/.well-known/mcp/server-card.json',
        description: 'Read-only Model Context Protocol server over the curated profile records.' },
      { namespace: 'skill', artifact: 'profile', display_name: 'agent skills',
        type: 'application/agent-skills+json', path: '/.well-known/agent-skills/index.json',
        description: 'Agent skills for retrieving and searching the profile, roles, and case studies.' },
      { namespace: 'api', artifact: 'profile', display_name: 'read-only REST API',
        type: 'application/openapi+json', path: '/openapi.json',
        description: 'OpenAPI 3.1 description of the read-only JSON API.' },
      { namespace: 'agent', artifact: 'recruiter', display_name: 'recruiter agent card',
        type: 'application/a2a-agent-card+json', path: '/.well-known/agent-card.json',
        description: "Agent-to-agent card naming the skills this site's data supports." },
      { namespace: 'markdown', artifact: 'profile', display_name: 'profile as Markdown',
        type: 'text/markdown', path: '/index.md',
        description: 'The whole page as one Markdown document.' }
    ].freeze
  end
end
