# Portfolio brand

## The mark

A geometric letterpress monogram: an ink "Z" anchored over a single accent
rule on a warm paper field. It evokes two-colour print, typographic discipline,
and the site's letterpress identity.

The approved geometry is in [mark-light.svg](mark-light.svg) and
[mark-dark.svg](mark-dark.svg), recreated from the production mark in
[public/icon.svg](../public/icon.svg). Both use a tightly cropped 280×324
viewBox (`0 0 280 324`). The Z glyph spans 280px wide and 256px high with 76px
horizontal bars, drawn as an outlined path rather than text to eliminate font
dependencies. The accent bar beneath spans the identical 280px width at 36px
height, separated from the glyph by 32px of clear space. [mark-paper.svg](mark-paper.svg)
preserves the 512×512 paper background field.

Every corner is square: `border-radius: 0` across all elements. Proportions are
fixed. Do not redraw, re-space, or round individual paths.

## Palette

| Name | Approved palette | Use |
|------|------------------|-----|
| Paper | `#FBF9F5` | Primary surface and canvas background |
| Paper Select | `#F3DED5` | Selection highlight background only |
| Rule | `#E5DFD3` | Hairlines between rows and secondary elements |
| Rule Strong | `#C7BFB0` | Section boundaries, list separators, card rules |
| Ink Faint | `#736B61` | Mono gutter labels, section ordinals, metadata |
| Ink Muted | `#5C554A` | Secondary prose, contexts, captions, share subhead |
| Ink Body | `#2E2A25` | Body prose, roles |
| Ink | `#141210` | Headings, metric figures, primary monogram glyph |
| Accent | `#B03A1A` | Links, focus outline, active locale bar, mark accent bar |
| Accent Deep | `#8A2C12` | Link hover and active states |

The site and brand operate strictly in `color-scheme: light`. There is no dark
mode and no inverted scheme. Dark mark and lockup variants exist solely for
external dark surfaces (terminal tools, slide decks, third-party embeds).

Contrast ratios are measured against Paper (`#FBF9F5`) under WCAG 2.1:
Ink (17.77:1 AAA), Ink Body (13.55:1 AAA), Ink Muted (7.00:1 AAA),
Ink Faint (4.99:1 AA), Accent (5.76:1 AA), Accent Deep (8.15:1 AAA).

The second ink (`#B03A1A`) is rationed. On resting surfaces, it appears only
twice: as the grounding rule in the mark, and as the 2px underline marking the
current locale in the language switcher. Everywhere else, it signifies an
interaction state (focus outline, hover, active). Rules (`#E5DFD3`, `#C7BFB0`)
never carry type.

See [palette.svg](palette.svg) for full swatches and the measured contrast matrix.

## Typography

Zero web-font budget: system stacks only, with no web-font requests or layout
shifts.

| Stack | Font family | Use |
|-------|-------------|-----|
| Sans | `-apple-system, BlinkMacSystemFont, "Segoe UI Variable Text", "Segoe UI", Roboto, "Noto Sans", "Helvetica Neue", Arial, system-ui, sans-serif` | What is said: prose, names, headings, credentials |
| Mono | `ui-monospace, "SF Mono", "Cascadia Mono", "Segoe UI Mono", "Roboto Mono", "Liberation Mono", "DejaVu Sans Mono", monospace` | What is measured: figures, dates, labels, tech names, ordinals |

Pairing principle: sans for narrative, mono for metrics. Mono figures enforce
`font-variant-numeric: tabular-nums` for vertical column alignment. Mono labels
use uppercase styling with loose tracking (`0.09em` to `0.12em`).

Three weights only: 400 (body), 500 (mono labels, roles), 700 (headings, metric
figures). No hairline (300) weight.

The wordmark in [lockup-light.svg](lockup-light.svg) and
[lockup-stacked-light.svg](lockup-stacked-light.svg) traces the approved
reference lettering as outlined vector paths. It has no installed-font dependency.

## Placement

Allow clear space of at least 25% of the mark's dimension around standalone
marks. The standalone SVGs are tightly cropped; add padding in the containing
layout rather than stretching the vector box. Lockup spacing and clear space are
built directly into the supplied lockup layouts.

Browser tabs and bookmarks use [favicon/favicon.svg](favicon/favicon.svg) or
`public/icon.svg`. The mark is calibrated to downscale cleanly to 16×16 and 32×32
without losing letterform recognition or the accent bar.

Social cards (`public/og-image.png`) use a 1200×630 canvas. All critical brand
elements (host label, name, headline, accent rule) must sit inside the central
630×630 square safe area. This guarantees that messaging platforms (such as
WhatsApp) cropping the card to a 1:1 thumbnail do not clip text.

## Do not

- Stretch, rotate, skew, or distort the mark.
- Round corners: `border-radius: 0` is mandatory; no softened radii.
- Add gradients, drop shadows, bevels, glows, blur, or surface elevation.
- Introduce dark mode, inverted palettes, or alternative surface tones for the site.
- Substitute Accent (`#B03A1A`) with any other accent hue.
- Render typography in decorative rule colours (`#E5DFD3`, `#C7BFB0`).
- Make wordmark typography red; the second ink is strictly reserved for the mark's accent bar.
- Use icons, emojis, badges, or stock photography.
- Load external web fonts.
- Animate mark entrance, geometry transforms, or metric counters.

## Files

| File | Use |
|------|-----|
| [mark-light.svg](mark-light.svg) | Approved mark for light backgrounds (transparent) |
| [mark-dark.svg](mark-dark.svg) | Approved mark for dark backgrounds (transparent) |
| [mark-paper.svg](mark-paper.svg) | Approved mark on 512×512 Paper background |
| [lockup-light.svg](lockup-light.svg) | Approved horizontal lockup for light backgrounds |
| [lockup-dark.svg](lockup-dark.svg) | Approved horizontal lockup for dark backgrounds |
| [lockup-stacked-light.svg](lockup-stacked-light.svg) | Approved stacked lockup for light backgrounds |
| [lockup-stacked-dark.svg](lockup-stacked-dark.svg) | Approved stacked lockup for dark backgrounds |
| [favicon/](favicon/) | `favicon.svg`, 16/32/48/180/512 PNG exports, and `favicon.ico` |
| [palette.svg](palette.svg) | Approved palette sheet with WCAG 2.1 contrast |
| [brand-sheet.svg](brand-sheet.svg), [brand-sheet.png](brand-sheet.png) | Complete asset preview and small-size legibility test |
| [comparison.svg](comparison.svg), [comparison.png](comparison.png) | Approved light/dark comparison |
| `public/icon.svg`, `public/icon.png` | Production web icon and favicon |
| `public/og-image.png` | Production social share card / Open Graph image (1200×630) |
| `lib/tasks/site.rake` | Authoring task `bin/rails site:images` to rebuild public PNGs |
| `DESIGN.md` | Binding design system specification and stylesheet token contract |
| `README.md` | Directory asset index |
