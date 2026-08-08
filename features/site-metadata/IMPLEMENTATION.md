---
title: "Site Metadata - Implementation"
type: "feature-implementation"
updated: "2026-08-08"
commit: "8d20fce"
---

# Site Metadata — implementation

- Updated: 2026-08-08
- Code as of: repository commit `8d20fce`, the commit this feature landed in
- Spec: [SPEC.md](SPEC.md) · Visual language: [DESIGN.md](../../DESIGN.md)

Two `<head>` blocks, two crawler documents, and three PNGs. None of it is
visible in a browser window, which is the whole reason it needed specs: a
`telephone` added to the JSON-LD would survive every review that consists of
looking at the page.

Every value comes out of the `site_profile` record through the loader that
already serves the page. Nothing here restates content — this feature selects
from records and formats what it selected.

## Entry points / flow

```mermaid
flowchart TD
  ROOT["GET /"] --> LC
  PTBR["GET /pt-BR"] --> LC
  LC["LandingController#show"] --> PAGE["LandingPage"]
  PAGE --> SM["SiteMetadata<br/>canonical · hreflang · OG · Person"]
  SM --> HEAD["site_metadata/_head<br/>via content_for :head"]

  ROBOTS["GET /robots.txt"] --> SMC
  MAP["GET /sitemap.xml"] --> SMC
  SMC["SiteMetadataController"] --> SITEMAP["Sitemap<br/>lastmod from record `updated`"]
  SITEMAP --> PAGE2["LandingPage, once per locale"]
  PAGE2 --> REPO
  PAGE --> REPO["Content.repository<br/>site_profile"]

  ORIGIN["SiteMetadata::ORIGIN<br/>https://zaffari.casa"] --> SM
  ORIGIN --> SITEMAP
  ROUTES["config/routes.rb<br/>url_helpers"] --> SM
```

`SiteMetadata::ORIGIN` and the routing table are the only two sources of a URL
in this feature. `LandingHelper#locale_path` now delegates to
`SiteMetadata.path_for`, so the language switcher, the canonical URL, the
`hreflang` set and the sitemap cannot disagree about where a locale lives.

## Key files

