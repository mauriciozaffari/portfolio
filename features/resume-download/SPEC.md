---
title: "Resume Download - Spec"
type: "feature-spec"
status: "implemented"
created: "2026-08-06"
updated: "2026-10-05"
origin: "user request (concise resume plus complete profile download)"
---

# Resume Download

- Status: implemented
- Created: 2026-08-06
- Updated: 2026-10-05
- Built: see [IMPLEMENTATION.md](IMPLEMENTATION.md)

## Problem / motivation

The complete record-derived PDF is a dossier, not a recruiting resume. Offer
Mauricio's edited two-page resume first, while retaining the complete profile
for readers who want the case studies and career detail.

## Desired behavior

- Both landing pages and contact pages offer the concise English resume first.
  Portuguese labels explicitly say that this document is in English.
- `/resume-short.pdf` serves the reviewed English PDF as an attachment, with a
  professional filename and the site's hardened response headers. Legacy
  browsers and applicant tracking systems can download it.
- `/resume.pdf` and `/pt-BR/resume.pdf` remain unchanged: complete profiles
  generated on request from the published, public records in their own locale.
- Link labels distinguish the two-page resume from the complete profile.
- The concise PDF has exactly two US Letter pages with readable body type
  (at least 10pt), a single column and selectable text.
- Both downloads carry only allowlisted contact channels. No phone, street
  address, private-individual name or personal compensation is published.
- CI scans the actual concise PDF's extracted text and readable metadata with
  `Content::SafetyScanner`, checks its page count, and checks selected facts
  against the published records. The existing generated-PDF guards remain.
- Metadata contains no private path or contact field. Authoring tools are not
  needed in the production image.
- Markdown twins and the agent guide identify both downloads.

## Constraints

- The private source tree stays ignored. Only the reviewed publication-safe
  PDF is committed, outside `public/`, and served by the controller.
- Human review remains necessary for names and factual accuracy. Scanner-clean
  does not mean publication-safe, and selected fact checks cannot prove all
  prose agrees with the records.
- The authored resume is a second editorial source, accepted by the owner on
  2026-10-05. Updating records requires reviewing the concise resume for drift.
- The full profile remains single-source: generated from records without
  manual editing or production persistence.
- Existing complete-profile URLs and filenames remain stable.

## Out of scope

- Cover letter download or signup gate.
- A Portuguese translation of the concise resume in this change.
- Automated inference of which records belong in the concise resume.

## Pending TODOs

- [x] Ship the concise public PDF and both download links with CI guards.
- [ ] Revisit tagged-PDF accessibility if a reader reports a problem. The HTML
      profile remains the accessible alternative.
