---
title: "Deployment - Spec"
type: "feature-spec"
status: "in-progress"
created: "2026-08-06"
updated: "2026-08-06"
origin: "operational need (site must be publicly reachable before metadata and later features)"
---

# Deployment

- Status: in-progress
- Created: 2026-08-06
- Updated: 2026-08-06
- Origin: operational need (site must be publicly reachable before metadata and later features)

## Problem / motivation

Deployment sits early, not last, for two reasons.

[site-metadata](../site-metadata/SPEC.md) needs a real origin: canonical URLs,
absolute share-image URLs, and sitemap entries. Producing those before the site
is reachable means writing placeholders and revisiting them.

Deploying as soon as the page renders real content also means every later
feature ships continuously instead of arriving as one big-bang release.

The domain is already owned, which removes the highest-variance item.

## Desired behavior

- The site is reachable over HTTPS at the canonical origin. HTTP redirects to
  HTTPS; HSTS is set.
- **No database service exists in the production topology.** The deployed
  artifact is a single stateless container.
- One documented deploy command, repeatable. A rollback path is documented
  **and exercised once** — an untested rollback is not a rollback.
- Secrets come from the environment. None are committed.
- Security headers: a CSP that actually blocks inline script (or a documented,
  justified exception), `X-Content-Type-Options`, `Referrer-Policy`,
  `Permissions-Policy`.
- CI runs the full gate from [app-foundation](../app-foundation/SPEC.md) —
  specs, linters, and the content-safety scanner from
  [curated-content](../curated-content/SPEC.md) — and **blocks deploy on
  failure**.
- The deployed artifact has no mount, no credential, and no network path to any
  private source material. This is enforced structurally by what the artifact
  does not include, not by convention.

## Constraints

- The repository is public; the deploy pipeline configuration is public with
  it. It must be readable without disclosing anything.
- Single production environment. No staging.
- Deployment must not become the reason a database gets added back.

## Out of scope

- Error monitoring and APM — revisit when [chatbot](../chatbot/SPEC.md)
  introduces an external dependency worth monitoring.
- CDN and multi-region topology. One page, one origin.
- Zero-downtime orchestration beyond what the chosen host provides for free.

## Canonical origin

`https://zaffari.casa` — owned. Every absolute URL in
[site-metadata](../site-metadata/SPEC.md), and the `mauricio@zaffari.casa`
forwarding alias on the approved contact allowlist, derive from this origin.
## Decisions

- **Kamal 2 to a single small VPS.** Rails 8's own deployment path, no vendor
  lock, and it matches the one-stateless-container topology this project's
  no-database rule was chosen to produce. The trade accepted: the box is ours
  to patch and monitor.

## Pending TODOs

The configuration exists and the image is built and verified locally; see
[IMPLEMENTATION.md](IMPLEMENTATION.md). Nothing has been deployed, because no
server exists yet. What remains:

- [ ] Decide whether deploys are triggered on merge to the default branch or
      manually. Deliberately still open: the CI workflow runs the gate and
      stops there.
- [ ] Provision the VPS and supply the four values the configuration reads from
      the environment. The full list is in IMPLEMENTATION.md.
- [ ] Point `zaffari.casa` at the host so kamal-proxy can complete the Let's
      Encrypt challenge, and decide whether `www.zaffari.casa` is served,
      redirected, or left unresolved. It is currently unserved.
- [ ] Run `kamal setup` once, then confirm the desired behavior over HTTPS.
- [ ] **Exercise the rollback.** This SPEC requires it and it cannot be
      satisfied without a running host, so it is the one acceptance criterion
      the local work could not meet. Deploy twice, run `kamal rollback`, and
      confirm the previous version serves.
- [ ] Decide whether to enable `config.hosts` for DNS-rebinding protection
      after the first successful deploy. It is off now on purpose — enabling it
      blind is the classic way to make a first deploy return 403 on every
      request.
- [ ] Revisit HSTS preloading once the site has been live on HTTPS long enough
      to trust. `preload` is off; the header is otherwise complete.
