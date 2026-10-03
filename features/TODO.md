---
title: "Feature Backlog Index"
type: "feature-backlog"
date: "2026-08-06"
tags:
  - feature-backlog
  - portfolio
---

# Portfolio feature backlog

Status index for this Rails 8 + Hotwire professional showcase site. One folder
per feature, each with a `SPEC.md` (what and why) and, once implemented, an
`IMPLEMENTATION.md` (how). This file is the single cheap read that answers
"what does the site do, what is pending, and what are the constraints".

```mermaid
flowchart LR
  A[idea] --> B["spec'd"] --> C[in-progress] --> D[implemented]
```

Maintained by the [feature-spec](../.opencode/skills/feature-spec/SKILL.md) and
[implement-feature](../.opencode/skills/implement-feature/SKILL.md) skills. Keep
this table in sync whenever a feature folder is added or a status changes.

The `commit` field in each `IMPLEMENTATION.md` names the commit the feature
landed in — the one carrying both its code and that document — not the commit
before it, while `updated` tracks the document's own last revision.

## Blocking preconditions

Not features. Preconditions that gate the first commit.

- **The repository is public.** Everything committed is permanent and
  world-readable, including `data/**` and this backlog.
- **`data/` contains only reviewed, publication-safe records.** The unreviewed
  seed resume that carried a direct phone number and personal email was deleted
  before any commit existed, so those values were never written to history.
- **`.gitignore` is in place**, covering agent session artifacts, secrets, and
  Rails runtime paths. Vendored `node_modules` was already excluded by
  `.opencode/.gitignore`.

Commit #1 is unblocked.

## Ordering

The sequence is dependency-driven, not priority-driven:

```mermaid
flowchart LR
  F[app-foundation] --> C[curated-content] --> L[landing-page] --> D[deployment]
  D --> M[site-metadata]
  D --> R[resume-download]
  M --> B[chatbot]
  R --> B
```

`deployment` sits early on purpose: `site-metadata` and `resume-download` both
need a real canonical origin, and shipping continuously beats a big-bang
release. `chatbot` is last by explicit request and because it is the only
feature that adds an external dependency, a running cost, and an abuse surface.

## Features

| Feature | Status | Created | Implemented | Summary |
| ------- | ------ | ------- | ----------- | ------- |
| [app-foundation](app-foundation/SPEC.md) | implemented | 2026-08-06 | 2026-10-03 | Rails 8 + Hotwire app that boots with no database, no Node toolchain, and no Solid adapters; the shared `rails-quality-assurance` kit (RuboCop, Reek, Flay, Brakeman, bundler-audit) and RSpec behind one `CI.run` entry point, with SimpleCov enforcing 100% line and branch coverage |
| [curated-content](curated-content/SPEC.md) | implemented | 2026-08-06 | 2026-08-06 | Bilingual Markdown content in `data/**` with an enforced front-matter schema, a publication allowlist, and a content-safety scanner that fails the build |
| [landing-page](landing-page/SPEC.md) | implemented | 2026-08-06 | 2026-08-06 | One server-rendered locale-aware page at `/` and `/pt-BR`, built entirely from the content records; zero JavaScript, zero web fonts, 18.5 KB gzipped, design language recorded in [DESIGN.md](../DESIGN.md) |
| [site-metadata](site-metadata/SPEC.md) | implemented | 2026-08-06 | 2026-08-06 | Canonical URLs, hreflang, OG/Twitter cards, `Person` JSON-LD asserted to carry no contact field, an app-served sitemap dated from record `updated` values, a robots policy that allows AI crawlers on purpose, and a share card and favicon built from `site_profile` by `bin/rails site:images` |
| [resume-download](resume-download/SPEC.md) | implemented | 2026-08-06 | 2026-08-06 | A PDF per locale built with Prawn on request from the same records as the page — no phone, email, address or compensation in the text or in the document metadata, proven by scanning the extracted bytes and the information dictionary, with a failing fixture proving the scan fires |
| [deployment](deployment/SPEC.md) | in-progress | 2026-08-06 | — | HTTPS at the canonical origin from a single stateless container, security headers, and CI that blocks deploy on a failing content scan. Kamal 2 config, production image, and headers are built and verified locally; nothing is deployed, because no server exists yet |
| [chatbot](chatbot/SPEC.md) | spec'd | 2026-08-06 | — | Flag-gated grounded assistant over the published corpus only, with citations, explicit refusals, adversarial specs, rate limits, and no vector database |

## Publication policy

The one rule that cuts across every feature, per the owner's decision:

- **Permitted**: hard performance numbers, contribution metrics, named clients
  and employers, open-source download counts, public media coverage.
- **Never published**: personal compensation in any form — pay rate, salary,
  day rate, share counts, equity value, option grants.
- **Never published**: legal identifiers, addresses, immigration material,
  family, medical and financial data, credentials, internal URLs, and any
  direct contact field outside the approved professional-profile allowlist.

Details and enforcement live in
[curated-content](curated-content/SPEC.md).

## Pending work

Concrete pending TODOs live in each feature's `SPEC.md` under "Pending TODOs".
Listed here in the order they block progress:

- [Deployment](deployment/SPEC.md): **in progress.** The Kamal 2 configuration,
  the production image, the security headers, and the CI workflow exist and are
  verified locally — see
  [its IMPLEMENTATION.md](deployment/IMPLEMENTATION.md). What is left needs a
  machine: provision the VPS, supply the four environment values, point DNS at
  it, run `kamal setup`, and **exercise the rollback**, which this SPEC requires
  and which cannot be proved without a host. The deploy trigger is still
  undecided.
- [Curated content](curated-content/SPEC.md): **nothing pending.** Both locales
  are authored and published — 68 records, 34 in `en` and 34 in `pt-BR`. The
  fallback still covers the case of an English record authored ahead of its
  translation, and is now proven by fixtures rather than by the corpus happening
  to be incomplete.
- [Landing page](landing-page/SPEC.md): decide whether `source_url` becomes a
  visible citation, and whether `metric` and `skill_group` get an ordering key.
  Neither blocks anything; both are recorded so they are not improvised.
- [Site metadata](site-metadata/SPEC.md): **implemented** — both open decisions
  are made and recorded (AI crawlers allowed on purpose; the share card is a
  static PNG built from the record by `bin/rails site:images`). What is left
  needs the live origin: validate the unfurl through LinkedIn's and Slack's own
  debuggers, which cannot reach a local server. A second open item is whether a
  share card left stale by a profile edit should fail the build; CI cannot run
  the image task, so nothing detects it today.
- [Resume download](resume-download/SPEC.md): **implemented** — see
  [its IMPLEMENTATION.md](resume-download/IMPLEMENTATION.md). Two open items,
  neither blocking: whether a one-page variant is worth having (the honest build
  is a key on the records, not a selection rule inside the feature), and the
  untagged-PDF accessibility gap Prawn leaves, whose mitigation today is that
  drawing order is reading order and the colophon links back to the HTML page.
- [Chatbot](chatbot/SPEC.md): decide conversation logging and retention, and
  record the corpus-size threshold that would justify a vector database.
  Provider (Gemini) and the USD 20/month hard cap are decided.
- [App foundation](app-foundation/SPEC.md): drop the `nodejs` pin from
  `.tool-versions`. Nothing in the build reads it — there is no `package.json`
  and Tailwind runs from the binary the `tailwindcss-ruby` gem vendors — so the
  pin only suggests a toolchain the project has ruled out. Blocks nothing.
