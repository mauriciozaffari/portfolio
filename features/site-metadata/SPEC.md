---
title: "Site Metadata - Spec"
type: "feature-spec"
status: "spec'd"
created: "2026-08-06"
updated: "2026-08-06"
origin: "operational need (the site is a professional showcase; how it appears when shared is part of the product)"
---

# Site Metadata

- Status: spec'd
- Created: 2026-08-06
- Updated: 2026-08-06
- Origin: operational need (the site is a professional showcase; how it appears when shared is part of the product)

## Problem / motivation

This site will be pasted into LinkedIn messages, recruiter emails, and Slack
threads far more often than it will be browsed to directly. The unfurled card
is frequently the only thing a reader sees. It is part of the product, not an
afterthought.

It is also a second surface where personal data can escape: OG tags and JSON-LD
are structured, machine-readable, and easy to populate carelessly with a phone
number or an email that the visible page correctly omits.

This feature follows [deployment](../deployment/SPEC.md) because every value it
produces is an absolute URL.

## Desired behavior

- Absolute canonical URL per locale, with `hreflang` alternates linking the
  `en` and `pt-BR` versions and an `x-default`.
- Open Graph and Twitter card tags with a correctly sized share image, and
  `og:locale` / `og:locale:alternate` set. **Validated by rendering the card,
  not by reading the markup.**
- `schema.org/Person` JSON-LD built from the `site_profile` record, asserted to
  contain no contact fields outside the approved allowlist.
- `robots.txt` with a **deliberate** policy for both search crawlers and
  AI/LLM crawlers. This is a decision to make, not a default to inherit.
- `sitemap.xml` covering both locales, with `lastmod` derived from content
  `updated` values rather than build time.
- Favicon and app icons.
- The metadata layer passes the same forbidden-pattern scan as the page.

## Constraints

- All values derive from the `site_profile` record in
  [curated-content](../curated-content/SPEC.md). Metadata never restates
  content that lives in a record, so the two cannot drift.
- No direct phone number or personal email in any tag, attribute, or JSON-LD
  field.

## Out of scope

- Analytics, tag managers, and third-party pixels. None are requested, and each
  is a render-blocking third-party request the landing page forbids.
- Search-console verification workflows beyond the meta tag itself.

## Pending TODOs

- [ ] Decide the AI/LLM crawler policy — allow, disallow, or selective. The
      site's purpose argues for being found, including by assistants doing
      candidate research.
- [ ] Decide whether the share image is a static asset or generated from
      content.
