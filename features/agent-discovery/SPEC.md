---
title: "Agent discovery - Spec"
type: "feature-spec"
status: "implemented"
created: "2026-10-03"
updated: "2026-10-03"
origin: "operational need (a large share of readers now arrive through an AI assistant, and an assistant that cannot read the published source answers from a stale scrape or a guess)"
---

# Agent discovery

- Status: implemented — see [IMPLEMENTATION.md](IMPLEMENTATION.md)
- Created: 2026-10-03
- Updated: 2026-10-03
- Origin: operational need (a large share of readers now arrive through an AI
  assistant, and an assistant that cannot read the published source answers from
  a stale scrape or a guess)

## Problem / motivation

The site exists to be found. An increasing share of the people it is written for
never open it: they ask an assistant a question about the person it describes,
and the assistant answers from whatever it can reach — the rendered page, a
scraped aggregator, or nothing. [Site metadata](../site-metadata/SPEC.md) covers
the unfurl and the search crawler. It does not cover the surfaces an agent looks
for when it is deciding what it can *do* with a site: a context index, a
capability list, a machine-readable API, and a protocol it can call.

Those surfaces are also the ones that go wrong quietly. A document that
advertises an endpoint the application does not serve is worse than no document,
because the agent reports a dead end that no human review would have caught.
Every URL this feature publishes must therefore come from the routing table or
from the same constants the controllers read, never from a hand-written literal.

## Desired behavior

- **A context index.** `/llms.txt` states what the site is, when an agent should
  reach for this person, and where the machine-readable documents live.
  `/llms-full.txt` carries every record in both locales in one document.
- **Discovery documents** under `/.well-known/`, each generated from the
  records and the routing table:
  - an Agentic Resource Discovery catalog (`ard.json`, also served at the AI
    Catalog alias `ai-catalog.json`) with a `urn:air` identifier per entry;
  - an agent-skills index (`agent-skills/index.json`) whose every entry carries
    a name, a description, a type, a URL, and a digest over the bytes it
    advertises;
  - an MCP server card listing the tools the server actually exposes;
  - an A2A agent card;
  - an RFC 9727 API catalog and RFC 9728 protected-resource metadata.
- **A machine-readable API.** `/openapi.json` describes a read-only JSON API
  under `/api/v1` over the same records the page renders. No key, no account, no
  login: an agent that cannot complete a signup flow is the reader this exists
  for. Errors are JSON in one shape.
- **A callable protocol.** `/mcp` serves the Model Context Protocol over
  Streamable HTTP, stateless, exposing the profile, the employment history, and
  a keyword search as tools, plus the agent guide as a resource.
- **Markdown on demand.** `/index.md` and `/pt-BR/index.md` serve the page as
  Markdown; `Accept: text/markdown` negotiates the same document on `/`; and
  `?mode=agent` returns a short machine-readable overview for a cold arrival.
- **Link headers** advertising the sitemap, the Markdown twin, the API catalog,
  and the ARD catalog.
- **Richer structured data**: beyond the `Person` entity, a `WebSite`, a
  `ProfilePage`, a `BreadcrumbList`, and an `FAQPage` whose answers are the
  record's own words.
- **Trust pages** at `/about`, `/contact`, and `/privacy`, each substantial and
  each rendered from the records or from recorded policy, because these are the
  pages an agent checks before it recommends a site.

## Constraints

- Everything stays within [app-foundation](../app-foundation/SPEC.md): no
  database, no Node toolchain, no external service at runtime.
- Every value is generated from `data/**` or from a constant. Nothing is
  transcribed. The `Person`/`ProfilePage` JSON-LD remains asserted to carry no
  contact field outside the approved allowlist.
- The MCP server is read-only by construction. The site has nothing to write and
  no accounts, so there is no authorization server to publish and no session to
  keep.
- New gems are justified the way the project already justifies them: pure Ruby,
  no service, and named in the Gemfile comment. Two were added —
  `mcp` (the official SDK, so the protocol is not hand-rolled) and
  `ruby-structured-data` (schema.org's vocabulary, so a misspelled property is a
  load-time error).

