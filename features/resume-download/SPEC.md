---
title: "Resume Download - Spec"
type: "feature-spec"
status: "implemented"
created: "2026-08-06"
updated: "2026-08-06"
origin: "user request (downloadable resume, publication-safe build)"
---

# Resume Download

- Status: implemented
- Created: 2026-08-06
- Updated: 2026-08-06
- Origin: user request (downloadable resume, publication-safe build)
- Built: see [IMPLEMENTATION.md](IMPLEMENTATION.md)

## Problem / motivation

Recruiters and hiring managers ask for a file. Sending them to a URL and hoping
they copy-paste it into their ATS loses candidates.

The existing resume documents cannot be uploaded as they are: they carry a
direct phone number, a personal email, and a home city. A public download is a
permanent, uncontrolled artifact — once it is fetched, it circulates. It needs
its own publication-safe build rather than a copy of the private original.

Building it from the same content records as the page also removes the classic
portfolio failure where the site and the PDF quietly disagree about dates,
titles, and numbers.

## Desired behavior

- A downloadable resume is offered from the landing page, per locale (`en` and
  `pt-BR`).
- The document is generated from the same `published` + `public` records that
  render the page. There is no separately maintained resume source.
- The contact block contains only the approved professional-profile allowlist.
  **No phone number, no personal email, no street address.**
- No compensation details in any form.
- The generated file passes the same content-safety scanner as `data/**` and
  the rendered HTML, including a check of the extracted PDF text — not just the
  source markup.
- Document metadata (title, author, producer fields) is set deliberately and
  contains nothing outside the allowlist.
- The filename is stable and professional.
- Regenerating after a content change requires no manual editing step.

## Constraints

- The original private resume documents are reference material only. They are
  never published, and their contact block is never carried over.
- The artifact is public and permanent once fetched. Treat every field as
  non-retractable.

## Out of scope

- A cover letter download.
- Gating the download behind a form or an email capture. No contact form is
  planned.
- Preserving the exact visual design of the existing resume documents.

## Decisions

- **Prawn, pure Ruby.** No headless Chrome in the production image and no Node,
  so the container stays slim and no live request depends on a browser
  rendering.
- **The layout is deliberately distinct from the page**, which is the cost of
  the Prawn choice. The mitigation is that layout is the *only* thing that can
  diverge: both surfaces read the same `published` + `public` records, so the
  facts, dates, and figures cannot drift apart. A spec asserts the PDF's
  content is derived from those records rather than restated.
- **The document is the whole corpus, not a shortlist.** Falls straight out of
  the rule above: choosing which records belong on a resume would be a second
  editorial rule, and a second editorial rule is what drifts. The consequence is
  a multi-page dossier rather than a one-page CV, recorded in
  [IMPLEMENTATION.md](IMPLEMENTATION.md).

## Pending TODOs

- [x] Build it. Done: two locale routes generating from `Content::Repository`
      through `LandingPage`, with both the extracted PDF text and the document
      information dictionary scanned by `Content::SafetyScanner`, and a failing
      fixture proving that scan fires. See
      [IMPLEMENTATION.md](IMPLEMENTATION.md).
- [ ] Decide whether a one-page variant is worth having. Nothing blocks on it,
      and the honest way to build one is a key on the records rather than a
      selection rule inside this feature.
- [ ] Revisit the untagged-PDF accessibility gap if a reader reports it. Prawn
      emits no structure tree and no `/Lang`; the accessible surface is the HTML
      page, which the document's colophon links back to.

