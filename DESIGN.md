# Design

The visual language of [zaffari.casa](README.md). One page consumes it, so it
lives here as a decision record rather than as an extracted component library —
see [features/landing-page/SPEC.md](features/landing-page/SPEC.md) for why.

This document is **binding on the CSS**. Every colour, size, spacing and timing
value in `app/assets/tailwind/application.css` traces to a token named here. A
value that is not in this file does not belong in the stylesheet.

## 1. Atmosphere and identity

**A two-ink letterpress specimen.** Warm paper, one black ink for everything
that is said, one red ink reserved for everything you can touch. The page is a
single sheet divided by hairline rules, not a stack of floating cards.

The one thing a visitor remembers: **numbered section labels set in a
letter-spaced mono gutter, hairline rules, and a red second ink that only
appears under the cursor.** The craft is in the rhythm and the figures, not in
an effect. Nothing glows, nothing floats, nothing fades in.

Reference influences, as the SPEC requires them to be named: the Linear and
Notion register for restraint and type-led hierarchy; two-colour print — a
technical specimen sheet or a Monocle-style standfirst — for the warm stock,
the mono gutter, and the rules.

Why this and not something louder: the content is the argument. It carries hard
performance numbers, named studio clients, an eighteen-year arc. A portfolio
that reaches for gradients and elevation is arguing that the work needs help.
The deliberate anti-goals are the generic AI-SaaS defaults: no purple-blue
gradient hero, no three-card feature grid, no `rounded-2xl`, no drop shadows,
no stock photography, no icon set, no emoji.

## 2. Colour

One warm-neutral ink ramp plus one accent hue. Expressed as discrete stops, not
as one colour at varied opacity — an opacity ramp cannot have its contrast
stated, and the SPEC requires stated contrast.

Ratios below are **measured** with the WCAG 2.1 relative-luminance formula, not
estimated. Thresholds: 4.5:1 for text under 24px, 3:1 for text at 24px and
above and for non-text UI, per WCAG 1.4.3 and 1.4.11.

### The ramp

| Token | Hex | On `paper` | Verdict | Used for |
| ----- | --- | ---------- | ------- | -------- |
| `--color-paper` | `#FBF9F5` | — | the only surface | document background, everywhere |
| `--color-paper-select` | `#F3DED5` | 1.23:1 | surface only | `::selection` background, nothing else |
| `--color-rule` | `#E5DFD3` | 1.26:1 | decorative | hairlines between rows and sections |
| `--color-rule-strong` | `#C7BFB0` | 1.74:1 | decorative | section-boundary hairlines, list separators |
| `--color-ink-faint` | `#736B61` | 4.99:1 | AA at any size | mono labels, section ordinals, meta |
| `--color-ink-muted` | `#5C554A` | 7.00:1 | AAA at any size | secondary prose, contexts, captions |
| `--color-ink-body` | `#2E2A25` | 13.55:1 | AAA at any size | body prose, roles |
| `--color-ink` | `#141210` | 17.77:1 | AAA at any size | headings, metric figures |
| `--color-accent` | `#B03A1A` | 5.76:1 | AA at any size | links, focus ring, current locale |
| `--color-accent-deep` | `#8A2C12` | 8.15:1 | AAA at any size | link hover and active |

Text on `--color-paper-select`, measured, because a reader can select any of it:
`ink` 14.43:1, `ink-body` 11.00:1, `accent` 4.68:1, `accent-deep` 6.62:1. Every
pair clears 4.5:1.

The two decorative stops carry no text and encode no information a sighted-only
reader would otherwise miss, so WCAG 1.4.11 does not apply to them. They are
recorded here so nobody later mistakes them for a text colour: `rule` and
`rule-strong` must never hold type.

### How the accent is rationed

`accent` is the second ink. It appears in exactly four places, all of them a
state rather than decoration:

1. `:hover` on any link.
2. `:focus-visible` on any interactive element, as the outline colour.
3. `:active`, in `accent-deep`.
4. The current locale in the language switcher, as a 2px underline.

Item 4 is the one at-rest instance, and it is deliberate: it proves the second
ink exists on first paint, and it marks where the reader already is. Everything
else on a resting page is black ink on warm paper.

### Colour scheme

`color-scheme: light`. Light only, declared rather than defaulted, so the
browser stops fighting the page over scrollbars and form controls.

A dark scheme is a second contrast matrix and a second set of ink decisions for
a page that has one job. Skipping it is the same judgement as skipping the web
font: it is not free, and nothing here needs it. Recorded as a decision, not an
oversight.

## 3. Typography

### Families

Named explicitly, and **no web font is loaded**. Zero font bytes, zero font
requests, zero `font-display` swap reflow.

```
--font-sans: -apple-system, BlinkMacSystemFont, "Segoe UI Variable Text",
             "Segoe UI", Roboto, "Noto Sans", "Helvetica Neue", Arial,
             system-ui, sans-serif;

--font-mono: ui-monospace, "SF Mono", "Cascadia Mono", "Segoe UI Mono",
             "Roboto Mono", "Liberation Mono", "DejaVu Sans Mono", monospace;
```

