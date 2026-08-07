# AGENTS.md

Context for agentic sessions in this repository. Read this before touching
anything.

## What this is

A personal portfolio and professional showcase site for Mauricio Zaffari, a
Ruby on Rails tech lead / staff software engineer. One landing page, Rails 8 +
Hotwire, all content authored as Markdown in `data/`. A grounded chatbot that
answers questions about his background is the final planned feature.

## Current state (2026-08-06)

**Six features are built on `main`.** Five are `implemented`; `deployment` is
`in-progress` because nothing has been deployed yet. `bin/ci` is green.

```
.tool-versions   ruby 4.0.6, nodejs 26.7.0 (both installed and working)
.gitignore       session artifacts, secrets, Rails runtime; admits .opencode/skills only
AGENTS.md        this file
DESIGN.md        the binding design contract — read before any UI change
app/             Rails 8: no database, no Node, zero JavaScript shipped
data/en/         34 curated English records across eight types
features/        the backlog: TODO.md index + seven SPEC.md files
config/deploy.yml, Dockerfile, .kamal/   Kamal 2 config; never yet run against a host
.opencode/       project skills (feature-spec, implement-feature)
```

The site serves `/` and `/pt-BR` from the records, plus a Prawn resume PDF per
locale.

**`chatbot` is built but deliberately not on `main`.** It lives on the
`chatbot` branch, complete with specs and an `IMPLEMENTATION.md`, and is not
being shipped yet. Its [SPEC](features/chatbot/SPEC.md) stays in the backlog on
`main` at `spec'd` so the plan is still visible. Do not merge that branch
without the owner asking for it.

**The repository is committed and public.** History is permanent, so a mistake
in `data/**` is a history rewrite rather than a deletion. `bin/ci` is the gate
that prevents one: `content:validate`, `content:scan` and `content:paths` each
fail the build, and each is proven to fail by a spec.

## Hard rules

These are not preferences. Violating any of them is a defect.

1. **The repository is public on GitHub.** Everything committed is permanent and
   world-readable — including `data/**`, `features/**`, and commit history.
   There is no "clean it up later".

2. **Never publish personal compensation.** No pay rate, salary, day rate,
   share count, equity value, or option grant. This is the one hard content
   exclusion in an otherwise permissive policy — hard performance numbers,
   contribution metrics, and named clients and employers *are* publishable.

3. **Never publish** legal identifiers, addresses, immigration or visa
   material, family, medical or financial data, credentials, internal URLs and
   hostnames, private-individual names, or any direct contact field outside the
   approved professional-profile allowlist.

4. **Everything in `data/` is publication-safe or it does not belong there.**
   Content is curated by a human from private source material held outside this
   repository. That source material is never copied in verbatim, never
   symlinked, and never read by the application at runtime in any environment.
   The operator supplies its location when curating; it is not recorded here.

5. **No database.** No ActiveRecord, no Solid Queue / Cache / Cable, no
   ActiveStorage, ActionMailer, ActionCable, or jbuilder. Content is Markdown in
   the repository. This keeps the deployment topology to one stateless
   container. Do not helpfully add these back.

6. **No Node toolchain.** Tailwind runs via the standalone binary. No
   `package.json`, no esbuild, no React, no SPA.

## Workflow

This project is **SPEC-first**. Behavior is specified before it is built.

- `features/TODO.md` is the backlog index and the single cheap read for project
  status. Keep it in sync — every folder has a row, every row has a folder.
- Each `features/<slug>/SPEC.md` describes *what and why*. An
  `IMPLEMENTATION.md` describing *how* is written only after the code exists.
- Use the [feature-spec](.opencode/skills/feature-spec/SKILL.md) skill to
  create or update specs, and
  [implement-feature](.opencode/skills/implement-feature/SKILL.md) to implement
  one.
- Do not start implementing a feature whose SPEC has unresolved Pending TODOs
  that change what the feature does.

Feature order is dependency-driven: `app-foundation` → `curated-content` →
`landing-page` → `deployment` → (`site-metadata`, `resume-download`) →
`chatbot`. Rationale is in `features/TODO.md`.

## Decisions already made

Recorded so they are not relitigated every session.

| Decision | Value | Why |
|---|---|---|
| Repo visibility | Public | Owner's choice; drives every privacy rule above |
| Languages | English + pt-BR | Both first-class; folded into content, page, and metadata rather than a late i18n phase |
| Test framework | RSpec | Matches the owner's Rails style preferences |
| Metrics policy | Numbers and client names yes, compensation never | Owner's explicit decision |
| Resume download | Yes, publication-safe build | Recruiters need a file; existing PDFs carry contact details and cannot be republished |
| Domain | Already owned | Removes the highest-variance scheduling item |
| Deployment position | 4th, not last | Metadata and the PDF need a real canonical origin |
| Design system | Lives inside `landing-page`, not its own feature | One page does not justify extracting tokens first; the design *decision* is recorded in the SPEC instead |
| Accessibility / performance | Acceptance criteria, not a phase | They are properties of markup; scheduling them later guarantees a rewrite |
| Vector database for chatbot | No | One person's history fits in grounded context; revisit only at a recorded corpus size |

## Known gaps

- **Nothing has been deployed.** The Kamal configuration is complete and the
  image builds and serves locally, but it has never run against a host. The
  rollback is documented and **not yet exercised**, which is the one unmet
  acceptance criterion in [deployment](features/deployment/SPEC.md) and the
  reason that SPEC is `in-progress` rather than `implemented`. The repository
  also has no git remote, so CI runs nowhere until it is pushed.
- **Every response sets an unused `_portfolio_session` cookie.** Nothing reads
  it. On a public site with no login it is not strictly necessary, which is
  precisely the category that carries a consent obligation in the EU and UK.
  Worth removing before launch.
- **The Portuguese records are machine-drafted and human-approved**, not
  human-authored. They were translated in one pass and reviewed before
  publication. Figures carry Brazilian notation (`R$ 482.800`, `81,7%`) while
  the English keeps English notation, so the two locales are deliberately not
  byte-comparable on numbers. Three judgement calls are recorded in
  [curated-content](features/curated-content/SPEC.md): job titles keep *Tech
  Lead* untranslated, Looper's domain noun *scan* stays English, and city names
  are localised only where a common Portuguese exonym exists.
- **The resume PDF is eight pages.** It is faithful to its SPEC — the same
  records as the page, so the two cannot drift — but that is a dossier rather
  than a resume, and most readers expect one or two pages. An open product
  decision, not a defect.
- **The share card is generated by an authoring task CI cannot run.** Editing
  the profile name leaves a stale `og-image.png` and nothing detects it. The
  unfurl is also unproven end to end, because LinkedIn and Slack cannot reach a
  local origin.

## Style

- Clean and simple over clever. Introduce an abstraction on its second use, not
  in anticipation of one.
- Follow the conventions in the codebase once one exists. Until then, modern
  Rails 8 defaults minus the components excluded above.
- Text files end with a newline.
- No emojis in code, markup, or UI.
