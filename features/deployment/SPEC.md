---
title: "Deployment - Spec"
type: "feature-spec"
status: "in-progress"
created: "2026-08-06"
updated: "2026-10-03"
origin: "operational need (site must be publicly reachable before metadata and later features)"
---

# Deployment

- Status: in-progress
- Created: 2026-08-06
- Updated: 2026-10-03
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

`https://mauricio.zaffari.casa` — owned. Every absolute URL in
[site-metadata](../site-metadata/SPEC.md) and
[agent-discovery](../agent-discovery/SPEC.md), and the `mauricio@zaffari.casa`
forwarding alias on the approved contact allowlist, derive from this origin.

The apex `zaffari.casa` is a separate concern: it currently answers with a
different, `noindex` application, so it must either be repointed at this service
or left alone. It must not be claimed as this site's origin until it does.

## Decisions

- **Kamal 2 to a single small VPS, as the target that was configured but not
  used.** Rails 8's own deployment path, no vendor lock, and it matches the
  one-stateless-container topology this project's no-database rule was chosen to
  produce. `config/deploy.yml` is complete and has never been run.
- **In practice the site is a Docker container on the house host.** It is built
  where it runs (`le-mans`, `192.168.1.253`), addressed by the wildcard
  certificate that host already serves, and deployed by `bin/deploy` with a
  health-gated swap and a one-command rollback. The trade accepted: no registry
  round trip and an instant rollback, in exchange for a deploy that only works
  from a machine that can reach that host. See
  [IMPLEMENTATION.md](IMPLEMENTATION.md) for the topology and the runbook.

## Pending TODOs

The site is live at `https://mauricio.zaffari.casa` from one stateless container;
see [IMPLEMENTATION.md](IMPLEMENTATION.md) for how it gets there. What remains:

- [ ] **Exercise the rollback.** This SPEC requires it and it is the one
      acceptance criterion still unmet. `bin/deploy --rollback` exists and is
      exercised by construction on every deploy, but it has never been run on
      purpose with the site up. Deploy twice, roll back, confirm the previous
      version serves.
- [ ] Decide whether deploys are triggered on merge to the default branch or
      manually. Deliberately still open: the CI workflow runs the gate and
      stops there.
- [ ] Decide what the apex `zaffari.casa` does. It resolves to the same host and
      serves a different, `noindex` application, so nothing in this repository
      points at it. Repointing it at this service, or 301-ing it to the
      canonical host, is a separate decision.
- [ ] Decide whether to retire or pursue the Kamal path. It is the only route to
      a host that is not on the LAN, and it is dead weight until that is wanted.
- [ ] Decide whether to enable `config.hosts` for DNS-rebinding protection. It
      is off, as the Rails generator leaves it. The live host serves one
      vhost in front of the container, so this is defence in depth rather than
      a gap; enabling it blind is the classic way to make every request return
      403, including the proxy's health check.
- [ ] Revisit HSTS preloading once the site has been live on HTTPS long enough
      to trust. `preload` is off; the header is otherwise complete.