This is the one place where the register argues with conventional design
advice, so the reasoning is written down. A self-hosted variable font is the
usual way to get a distinctive voice. It costs a real request, a
`font-display` decision, and either a swap reflow or metric overrides tuned per
fallback — against an acceptance criterion that says *no layout shift from
late-arriving assets*. The SPEC asks for a declared web-font budget; the
declared budget is zero, and the voice comes from the pairing instead.

The pairing is the voice: **sans for what is said, mono for what is measured.**
Every figure, date, label, technology name, gem name and section ordinal is
mono. Every sentence is sans. A reader never has to work out which is which,
and on a page whose credibility rests on numbers, the numbers get the face that
aligns in columns.

- `font-variant-numeric: tabular-nums` on every mono figure, so the metric
  column aligns and digits do not shift between locales.
- Mono labels are set uppercase with real letter-spacing. No synthetic small
  caps, no `font-stretch`.
- Prose measure is capped at `--container-measure` (58ch), which measured 67-72
  characters per line at 1024px and above — inside the 60-75 target. The `ch`
  unit is the `0` advance, which is wider than an average lowercase letter, so
  58ch buys roughly 70 characters rather than 58. The first attempt at 66ch
  measured 77 and was tightened after looking at it.
- Prose is left-aligned and unjustified throughout. No hyphenation, so no
  language-dependent hyphenation dictionary changes the rag between locales.

### Scale

Base 16px. Discrete steps only — no `clamp()`, no fluid interpolation, because
a fluid step has no single value to state and cannot be verified at a
breakpoint. Larger sizes are reached with responsive utilities at the three
verified widths instead.

| Token | Size | Line height | Tracking | Role |
| ----- | ---- | ----------- | -------- | ---- |
| `--text-2xs` | 0.6875rem / 11px | 1.45 | 0.12em | mono micro-label, substitution marker |
| `--text-xs` | 0.75rem / 12px | 1.5 | 0.09em | mono section label, nav, meta |
| `--text-sm` | 0.8125rem / 13px | 1.6 | 0.01em | mono data rows, footnotes |
| `--text-base` | 1rem / 16px | 1.6 | 0 | compact prose, secondary entries |
| `--text-lg` | 1.0625rem / 17px | 1.7 | -0.003em | body prose, the default reading size |
| `--text-xl` | 1.1875rem / 19px | 1.6 | -0.006em | lead prose, roles |
| `--text-2xl` | 1.5rem / 24px | 1.3 | -0.014em | h3, entry titles |
| `--text-3xl` | 2rem / 32px | 1.2 | -0.018em | h2 at desktop, headline at mobile |
| `--text-4xl` | 2.75rem / 44px | 1.1 | -0.022em | headline, metric figures |
| `--text-5xl` | 4rem / 64px | 1.02 | -0.028em | h1 at desktop |

Negative tracking grows with size, which is how optical sizing works on faces
that have no optical size axis: large type set at default tracking looks loose.

### Weight

Three weights only: 400 body, 500 for mono labels and roles, 700 for headings
and metric figures. No 300 — hairline weights are unreadable on the warm
low-contrast stock and inconsistent across the fallback stack.

## 4. Spacing

One base unit: `--spacing: 0.25rem` (4px). Every margin, padding and gap in the
stylesheet is an integer multiple of it, expressed through the utility scale
(`gap-4` = 4 × 4px = 16px). There are no arbitrary spacing values.

The rhythm that matters is vertical, and it comes from four multiples:

| Step | Multiple | Value | Role |
| ---- | -------- | ----- | ---- |
| tight | 2 | 8px | label to the thing it labels |
| close | 4 | 16px | paragraph to paragraph |
| block | 8 | 32px | entry to entry inside a section |
| section | 20 / 28 | 80px / 112px | section to section, mobile / desktop |

Horizontal page frame: `px-5` (20px) at mobile, `px-10` (40px) from 768px,
`px-16` (64px) from 1024px. Outer width caps at `--container-page` (72rem).

Measures: `--container-measure` 58ch for prose, `--container-narrow` 44rem for
short-line blocks such as the headline and the metric contexts.

Anchor landings get `--scroll-offset` (32px) of `scroll-margin-top` so a jumped
heading is not welded to the viewport edge.

## 5. Components and their states

Every interactive element shares one focus treatment, declared once in the base
layer: `outline: 2px solid var(--color-accent)` with `outline-offset: 2px`, on
`:focus-visible`. **Never a border** — a border would change the box and shift
the layout on focus. Outline is drawn outside the box and costs no reflow.

