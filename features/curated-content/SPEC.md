---
title: "Curated Content - Spec"
type: "feature-spec"
status: "implemented"
created: "2026-08-06"
updated: "2026-08-06"
origin: "user request (all data in data/ as .md, curated from private source material, no sensitive leaks)"
---

# Curated Content

- Status: implemented
- Created: 2026-08-06
- Updated: 2026-08-06
- Origin: user request (all data in data/ as .md, curated from private source material, no sensitive leaks)

## Problem / motivation

All site content lives in the repository as Markdown, curated from personal
source material. Two facts make this the highest-risk feature in the backlog:

1. **The repository is public.** `data/**` is published the moment it is
   committed, independent of what the site renders.
2. **The source material is private and mixed.** Professional documents sit
   alongside material in every excluded category listed below. Nothing is safe
   by default, and the professional documents themselves carry direct contact
   details.

The failure mode this feature exists to prevent is a raw copy: a source
document moved into `data/` unreviewed, carrying fields the site would never
choose to render.

The safeguard cannot be a convention or a prompt. It has to be a schema the
loader enforces and a scanner that fails the build.

## Desired behavior

### Content model

- Every file under `data/**/*.md` carries front matter with at minimum:
  `id`, `type`, `locale`, `status`, `confidentiality`, `updated`.
- `locale` is `en` or `pt-BR`. Records pair across locales by shared `id`.
- `status` is `draft` or `published`. Only `published` reaches a view.
- `confidentiality` is `public` or `restricted`. Only `public` is renderable.
- A single `site_profile` record per locale is the sole source of name,
  headline, summary, and approved links. The page, the metadata layer, the
  resume PDF, and the chatbot all read it — none of them restate it.
- Adding or editing an experience entry, a case study, or a metric requires a
  Markdown edit only. No code change, no deploy-time code path.

### Type vocabulary

One record per file. Front matter carries structured metadata; the Markdown
body carries prose. **A value never appears in both** — duplicating a summary
into front matter is how the two drift apart.

Naming: `type` values are `snake_case`; `id` values and filenames are
`kebab-case`, and `id` always equals its filename without the extension. That
pairing is what lets a record be located from a citation alone, which
[chatbot](../chatbot/SPEC.md) depends on.

| `type` | Cardinality | Additional required keys | Body |
| ------ | ----------- | ------------------------ | ---- |
| `site_profile` | exactly one per locale | `name`, `headline`, `links` | positioning prose |
| `leadership` | exactly one per locale | `title` | how he leads, as prose |
| `experience` | one per role | `organization`, `role`, `start_date`, `prominence` | what the role involved |
| `case_study` | one per achievement | `title`, `organization`, `period`, `technologies` | `## Problem`, `## Approach`, `## Outcome` |
| `metric` | one per headline figure | `label`, `value`, `context` | none |
| `open_source` | one per project | `name`, `role`, `url` | what it does and why it matters |
| `skill_group` | one per domain grouping | `label`, `items` | none |
| `education` | one per credential | `institution`, `credential`, `year` | none |

- `end_date` is omitted on a current role rather than set to a sentinel value.
- `prominence` is `primary` or `secondary`, letting the page foreground recent
  or significant roles without deleting earlier history.
- `source_url` is optional on any record and carries public evidence for a
  claim. Its absence means the claim is self-attested — permitted, because the
  owner's metric policy allows internally-evidenced figures.

### Locale fallback

- Records pair across locales by shared `id`.
- When a requested locale has no counterpart for a published `id`, the reader
  is served the record that does exist rather than an empty section.
- A substituted record is marked as such in the rendered output, and its
  container carries a `lang` attribute reflecting the language actually shown,
  so a screen reader announces the switch instead of mispronouncing it.
- Consequence: shipping `en` first is valid. `pt-BR` records are added
  incrementally without a coordinated cutover.

### Enforcement

- The loader **fails loudly** on missing front-matter keys, on an unknown
  `type`, and on `status: published` combined with `confidentiality:
  restricted`.
- A spec proves a `draft` record cannot reach a rendered view.
- A content-safety scanner runs over both `data/**` and **rendered HTML**,
  failing on: email addresses, phone-number shapes, Brazilian document-number
  shapes (CPF, RG, CNH, passport), street addresses, and credential-like
  strings. A deliberate failing fixture proves the scanner actually fires.
- A grep gate asserts zero code references to filesystem paths outside the
  application root. The application never reads the private source material at
  runtime, in any environment.

### Publication policy

- **Permitted**: hard performance numbers, contribution and delivery metrics,
  named clients and employers, named open-source projects and download counts,
  education.