## Acceptance criteria

- [x] Every URL a discovery document publishes is served by this application,
      proven by a spec that recognizes each path.
- [x] `/llms.txt`, `/llms-full.txt`, `/api/llms.txt`, and
      `/agent-skills/llms.txt` are served as text, not HTML.
- [x] `/openapi.json` is served as an OpenAPI 3.1 document whose operations each
      carry an id, a description, and a typed response.
- [x] The JSON API answers every documented path, one JSON error shape for an
      unknown type, and `304` for a matching `If-None-Match`.
- [x] `/mcp` answers `initialize`, `tools/list`, and `tools/call` over
      Streamable HTTP, refuses `GET`, and rejects an unknown tool with a
      JSON-RPC error.
- [x] The page is served as Markdown by negotiation and at a guessable `.md`
      URL.
- [x] The head carries a Link header set, a Markdown alternate, and the extended
      JSON-LD graph.
- [x] The trust pages exist in both locales and link only the approved contact
      channels.
- [x] `/api` serves the API guide at the URL a developer or an agent guesses,
      and the homepage links to it.
- [x] An unknown path answers `Accept: text/markdown` with a Markdown body that
      points at the index, the agent guide and the sitemap, rather than an HTML
      dead end.
- [x] `/openapi.json` states the versioning and deprecation policy: the major
      version is the first path segment, breaking changes arrive as a new path,
      and a retiring version carries `Deprecation` and `Sunset` headers.
- [x] `bin/ci` is green with 100% line and branch coverage.

## Open decisions

- **The canonical host is settled.** `SiteMetadata::ORIGIN` is
  `https://mauricio.zaffari.casa` — the host that actually serves this site —
  and it stays overridable with `SITE_ORIGIN` for a staging origin. The apex
  `zaffari.casa` serves a different application and is therefore *not* used
  anywhere; see the [deployment](../deployment/SPEC.md) SPEC.

## Pending TODOs

- [ ] **Unblock GPTBot and ClaudeBot at the edge.** The application answers
      every real AI crawler User-Agent with 200 — verified against the origin —
      but the public path returns **403** for GPTBot and ClaudeBot while
      allowing OAI-SearchBot, PerplexityBot and ordinary clients. The public
      `A` records are Cloudflare's, so this is Cloudflare's AI-bot control, not
      the app. Allow the two there, or narrow the rule to every host in the zone
      except this one. This is the single largest remaining agentic defect and
      it cannot be fixed from this repository.
- [ ] Decide what the apex `zaffari.casa` does. It currently answers with a
      different application, so nothing here points at it. Repointing it at this
      service (or 301-ing it to the canonical host) is a DNS and deployment
      decision, recorded in the deployment SPEC.
- [ ] Decide whether to accept the cost of the two checks that are deliberately
      not satisfied. `webmcp` and `pricing-info` both ask for something this
      project has ruled out on purpose: in-page tools need JavaScript, and the
      page ships none with `script-src 'none'`; pricing needs a rate, and the
      publication policy forbids compensation. They are recorded as accepted
      losses rather than pending work.
- [ ] Decide whether a `/pricing.md` is wanted. It was deliberately not added:
      this site publishes no rate, and the publication policy forbids
      compensation. A pricing document would either say nothing useful or
      violate a hard rule.
- [ ] Register the MCP server in a public registry so the listing links back to
      the canonical host.
- [ ] If the repository is pushed to a public remote, link it from `/llms.txt`
      so the `agent-rules-repo` signal (an `AGENTS.md` in a discoverable repo)
      resolves.

## Dependencies

- [app-foundation](../app-foundation/SPEC.md) — the test and CI harness the
  coverage gate runs in.
- [curated-content](../curated-content/SPEC.md) — every document is generated
  from these records.
- [site-metadata](../site-metadata/SPEC.md) — the origin, the canonical URL
  helpers, and the `Person` entity this feature extends.
- [landing-page](../landing-page/SPEC.md) — the page whose Markdown twin and
  agent mode are rendered here.
