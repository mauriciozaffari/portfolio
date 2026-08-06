---
title: "Landing Page - Spec"
type: "feature-spec"
status: "implemented"
created: "2026-08-06"
updated: "2026-08-06"
origin: "user request (single landing page, visually appealing, clean and simple)"
---

# Landing Page

- Status: implemented
- Created: 2026-08-06
- Updated: 2026-08-06
- Origin: user request (single landing page, visually appealing, clean and simple)
- Implementation: [IMPLEMENTATION.md](IMPLEMENTATION.md)

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

Recorded before implementation and binding on it. The full seven-section
treatment — component states, measured ratios for every pair, and the reasoning
behind each choice — is [DESIGN.md](../../DESIGN.md). What follows is the token
contract itself, restated here so this spec stands alone.

**Atmosphere.** A two-ink letterpress specimen: warm paper, one black ink for
everything that is said, one red ink reserved for everything you can touch. The
memorable element is the mono gutter of letter-spaced, numbered section labels
against hairline rules. Reference influences: the Linear and Notion register for
type-led restraint, two-colour print for the stock, the gutter, and the rules.

**Palette**, as a ramp with measured WCAG 2.1 ratios on `--color-paper`:

| Token | Hex | Ratio | Role |
| ----- | --- | ----- | ---- |
| `--color-paper` | `#FBF9F5` | — | the only surface in the stylesheet |
| `--color-paper-select` | `#F3DED5` | 1.23:1 | `::selection` background, nothing else |
| `--color-rule` | `#E5DFD3` | 1.26:1 | row hairlines; never holds type |
| `--color-rule-strong` | `#C7BFB0` | 1.74:1 | section hairlines; never holds type |
| `--color-ink-faint` | `#736B61` | 4.99:1 | mono labels, ordinals, meta |
| `--color-ink-muted` | `#5C554A` | 7.00:1 | secondary prose, contexts |
| `--color-ink-body` | `#2E2A25` | 13.55:1 | body prose |
| `--color-ink` | `#141210` | 17.77:1 | headings, metric figures |
| `--color-accent` | `#B03A1A` | 5.76:1 | hover, focus ring, current locale |
| `--color-accent-deep` | `#8A2C12` | 8.15:1 | active |

Every stop that carries text clears 4.5:1, including on `paper-select`. The
accent is rationed to four states and never used as decoration; the one at-rest
instance is the current-locale underline. `color-scheme: light`, declared. No
dark scheme — a second contrast matrix for a page with one job.

**Type.** No web font: the declared budget is zero bytes and zero requests, so
there is no `font-display` swap reflow to design around. Families are named
explicitly, and the voice comes from the pairing — sans for what is said, mono
for what is measured, with `tabular-nums` on every figure:

- `--font-sans`: `-apple-system, BlinkMacSystemFont, "Segoe UI Variable Text",
  "Segoe UI", Roboto, "Noto Sans", "Helvetica Neue", Arial, system-ui,
  sans-serif`
- `--font-mono`: `ui-monospace, "SF Mono", "Cascadia Mono", "Segoe UI Mono",
  "Roboto Mono", "Liberation Mono", "DejaVu Sans Mono", monospace`

Scale on a 16px base, discrete steps only — no `clamp()`, because a fluid step
has no single value to state or verify at a breakpoint: `--text-2xs` 11px,
`--text-xs` 12px, `--text-sm` 13px, `--text-base` 16px, `--text-lg` 17px,
`--text-xl` 19px, `--text-2xl` 24px, `--text-3xl` 32px, `--text-4xl` 44px,
`--text-5xl` 64px. Each step carries its own line height and tracking, with
tracking growing negative as size grows. Three weights: 400, 500, 700.

**Spacing.** One base unit, `--spacing: 0.25rem`. Every gap, margin and padding
is an integer multiple of it; there are no arbitrary values. Vertical rhythm
uses four multiples: 8px label-to-thing, 16px paragraph, 32px entry, 80px
mobile / 112px desktop between sections. Prose measure `--container-measure`
58ch, which measured 67-72 characters per line at desktop widths; page cap
`--container-page` 72rem.

**Depth: hairline rules, and nothing else.** One background colour for the whole
document, structure from 1px rules plus vertical rhythm. No shadows, no
elevation, no filled panels, no `border-radius` — those tokens do not exist.
Tonal shift applies to ink, not to surfaces: importance is darkness.

**Motion budget.** Colour-only transitions at 120ms on interactive elements,
plus smooth scrolling for anchors. Deliberately not animated: page entrance,
scroll-triggered reveals, metric count-ups, any `transform`, any opacity fade,
the locale switch, and the sticky section label. There is no `@keyframes` rule
in the stylesheet. `prefers-reduced-motion: reduce` drops scrolling to `auto`
and transitions to `0.01ms`.

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

## Decisions

- **Visual register: minimal editorial.** Type-led, restrained, tonal depth
  rather than ornament, one accent used only for interaction. Reference
  influences are the Linear and Notion register. Chosen because the content is
  the argument here — a portfolio that looks overdesigned undercuts a claim of
  engineering judgement, and this register ages better than a gradient-heavy
  one. The concrete token values still have to be written into
  `## Design direction` before any UI code exists.
- **Locale URLs: `/` serves `en`, `/pt-BR` serves Portuguese.** A path prefix,
  not a subdomain and not content negotiation, so every locale has one stable
  canonical URL that [site-metadata](../site-metadata/SPEC.md) can point
  `hreflang` at.

## Pending TODOs

- [x] Write the `## Design direction` token values into this spec, then
      `DESIGN.md`, before any UI code is written. Done: the token contract is in
      `## Design direction` above and the full treatment is
      [DESIGN.md](../../DESIGN.md), both written before the first line of CSS.
- [x] Decide whether the impact section leads with metrics or with named
      clients. Resolved: **metrics**, and the constraint decided it. A
      client-led opening would be a list of studio names, and those names exist
      only inside `site_profile` prose and `metric` contexts — assembling them
      into a logo-wall equivalent means writing them into a view, which the
      no-hardcoded-content rule forbids. Leading with metrics costs nothing,
      because the studio names arrive one section earlier in the positioning
      prose and each `metric` context names its own client. The reader meets
      Disney, Warner Bros, Sony and NBCUniversal in the first paragraph and the
      numbers immediately after.
- [ ] Decide whether `source_url` becomes a visible citation. Four records carry
      public evidence for a claim and the page currently loads it and renders
      nothing. The two options both cost something: an accent link inside a
      metric figure breaks the rule that the accent is reserved for interaction
      at rest, and a separate "source" line needs a new chrome label. Parked
      rather than improvised, because a half-cited page is worse than an
      uncited one.
- [ ] Give `metric` and `skill_group` an ordering key, or accept id order for
      good. They are the only two types the page cannot order meaningfully, so
      they render alphabetically. This is a
      [curated-content](../curated-content/SPEC.md) schema change, not a page
      change.
