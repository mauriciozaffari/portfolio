---
title: "Site Metadata - Spec"
type: "feature-spec"
status: "implemented"
created: "2026-08-06"
updated: "2026-08-06"
origin: "operational need (the site is a professional showcase; how it appears when shared is part of the product)"
---

# Site Metadata

- Status: implemented — see [IMPLEMENTATION.md](IMPLEMENTATION.md)
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

- [x] Decide the AI/LLM crawler policy — allow, disallow, or selective.
      Resolved: **allow, without exception.** The site exists to be found, and a
      growing share of its readers meet it through an assistant answering
      someone else's question rather than through a browser; an assistant that
      cannot read this page answers from something worse. `robots.txt` states
      the decision in prose so it cannot later be mistaken for a default nobody
      overrode, and a spec asserts the statement is still there. The only
      `Disallow` is the container health check.
- [x] Decide whether the share image is a static asset or generated from
      content. Resolved: **static, generated from content at authoring time.**
      `bin/rails site:images` builds it from the `site_profile` record with
      ImageMagick and the PNG is committed; the runtime image has neither
      ImageMagick nor a headless browser, and a scraper fetches the file once
      and caches it. Verified byte-identical across runs.
- [ ] Validate the card through each platform's own unfurl debugger after the
      first deploy. The image was rendered and inspected, but LinkedIn's and
      Slack's scrapers cannot reach a local server, so the end-to-end unfurl is
      the one acceptance criterion that needs a live origin.
- [ ] Decide whether a stale share card should fail the build. `site:images` is
      an authoring tool that CI cannot run — it needs ImageMagick and two fonts
      the container does not have — so editing the profile's `name` or
      `headline` leaves the committed PNG showing the old one until someone
      reruns the task, and nothing detects that.
