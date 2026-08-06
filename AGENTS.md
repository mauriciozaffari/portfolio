# AGENTS.md

Context for agentic sessions in this repository. Read this before touching
anything.

## What this is

A personal portfolio and professional showcase site for Mauricio Zaffari, a
Ruby on Rails tech lead / staff software engineer. One landing page, Rails 8 +
Hotwire, all content authored as Markdown in `data/`. A grounded chatbot that
answers questions about his background is the final planned feature.

## Current state (2026-08-06)

**There is no Rails application yet.** The repository contains:

```
.tool-versions   ruby 4.0.6, nodejs 26.7.0 (both installed and working)
.gitignore       session artifacts, secrets, Rails runtime; admits .opencode/skills only
AGENTS.md        this file
data/en/         34 curated English records across eight types
features/        the feature backlog: TODO.md index + seven SPEC.md files
.opencode/       project skills (feature-spec, implement-feature)
```

**The repository has zero commits.** Nothing has been committed yet, which is
why replacing unsafe content is still free rather than a history rewrite.

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

- **`curated-content` has no enforcement.** The schema, the publication policy,
  and the exclusion list are written down and the records conform to them, but
  the loader, the content-safety scanner, and the outside-app-root grep gate do
  not exist yet — they need the Rails app. Until then the policy rests on human
  review, which is weaker than
  [its SPEC](features/curated-content/SPEC.md) intends. This is the reason
  `app-foundation` is next.
- **`pt-BR` records do not exist.** English ships first; the locale fallback in
  [curated-content](features/curated-content/SPEC.md) makes the second locale
  incremental rather than a cutover.

## Style

- Clean and simple over clever. Introduce an abstraction on its second use, not
  in anticipation of one.
- Follow the conventions in the codebase once one exists. Until then, modern
  Rails 8 defaults minus the components excluded above.
- Text files end with a newline.
- No emojis in code, markup, or UI.
