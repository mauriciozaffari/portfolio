---
name: feature-spec
description: "Create or update a feature spec in the portfolio feature backlog at features/ in this repository (a Rails 8 + Hotwire personal portfolio and professional showcase site). Use when specifying a new feature or capability, when the user asks to spec, document, or plan a feature, when self-reflection identifies an improvement opportunity, or when a feature's SPEC.md needs updating after scope changes. Covers folder conventions, SPEC.md and IMPLEMENTATION.md templates, and TODO.md index maintenance."
---

# Feature spec

Create and maintain feature specs in the portfolio feature backlog.

## Backlog layout

```
features/
├── TODO.md                      # status index — one row per feature
└── <feature-slug>/
    ├── SPEC.md                  # what and why (always present)
    └── IMPLEMENTATION.md        # how (only once implemented)
```

- Feature slugs are kebab-case, short, and stable (`case-studies`, not
  `project-case-studies-v2`).
- Statuses:

  ```mermaid
  flowchart LR
    A[idea] --> B["spec'd"] --> C[in-progress] --> D[implemented]
    D --> E[superseded]
    B --> E
  ```

  `superseded` means the feature was replaced by a newer one. The SPEC must
  link to the superseding feature and explain why. Superseded features stay
  in the backlog for historical context; they are not deleted.

- [TODO.md](../../../features/TODO.md) must stay in
  sync: every folder has a row; every row has a folder. The table is sorted
  by status (implemented → spec'd → idea → superseded), then by date within
  each status group. Columns: `Feature | Status | Created | Implemented |
  Summary`. Use `—` for the Implemented column when not yet implemented.

## Mode selection

### Create mode

Use when no folder for the feature exists yet.

1. Read [features/TODO.md](../../../features/TODO.md)
   and scan folder names. **If a matching or overlapping feature exists,
   switch to update mode instead** — never create a near-duplicate.
2. Create `<feature-slug>/SPEC.md` from the template below.
3. Add a row to the `TODO.md` features table with the initial status
   (`idea` when only the problem is clear, `spec'd` when desired behavior
   is written out). Use today's date in the **Created** column and `—` in
   the **Implemented** column. Place the row in the correct status group
   (implemented features first, then spec'd, then idea, then superseded).
4. If the spec carries actionable pending work, list it in the SPEC's
   "Pending TODOs" and surface it under "Pending work" in `TODO.md`.

### Update mode

Use when the feature folder exists and scope, behavior, constraints, or
status changed.

1. Edit `SPEC.md` in place; bump the `Updated:` date in both the frontmatter
   and the body header.
2. Resolve or add "Pending TODOs" entries — never leave stale ones.
3. Update the feature's row (status + summary) in `TODO.md`. When the
   status changes to `implemented`, fill the **Implemented** column with the
   date from `IMPLEMENTATION.md`.
4. If behavior described in `IMPLEMENTATION.md` changed, update it too (or
   flag the mismatch when you cannot verify the code).

### Superseding a feature

When a new feature replaces an existing one:

1. Update the old feature's `SPEC.md`: set `status` to `superseded` in both
   frontmatter and body header, bump `Updated:`, add a `- Superseded by:
   [new-feature](../new-feature/SPEC.md)` line to the body header with a
   one-line explanation.
2. Remove the old feature's pending TODOs from `TODO.md`'s "Pending work"
   section (they are no longer actionable).
3. Move the old feature's row to the **superseded** group at the bottom of
   the `TODO.md` table.
4. The superseding feature's `SPEC.md` should reference the superseded
   feature in its "Problem / motivation" section.

## SPEC.md template

```markdown
---
title: "<Feature name> - Spec"
type: "feature-spec"
status: "idea | spec'd | in-progress | implemented | superseded"
created: "YYYY-MM-DD"
updated: "YYYY-MM-DD"
origin: "user request | self-reflection (session id) | operational need"
---

# <Feature name>

- Status: idea | spec'd | in-progress | implemented | superseded
- Created: YYYY-MM-DD
- Updated: YYYY-MM-DD
- Origin: user request | self-reflection (session id) | operational need

## Problem / motivation

Why this feature should exist. Cite evidence (session ids, summary files,
user quotes) when it came from reflection.

## Desired behavior

Concrete, observable behavior. Bullet points, testable statements.

## Constraints

Hard requirements, safety rules, things that must not change.

## Out of scope

Explicit exclusions so future agents do not gold-plate.

## Pending TODOs

- [ ] actionable items, or "None recorded."
```

## IMPLEMENTATION.md template

```markdown
---
title: "<Feature name> - Implementation"
type: "feature-implementation"
updated: "YYYY-MM-DD"
commit: "<short-sha>"
---

# <Feature name> — implementation

- Updated: YYYY-MM-DD
- Code as of: repository commit `<short-sha>`
- Spec: [SPEC.md](SPEC.md)

## Entry points / flow

How the feature is reached at runtime.

## Key files

Absolute-from-repo-root paths with one-line roles.

## Configuration

Env vars, defaults.

## Testing

Spec files covering the feature.

## Known limitations / pitfalls

What future agents must not break or "fix".
```

## Writing rules

- Factual and durable: self-contained files, dates, paths, no secrets.
- SPEC describes behavior and intent; IMPLEMENTATION describes code.
  Do not mix them.
- IMPLEMENTATION must cite the commit SHA it was written against so drift
  is detectable.
- Reference other files with markdown links, not bare backtick paths:
  repo-relative markdown links inside the features tree
  (e.g. `[SPEC.md](SPEC.md)`), and repo-root-relative paths for application
  code (e.g. `app/models/foo.rb`).
- Use mermaid diagrams when a flow, state machine, or decision tree is
  clearer as a picture than as prose.
- Files end with a newline.

## Related skills

- [implement-feature](../implement-feature/SKILL.md) — SPEC-first
  implementation workflow; writes IMPLEMENTATION.md after code changes.