| Path | Role |
|---|---|
| [app/models/site_metadata.rb](../../app/models/site_metadata.rb) | The fixed origin, both locale URLs, the reciprocal alternates, the description, and the `Person` graph. |
| [app/models/sitemap.rb](../../app/models/sitemap.rb) | One entry per locale, each dated from the records that locale actually renders. |
| [app/controllers/site_metadata_controller.rb](../../app/controllers/site_metadata_controller.rb) | Two actions, no layout, explicit formats and content types. |
| [app/views/site_metadata/_head.html.erb](../../app/views/site_metadata/_head.html.erb) | Canonical, `hreflang`, Open Graph, Twitter, JSON-LD. Rendered into the layout's existing `yield :head`. |
| `app/views/site_metadata/robots.text.erb` | The crawler policy, and the paragraph explaining that it is one. |
| `app/views/site_metadata/sitemap.xml.erb` | `urlset` with `xhtml:link` alternate annotations. |
| [config/routes.rb](../../config/routes.rb) | `robots.txt` and `sitemap.xml`, both `format: false`. |
| [lib/tasks/site.rake](../../lib/tasks/site.rake) | `bin/rails site:images`. Build-time only; rebuilds `icon.png` and `og-image.png`. |
| `public/icon.svg`, `public/icon.png`, `public/og-image.png` | The mark and the share card. Committed artifacts. |
| [app/controllers/application_controller.rb](../../app/controllers/application_controller.rb), [app/controllers/landing_controller.rb](../../app/controllers/landing_controller.rb) | `allow_browser` moved from the base class to the page. See [Decisions](#decisions). |
| [config/locales/en.yml](../../config/locales/en.yml), [config/locales/pt-BR.yml](../../config/locales/pt-BR.yml) | One new key, `metadata.image_alt`. Chrome, translated, wrapped around record values. |

Deleted: `public/robots.txt`, the Rails generator's one-line stub. It sat in
front of the route — Rack's static file server answers before the router — so
leaving it there would have silently served an empty policy.

## Configuration

None. No environment variable, no initializer, no new gem. The origin is a
constant, deliberately.

## Decisions

**The canonical origin is a constant, not `request.base_url`.** A canonical URL
built from the request reflects whatever host answered — a staging name, a bare
IP, the proxy's internal hostname — and a canonical that varies by responder is
not a canonical. `SiteMetadata::ORIGIN` and `proxy.host` in
[config/deploy.yml](../../config/deploy.yml) are the only two places the origin
is written down, and they are changed together.

**AI and LLM crawlers are allowed, and `robots.txt` says so in prose.** This was
the SPEC's first open question. The site exists to be found, and a growing share
of the people it is written for will meet it through an assistant answering
someone else's question rather than through a browser. An assistant that cannot
read this page answers from something worse — a stale profile, a scraped
aggregator, a guess. The file therefore names GPTBot, ClaudeBot,
Google-Extended, PerplexityBot, CCBot and Applebot-Extended in a comment and
states that their coverage by the wildcard **is the policy**, because a decision
nobody wrote down is indistinguishable from an oversight six months later. A
spec asserts the comment is still there.

The only `Disallow` is `/up`, the container health check, which renders no
content and exists for the proxy.

**The share image is a static PNG, generated once by a committed script.** This
was the SPEC's second open question. What is actually installed here is
ImageMagick 6.9 with freetype and fontconfig; there is no libvips, and a Node or
headless-Chrome renderer is excluded from the runtime image by
[app-foundation](../app-foundation/SPEC.md) and
[deployment](../deployment/SPEC.md). Generating the card per request would have
added a dependency to the image to serve a file a scraper fetches once and
caches for months. So `bin/rails site:images` renders it at authoring time and
the PNG is committed. Verified deterministic: two consecutive runs produce
byte-identical files.

The card is DESIGN.md's own palette and two of the faces DESIGN.md already names
in its stacks (Noto Sans, DejaVu Sans Mono), so it matches what a Linux reader
sees rather than introducing a third face nobody chose. Warm paper, two
hairlines, a letter-spaced mono label, the name and headline from the record,
and one 120px accent segment sitting on the lower rule — the same at-rest
instance of the second ink that marks the current locale in the switcher. No
gradient, no shadow, no radius, consistent with [DESIGN.md](../../DESIGN.md) §7.

The task **aborts** if the name or the headline renders wider than the card's
measure. ImageMagick draws past the canvas edge without complaining, which would
ship a clipped name and no warning.

**The Rails generator icons were the site's icons, and they are gone.** Both
were a plain `#FF0000` circle — a colour that is not in the palette at all.
`public/icon.svg` is now a geometric two-ink mark: a paper field, an ink `Z`
drawn as a path rather than as a `<text>` element so it does not depend on a
font, and the accent rule beneath it. `icon.png` is rendered from that SVG by
the same rake task, so the two cannot drift. Checked at 16px and 32px by
downscaling and looking: the letterform holds and the accent rule survives as a
visible bar.

**JSON-LD is one `<script type="application/ld+json">`, and it does not violate
`script-src 'none'`.** HTML's *prepare the script element* algorithm returns
before the CSP check when the type is not a JavaScript MIME type, so the block
is data and is never executed. This was **verified in Chromium against the
running application**, not reasoned about: zero `securitypolicyviolation`
events, zero console errors, one `<script>` element, zero executable scripts.
[spec/requests/security_headers_spec.rb](../../spec/requests/security_headers_spec.rb)
was changed from counting `<script>` elements to asserting their type, which
still fails on an executable script, inline or sourced.

**`sameAs` is filtered by URL scheme, not by label.** The contact allowlist's
fourth entry is a `mailto:`, and schema.org's field for one is `email` — which
the publication policy forbids. `sameAs` takes the links whose URL begins
`http://` or `https://`, so the address is excluded structurally. A fifth link
added to the record is included or excluded by the same rule, with no name to
keep in sync and nothing to remember.

**The `Person` graph has seven keys and no more.** `@context`, `@type`, `@id`,
`name`, `jobTitle`, `url`, `sameAs`. `@id` is the origin plus `#person` and is
identical in both locales, so the two pages describe one person rather than two
who happen to share a name. Deliberately absent: `profile:first_name` and
`profile:last_name` on the Open Graph side and any name splitting anywhere —
deciding which word is the family name is a guess, and this project does not
publish guesses about a person as structured data. Also absent: `image`. The
card is typographic, not a photograph, and offering it as a `Person.image` would
be a small lie.

No `twitter:site` or `twitter:creator`: both take an `@handle`, and no handle is
on the allowlist.

**The description is whole sentences from the profile body, not a front-matter
field.** `summary` is a forbidden front-matter key in
[curated-content](../curated-content/SPEC.md) precisely so a description cannot
have two homes. So this reads the *rendered, sanitized* body — a link added to
the record later becomes words here rather than syntax — and takes whole
sentences up to 250 characters. Consumers truncate; a card that ends mid-word
reads as broken markup. The budget is 250 rather than the ~160 a search result
shows because stopping at one sentence would drop the named clients, which is
the strongest thing the paragraph says. The profile currently lands at 246.

**`lastmod` comes from records, through `LandingPage`.** Not from `Time.now`,
which would mark both URLs as modified on every deploy and teach a crawler to
ignore the field. Going through `LandingPage` rather than the repository means
"the content behind this URL" is the same set of records here as in the browser,
including the locale fallback — so a page rendered partly from borrowed records
is dated from what it actually shows rather than from nothing at all. Since
`589ec86` neither locale borrows anything, and the fallback is proved by
fixtures instead.

**`format: false` on both routes.** It drops the `(.:format)` segment, so the
dot in each name is a literal. `/robots.txt.json` is a 404, and `sitemap_path`
cannot generate `/sitemap.xml.xml`.

**`allow_browser` moved off `ApplicationController`.** This was a live defect
found by testing rather than by reading: with the gate on the base class,
`/robots.txt` and `/sitemap.xml` returned **406** to any User-Agent Rails read
as an old browser. Several crawlers send exactly that to look innocuous, and a
crawler told this site has no sitemap is the one failure the feature cannot
afford. The gate protects a rendering contract, and neither document has one, so
it now lives on `LandingController`. Measured before and after; specs hold both
halves — the crawler documents answer 200 to a Chrome 49 UA and the page still
answers 406.

## Verified non-functionals

Measured, not asserted from theory.

**Transfer.** The metadata block is **2,496 bytes uncompressed on `/`** and
2,513 on `/pt-BR` — **396 and 423 bytes gzipped**, measured by rendering each
page with and without it. Against that, `icon.png` fell from **4,166 to 1,902
bytes** because the generator's artwork was replaced by a four-shape SVG. A
first-time visitor therefore transfers **less** than before this feature.
`robots.txt` is 1,114 bytes and `sitemap.xml` is 898.

`og-image.png` is 27,849 bytes and is fetched by scrapers only — never by the
page, which still loads exactly four resources: document, stylesheet,
`icon.svg`, `icon.png`. Zero third-party origins, confirmed from the browser's
own network log.

**Content Security Policy.** Zero violations in Chromium with
`script-src 'none'` in force. One `<script>` element, zero executable scripts.

**Crawler documents.** `GET /robots.txt` → 200 `text/plain`, `GET /sitemap.xml`
→ 200 `application/xml`, both carrying the full hardened header set including
`default-src 'none'`. The sitemap parses under `Nokogiri::XML(&:strict)` with no
errors. Googlebot, bingbot, GPTBot and ClaudeBot user agents all get 200 from
all three URLs.

**Quality gate.** `bin/ci` exits 0: RuboCop (53 files), `herb analyze` (14
files), `content:validate`, `content:scan`, `content:paths`, `importmap audit`,
and the RSpec suite. The example count is deliberately not recorded here — it
moves with every commit, and `bin/rspec` reports the current one.

## Testing

| Spec | What it proves |
|---|---|
| [spec/requests/site_metadata_spec.rb](../../spec/requests/site_metadata_spec.rb) | Shared examples over both locales: exactly one absolute canonical built from the fixed origin; the same three reciprocal alternates including `x-default` on both pages; `og:title` equal to the document's own `<title>`; `og:description` equal to the meta description; `og:locale` and `og:locale:alternate` correct per locale; a share image that **exists on disk at the width and height the tags claim**, read out of the PNG's IHDR; the `Person` graph built from the record; **the contact assertion** below; no `mailto:` or `tel:` anywhere in the head and the safety scanner clean over it; and no absolute URL in the whole document outside the canonical origin, the schema vocabulary, and the URLs the records themselves publish. |
| `spec/requests/site_metadata_spec.rb`, "carries no contact field outside the four-entry allowlist" | The graph's key set is exactly the seven expected, **and** nineteen schema.org contact and identity properties — `telephone`, `email`, `faxNumber`, `contactPoint`, `address` and its five components, `birthDate`, `nationality`, `taxID`, `vatID` and friends — are absent from the serialized JSON. Both halves matter: the key-set check catches a replacement, the field list catches an addition nested inside a value. |
| `spec/requests/site_metadata_spec.rb`, "GET /robots.txt" | Served by the application as `text/plain`; `User-agent: *` with `Allow: /`; **`/up` is the only `Disallow` in the file**, so a future edit cannot quietly exclude a crawler; the AI decision comment is still present; and the `Sitemap:` line is the absolute URL. |
| `spec/requests/site_metadata_spec.rb`, "GET /sitemap.xml" | Strict XML parse; both locales at their canonical URLs in schema order; `lastmod` equal to the newest `updated` in the renderable corpus, one per locale; the `xhtml:link` annotations matching the pages' own alternates; scanner clean. |
| `spec/requests/site_metadata_spec.rb`, "a crawler that looks like an old browser" | The `allow_browser` defect, locked from both sides: a Chrome 49 UA gets 200 from `robots.txt` and `sitemap.xml`, still gets 406 from the page, and the crawler documents still carry the hardened headers. Verified to fail — putting `allow_browser` back on `ApplicationController` fails the first example with `expected 200, got 406`. |
| [spec/models/site_metadata_spec.rb](../../spec/models/site_metadata_spec.rb) | The origin is fixed; both locale paths come from the routing table; the alternates cover every locale the schema admits and so does `OPEN_GRAPH_LOCALES`, so adding a third locale fails here rather than shipping unadvertised; the description takes whole sentences, keeps the first one even when it alone overruns, and renders a Markdown link as words; the `Person` graph is exact; a `mailto:` in the links stays out of `sameAs`; and **a `</script>` hidden in a record value comes back escaped but intact**. |
| [spec/models/sitemap_spec.rb](../../spec/models/sitemap_spec.rb) | `lastmod` is the newest `updated` among renderable records, is not today's date, ignores a draft dated in the future, and dates a fallback locale from the records it actually shows. |
| [spec/requests/rendered_html_safety_spec.rb](../../spec/requests/rendered_html_safety_spec.rb) | Unchanged, and now sweeping the two new routes because it is driven by the routing table. It skips non-HTML responses, so `robots.txt` and `sitemap.xml` are scanned explicitly in the spec above instead. |
| [spec/requests/security_headers_spec.rb](../../spec/requests/security_headers_spec.rb), [spec/requests/landing_spec.rb](../../spec/requests/landing_spec.rb) | Two assertions narrowed, each with the reason recorded at the point of change: `<script>` is asserted by type rather than counted, and the subresource check now names the rels that actually fetch, because `canonical` and `alternate` must be absolute and cost no request. The coverage that moved is picked up by the document-wide origin allowlist above. |

## Known limitations / pitfalls

- **`bin/rails site:images` needs ImageMagick and two fonts that CI does not
  have.** It is an authoring tool, not a build step: nothing in `bin/ci` runs
  it, and the container has no ImageMagick at all. The consequence is that the
  PNGs can go stale — edit `site_profile`'s `name` or `headline` and the card
  still shows the old one until someone reruns the task. Nothing detects that
  today.
- **`ORIGIN` is duplicated in `config/deploy.yml`.** Two files, one value.
  `deploy.yml` cannot read a Ruby constant and the application should not parse
  a deploy file at boot, so the link is the comment on the constant. Change both.
- **`og:locale` says `en_US`.** The format has no way to spell "English, no
  territory in particular", and `en_US` is its own default. It is the one value
  in this feature that is not derived from anything.
- **The share card is a Linux rendering of the design.** DESIGN.md's font stacks
  are system stacks; the card is baked with Noto Sans and DejaVu Sans Mono, so a
  reader on macOS sees a card in slightly different faces from the page they
  click through to. Freezing one pair is the price of not shipping a web font.
- **The share card is English on both locales.** The description and the
  `Person` graph became Portuguese on `/pt-BR` when the pt-BR `site_profile`
  landed in `dfdab9f`, but `bin/rails site:images` renders `og-image.png` from
  `Content::Schema::DEFAULT_LOCALE` — one baked PNG serving both pages. A
  Portuguese card means a second file, a second `og:image` per locale, and a
  second thing to keep from going stale, which is not obviously worth it for an
  unfurl.
- **`lastmod` is a whole day.** `updated` is a date in the front matter, so two
  edits on one day are indistinguishable. That is the record schema's
  granularity, not this feature's, and a finer one would be invented precision.
- **Nothing validates the card against a real unfurler.** The SPEC asks for the
  card to be validated *by rendering it*, and the image itself was rendered and
  looked at — but LinkedIn's and Slack's scrapers cannot reach `localhost`, so
  the end-to-end unfurl is unproven until the site is deployed. Re-check it
  through each platform's own debugger after the first deploy.
- **`public/` is served by Rack before the router.** Dropping a `robots.txt` or
  a `sitemap.xml` back into `public/` silently shadows these routes and no spec
  fails, because the request spec would still see a 200.
