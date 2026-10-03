---
title: "Agent discovery - Implementation"
type: "feature-implementation"
status: "implemented"
created: "2026-10-03"
updated: "2026-10-03"
commit: "b2c6982"
---

# Agent discovery — How it was built

- Status: implemented
- Commit: `b2c6982` — *Let agents find, read, and call this profile*
- Updated: 2026-10-03

## Shape

One rule drives the design: **no document may advertise a URL the application
does not serve.** That rules out hand-written files under `public/`. Everything
here is generated at request time from the routing table, `SiteMetadata.origin`,
and the curated records, and a spec walks every advertised URL back through the
router.

```
app/controllers/
  landing_controller.rb         # HTML, Markdown negotiation, ?mode=agent
  site_metadata_controller.rb   # robots, sitemap, llms*.txt
  discovery_controller.rb       # /.well-known/* and the skill artifacts
  pages_controller.rb           # about, contact, privacy, auth.md, agents.md
  api/records_controller.rb     # the read-only JSON API
  api/docs_controller.rb        # /openapi.json
  mcp_controller.rb             # POST /mcp, Streamable HTTP

app/models/
  agent_guide.rb                # the /llms.txt text, shared with the MCP resource
  discovery.rb                  # every discovery document
  discovery/vocabulary.rb       # the skill list and catalog entries as data
  record_set.rb                 # one serializer for the REST API and the MCP tools
  landing_page_markdown.rb      # the Markdown twin of the page
  openapi_document.rb           # the OpenAPI 3.1 description
  openapi_document/schemas.rb   # its component schemas, as constants
  structured_data/pages/profile.rb  # the JSON-LD graph

lib/mcp/
  tools.rb, tools/*.rb          # the MCP tool catalog (official mcp gem)
  resources.rb, resources/agent_guide.rb
```

## Decisions worth knowing

**The JSON API is versioned in the path, not in a module name.** The route
namespace is `api`; `scope 'v1', as: :v1` keeps `/api/v1` in the URL and
`api_v1_profile_path` in the helper without deriving a module named `V1`, which
Reek rejects. `Api::RecordsController` carries no version in its name.

**One serializer, three surfaces.** `RecordSet` shapes a record for the REST
API and for the MCP tools, so the two protocols cannot describe the same record
differently. `Localized#locale` falls back to the default locale, because the
API routes supply no route default and `?locale=pt-BR` must win; the two page
routes still supply a route default, which is what stops `/?locale=pt-BR`
switching the English URL.

**The MCP server is stateless and uses the official SDK.** `mcp` 0.25 provides
the transport, so the JSON-RPC envelope is not hand-rolled. `allowed_hosts` is
set to `SiteMetadata.host` — the SDK's DNS-rebinding protection — which is also
why the MCP spec speaks to the canonical host rather than the test host.

**Structured data moved out of `SiteMetadata`.** It is built by
`StructuredData::Pages::Profile` through `ruby-structured-data`, the pattern
`develoz-b2b` uses: the gem owns schema.org's vocabulary, so a misspelled
property fails at load time. `SiteMetadata` keeps two readers that delegate to
it. The `FAQPage` answers are the record's own fields, not prose written for the
schema.

**`delegate` is avoided; `Forwardable` is used.** ActiveSupport's `delegate`
compiles a rescue/`nil?` branch into the generated method, which SimpleCov
cannot see through, so it makes 100% branch coverage impossible. `def_delegator`
generates forwarding with no branch and still satisfies RuboCop's
`Rails/Delegate`. This is the same trade `develoz-b2b` records.

**Two media types are registered, not worked around.** `application/openapi+json`
and `application/linkset+json` are registered with `Mime`, and — in the test
environment only — with `ActionDispatch::RequestEncoder`, so
`TestResponse#parsed_body` parses them instead of returning a raw String. The
alternative was `JSON.parse(response.body)` with a cop suppression.

**The coverage gate drove the shape of the code.** `bin/ci` enforces 100% line
and branch coverage, so defensive branches that nothing could reach were
removed rather than tested: the leadership `nil` guard (the schema guarantees
exactly one leadership record), the optional `details` in the error body (one
caller always passes it), and the dead `markdown_twin?` guard. The empty sides
of the Markdown renderer are covered by a throwaway corpus in
`spec/models/landing_page_markdown_minimal_spec.rb`, not by adding a record to
`data/` that exists only to be counted.

## Generated coverage reports

The kit writes reports to `public/coverage`. `/public/coverage` is gitignored
and `/public/coverage/` is dockerignored, so a report can neither be committed
nor served in production.

## Verification

- `bin/ci` green: setup, RuboCop, Reek, Flay, `herb analyze`, content schema,
  content safety scan, path gate, importmap audit, bundler-audit, Brakeman,
  RSpec.
- 445 examples, 0 failures.
- Line coverage 1657/1657 (100.00%); branch coverage 179/179 (100.00%).
- Every discovery URL is recognized by the router in
  `spec/requests/discovery_spec.rb`; the MCP tool surface is exercised over its
  real transport in `spec/requests/mcp_spec.rb`; each tool is also called
  directly in `spec/models/mcp/tools_spec.rb`.

## Deferred

- What the apex `zaffari.casa` does. The canonical origin is
  `https://mauricio.zaffari.casa` and the apex serves a different application,
  so nothing here points at it; see the SPEC's open decisions.
- No `/pricing.md`: the publication policy forbids compensation, so the document
  would be empty or a violation.