- **Excluded as employer-internal**, even though the metric policy is otherwise
  permissive: issue-tracker keys, pull-request numbers, internal repository
  names, and database table or column names. A performance win is described by
  its problem, technique, and result — naming the employer's schema adds
  nothing a reader values and discloses system internals.
- **No unverifiable inflation.** Where a figure in the source material
  conflicts with the evidence behind it, the lower sourced figure is published.
  A number a reference check contradicts is worse than no number.
- **Excluded without exception**: personal compensation in any form — pay
  rate, salary, day rate, share counts, equity value, option grants, revenue
  share attributed to the author's earnings.
- **Excluded**: legal identifiers, addresses, immigration and visa material,
  family, medical and financial data, credentials, internal URLs and hostnames,
  private-individual names, and any direct contact field not on the approved
  allowlist.
- The approved contact surface is exactly four entries, and nothing reaches the
  site outside it:
  - LinkedIn profile
  - GitHub profile
  - RubyGems profile
  - one forwarding alias on the site's own domain, revocable if it attracts
    abuse
- **No direct phone number and no personal email address** appears in HTML,
  JSON-LD, OG tags, the resume PDF, or any other downloadable asset. The
  personal address the source documents use is not on the allowlist and never
  becomes site content, even though it appears throughout the source material.
- **Provenance is not stored in this repository.** A source path names a
  private directory, so committing it publishes it — recording provenance in
  front matter would defeat the policy it is meant to support. Records cite
  public evidence via `source_url` only; the mapping back to private source
  documents stays with the curator, outside the repository.

## Constraints

- Private source documents are read-only external evidence held outside this
  repository. They are never copied verbatim into `data/`, never symlinked, and
  never mounted by the deployed application. Their location is supplied by the
  operator at curation time and is not recorded here.
- Curation is a human review step. Automated extraction into `data/` is not
  acceptable, because the scanner catches the shapes it knows and nothing else.
- A source document that has not been through review is unapproved and does not
  belong in `data/`, tracked or untracked.
- Both locales are first-class. A `published` record with no counterpart in the
  other locale must degrade predictably rather than render an empty section.

## Out of scope

- Rendering, layout, and section composition — see
  [landing-page](../landing-page/SPEC.md).
- A CMS, an admin UI, or a database-backed content store. Markdown in the
  repository is the store.
- Translation as a build step. Nothing in the application translates anything at
  runtime or in CI, and no record is published unreviewed. The English records
  are human-authored; the Portuguese ones were machine-drafted in one pass and
  reviewed by a human before publication, as recorded under Pending TODOs. What
  stays excluded is an automated pipeline that puts a record in `data/` without
  a human approving it.

## Pending TODOs

- [x] Define the exact `type` vocabulary and the required keys per type.
- [x] Decide the pt-BR fallback rule when a record exists in one locale only.
- [x] Fix the approved contact-link allowlist.
- [x] Record the forwarding alias in `site_profile` — `mauricio@zaffari.casa`,
      derived from the canonical origin in
      [deployment](../deployment/SPEC.md). The same address is set as this
      repository's local `user.email`, so commit metadata — itself a published
      surface on a public repo — stays inside the contact allowlist.
- [x] Confirm the Webstores 2.0 test-coverage figure. Resolved: both numbers
      are real but describe different things. The replatforming moved coverage
      from 72% to 80%; 98.6% is the codebase's current figure, which the resume
      wrongly attributed to the refactor. The case study carries the delta and
      a `metric` record carries the current value, so neither number has two
      homes.
- [x] Build the enforcement half — the loader, the content-safety scanner, the
      outside-app-root grep gate, and their specs. Done: see
      [IMPLEMENTATION.md](IMPLEMENTATION.md). `bin/ci` now fails on an invalid
      record, on unpublishable content in `data/**` or in rendered HTML, and on
      any application file naming a filesystem path outside the app root. The
      policy is a failing build rather than human review alone.
- [x] Author the `pt-BR` records. Done: 34 records, machine-drafted in one pass
      and reviewed before publication. Three judgement calls, all reversible:
      job titles keep *Tech Lead* untranslated because that is what the Brazilian
      industry says rather than *Engenheiro de Software Líder*; Looper's domain
      noun *scan* stays English because it reads as the product's own term; and
      city names are localised only where a common Portuguese exonym exists, so
      *Londres* and *São Francisco* but not *Alpharetta*.

      Figures carry Brazilian notation — `R$ 482.800`, `81,7%`, `244.000` — so
      the two locales are deliberately **not** byte-comparable on numbers. The
      value is identical and only the separators differ; a Portuguese page
      showing `R$ 482,800` claims four hundred and eighty-two reais, and `81.7%`
      reads as a typo.
