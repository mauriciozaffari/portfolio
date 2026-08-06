---
title: "Resume Download - Spec"
type: "feature-spec"
status: "spec'd"
created: "2026-08-06"
updated: "2026-08-06"
origin: "user request (downloadable resume, publication-safe build)"
---

# Resume Download

- Status: spec'd
- Created: 2026-08-06
- Updated: 2026-08-06
- Origin: user request (downloadable resume, publication-safe build)

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

## Pending TODOs

- [ ] Decide the generation approach (rendered HTML to PDF at build time vs on
      request) and where the artifact is stored given the stateless container.
- [ ] Decide whether the PDF layout is shared with, or deliberately distinct
      from, the landing page design direction.