| Component | Rest | Hover | Focus-visible | Active | Current |
| --------- | ---- | ----- | ------------- | ------ | ------- |
| Skip link | visually hidden | — | visible at top-left, `paper` on hairline box, `ink` text | — | — |
| Section nav link | mono xs uppercase, `ink-faint` | `accent`, underline appears | accent outline | `accent-deep` | n/a |
| Language switcher | mono xs, `ink-faint` | `accent`, underline | accent outline | `accent-deep` | `ink` with 2px `accent` underline, `aria-current="page"` |
| Prose link | `accent`, 1px underline, offset 0.15em | `accent-deep`, 2px underline | accent outline | `accent-deep` | n/a |
| Back to top | mono xs, `ink-faint` | `accent`, underline | accent outline | `accent-deep` | n/a |
| Section label (gutter) | mono xs uppercase `ink-muted`, ordinal in `ink-faint`, sticky from 1024px | — | — | — | — |
| Metric row | `rule` hairline top, mono `text-4xl` `ink` figure, mono xs `ink-faint` label, sans `text-lg` `ink-muted` context | — | — | — | — |
| Experience entry, primary | `rule-strong` hairline top, `text-2xl` `ink` organization, `text-xl` `ink-body` role, mono xs `ink-faint` meta, `text-lg` `ink-body` prose | — | — | — | — |
| Experience entry, secondary | `rule` hairline top, `text-xl` `ink` organization, `text-base` `ink-body` role, mono xs `ink-faint` meta, `text-base` `ink-muted` prose | — | — | — | — |
| Case study | `rule-strong` hairline top, `text-2xl` `ink` title, mono xs `ink-faint` meta and technologies, body headings demoted to mono xs uppercase `ink-faint` | — | — | — | — |
| Skill group | mono xs uppercase `ink-faint` label, `text-lg` `ink-body` terms separated by an `ink-faint` middot | — | — | — | — |
| Education row | `rule` hairline top, `text-lg` `ink-body` credential, mono xs `ink-faint` institution, mono `text-sm` tabular year | — | — | — | — |
| Substitution notice | `rule-strong` 1px box, no fill, mono xs `ink-muted` | — | — | — | — |
| Substitution marker | mono 2xs uppercase `ink-faint` in brackets, plus a visually hidden sentence | — | — | — | — |

Two rules that hold everywhere:

- **`border-radius: 0`.** No radius token exists. Every corner on this page is
  square, including the focus outline and the notice box.
- **No `box-shadow`.** No shadow token exists either. See section 7.

## 6. Motion

The budget is deliberately close to nothing, because nothing on this page needs
to move to be understood.

**Animates:**

| What | Property | Duration | Easing |
| ---- | -------- | -------- | ------ |
| Any link or focusable element | `color`, `text-decoration-color`, `border-color`, `outline-color` | `--duration-tap` 120ms | `--ease-tap` `cubic-bezier(0.2, 0, 0.13, 1)` |
| In-page anchor jump | `scroll-behavior: smooth` on the root | browser default | browser default |

**Deliberately does not animate**, each for a reason:

- **Page entrance.** No fade-up, no staggered reveal. A resume that has to
  perform its own arrival is stalling. It also delays the first readable frame.
- **Scroll-triggered section reveals.** They require JavaScript, they hide
  content from a reader who scrolls fast, and they break Ctrl-F.
- **Metric figures.** No count-up. The number is the claim; animating it turns
  a fact into a trick, and it lands as a layout shift.
- **Geometry.** No `transform`, no `scale`, no `translate`, anywhere. There is
  not one `@keyframes` rule in the stylesheet.
- **Opacity.** Nothing fades. Hierarchy is a colour stop, not transparency.
- **The locale switch.** Turbo Drive replaces the body without a transition;
  no View Transitions, no cross-fade. The reader asked for the other language,
  not for a show.
- **The sticky section label.** It is scroll position, not animation. No
  transition is attached to it.

**`prefers-reduced-motion: reduce`** sets `scroll-behavior: auto` and collapses
every transition duration to `0.01ms`. Since the only animated properties are
colours, a reduced-motion reader loses nothing but the 120ms ramp.

## 7. Depth strategy

**Hairline rules. One strategy, no second one.**

The page is one sheet of `--color-paper` from the first pixel to the last.
Structure is created by 1px horizontal rules in `--color-rule` and
`--color-rule-strong` and by the vertical rhythm in section 4. That is the
entire depth system.

Consequently, and these are constraints rather than preferences:

- **No shadows.** Not for cards, not for the header, not on hover.
- **No elevation.** Nothing is layered above anything else. The only
  `position: sticky` element does not gain a shadow or a background when it
  sticks, because there is nothing behind it to occlude.
- **No filled surfaces.** No panels, no tinted cards, no alternating row
  stripes. `--color-paper-select` is the only non-paper background in the
  stylesheet and it is reachable only by selecting text.
- **No borders as containers.** Rules divide; they do not enclose. The single
  exception is the substitution notice, which is a bordered box precisely
  because it is the one element that is *not* part of the document's argument
  and needs to read as an aside.
- **Tonal shift is for ink, not for surfaces.** The four ink stops in section 2
  do the work that a shadow ramp would do elsewhere: importance is darkness.

The failure mode of a rules-only page is that it reads as unfinished. The
counterweight is the vertical rhythm and the type scale, which is why sections
4 and 3 are as prescriptive as they are. Rules with sloppy spacing look like a
missing stylesheet; rules with disciplined spacing look printed.
