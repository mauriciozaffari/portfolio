---
title: "App Foundation - Spec"
type: "feature-spec"
status: "spec'd"
created: "2026-08-06"
updated: "2026-08-06"
origin: "user request (Rails 8 + Hotwire showcase of my work)"
---

# App Foundation

- Status: spec'd
- Created: 2026-08-06
- Updated: 2026-08-06
- Origin: user request (Rails 8 + Hotwire showcase of my work)

## Problem / motivation

The repository has no application. It currently holds only `.tool-versions`,
an uncurated `data/` seed file, and this feature backlog. Every other feature
depends on a booting Rails 8 app with a working quality gate.

The default `rails new` brings a database, three Solid adapters, ActiveStorage,
ActionMailer, ActionCable, and a Node toolchain. This site renders Markdown
from the repository and stores nothing. Every one of those defaults is
unnecessary weight that would have to be maintained, deployed, secured, and
explained. Trimming them is the single decision that keeps the deployment
topology to one stateless container.

## Desired behavior

- A Rails 8 application boots and serves a `200` at the root route with **no
  database present** — no PostgreSQL, no SQLite, no `db/` migrations.
- The following are absent from the application: ActiveRecord, Solid Queue,
  Solid Cache, Solid Cable, ActiveStorage, ActionMailer, ActionCable, jbuilder.
- Asset pipeline is Propshaft. Styling is Tailwind via the standalone binary —
  **no Node toolchain, no `package.json`, no esbuild**.
- Hotwire (Turbo + Stimulus) is available but unused until a feature earns it.
- RSpec is the test framework, with the linters this project standardises on,
  all green against the empty app.
- A single command (`bin/ci` or equivalent) runs the full gate — specs plus
  linters — and exits `0`. This is the one entry point CI and humans both use.
- `.gitignore` is reviewed against the public-repo disclosure surface before
  the first commit.

## Constraints

- The repository is **public on GitHub**. Commit history is permanent and is
  itself a publication surface.
- No commit may be made until `data/` holds only reviewed, publication-safe
  records (see [curated-content](../curated-content/SPEC.md)). Anything
  unreviewed is replaced first; the window to do that for free closes at
  commit #1.
- Ruby version is pinned by `.tool-versions` (`ruby 4.0.6`, verified installed).
- No database means no migrations, no database container, and no backup story.
  Nobody re-adds ActiveRecord without superseding this spec.

## Out of scope

- Any page content, layout, or styling decisions — see
  [landing-page](../landing-page/SPEC.md).
- Deployment, CI hosting, and security headers — see
  [deployment](../deployment/SPEC.md).
- Error monitoring and APM. There is nothing to monitor until
  [chatbot](../chatbot/SPEC.md) introduces an external dependency.
- Staging environments. One page, one owner, one production environment.

## Pending TODOs

- [ ] Decide the linter set (RuboCop configuration, ERB lint, and whether a
      Markdown linter is worth it for `data/**`).
- [ ] Confirm Tailwind standalone binary versioning and how it is pinned.
