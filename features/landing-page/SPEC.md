---
title: "Landing Page - Spec"
type: "feature-spec"
status: "spec'd"
created: "2026-08-06"
updated: "2026-08-06"
origin: "user request (single landing page, visually appealing, clean and simple)"
---

# Landing Page

- Status: spec'd
- Created: 2026-08-06
- Updated: 2026-08-06
- Origin: user request (single landing page, visually appealing, clean and simple)

## Problem / motivation

The site is one page whose job is to convince a hiring manager or founder,
inside about thirty seconds, that the author is a credible Ruby on Rails tech
lead. It is also a work sample: a portfolio that looks generic argues against
its own claims.

This feature owns both the page and its visual language. They are deliberately
not split. A design system exists to serve multiple surfaces, and there is
exactly one page — extracting tokens and components before the page that
consumes them is speculative abstraction. What must not be improvised is the
design *decision*, so it is recorded in this spec before implementation and
extracted into a reusable system only if a second surface ever appears.

## Desired behavior

### Structure

- One canonical route (`/`), locale-aware for `en` and `pt-BR`. No client-side
  routing.
- Fully server-rendered. **With JavaScript disabled, all content and all
  in-page navigation work.**
- Sections, in narrative order: positioning, sourced impact, experience and
  case studies, leadership approach, open source and community, skills and
  education, approved contact links.
- In-page navigation uses native anchors targeting real element IDs.
- All copy and data come from [curated-content](../curated-content/SPEC.md)
  records. No content is hardcoded in a view.
- A visible language switcher preserves the reader's scroll position intent by
  linking to the equivalent locale URL.

### Hotwire

- Turbo and Stimulus are used only where they earn their place, with a recorded
  rationale per usage. **Zero Stimulus controllers is an acceptable outcome**
  for this feature and is not a failure.

### Design direction

Recorded here before implementation, and binding on it:

- Type scale, with the display/body/mono families named explicitly.
- Palette expressed as a ramp with stated contrast ratios, not a single accent
  reused at varied opacity.
- Spacing rhythm from one base unit.
- Depth strategy chosen and committed to (borders, shadows, or tonal shift).
- Motion budget, including what does *not* animate.
- Reference influences named, so the result is a deliberate position rather
  than an average of defaults.

### Verified non-functionals

Accessibility and performance are properties of this markup, not a later
phase. They are acceptance criteria here, executable where possible:

- Exactly one `<h1>`; no heading-level skips; landmark elements present.
- Keyboard focus visible on every interactive element; full keyboard traversal.
- WCAG AA text contrast across the palette.
- Images carry dimensions and meaningful `alt`; `prefers-reduced-motion`
  honored.
- `lang` attribute correct per locale.
- No render-blocking third-party requests; declared web-font budget; stated
  transferred-byte ceiling; no layout shift from late-arriving assets.
- Verified by screenshots at mobile, tablet, and desktop widths — not by
  assertions alone.

## Constraints

- Clean and simple implementation. A component abstraction is introduced on its
  second use, not in anticipation of one.
- No React, no SPA, no client-side rendering framework.
- The page renders only `published` + `public` records; it never reaches around
  the content loader.
- Compensation details never appear, in any section, in either locale.

## Out of scope

- OG tags, JSON-LD, sitemap, robots policy — see
  [site-metadata](../site-metadata/SPEC.md).
- The downloadable resume — see [resume-download](../resume-download/SPEC.md).
- Chat UI — see [chatbot](../chatbot/SPEC.md).
- A blog, an analytics integration, and a contact form. None are requested.

## Pending TODOs

- [ ] Write the `## Design direction` values into this spec before any UI code
      is written.
- [ ] Decide the locale URL strategy (`/pt-BR` path prefix vs alternatives) —
      the choice constrains [site-metadata](../site-metadata/SPEC.md) hreflang.
- [ ] Decide whether the impact section leads with metrics or with named
      clients.
