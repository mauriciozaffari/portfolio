---
id: release-engineering
type: case_study
locale: en
status: published
confidentiality: public
updated: "2026-10-04"
title: Sixty releases and one release button
organization: Looper Insights
period: 2022 - 2026
technologies:
  - Ruby on Rails
  - RSpec
  - Cypress
  - GitHub Actions
---

## Problem

Releases were manual and tribal: whoever knew the steps ran them, and the
steps lived in someone's head. The product serves Disney, Warner Bros, Sony
and NBCUniversal, so a bad release is not an internal inconvenience — it is a
client-visible incident. Two repositories became three as the frontend was
extracted, which tripled the ceremony.

## Approach

I ran the release train end to end across the three repositories: a biweekly
code freeze I instituted, QA gating, production deploys, hotfixes, and a
rollback plan for every release. Then I turned the parts a machine can do
into a machine doing them: an automated release workflow that builds, runs
the quality gates, deploys and health-checks. The gate is nine linters plus
the Cypress end-to-end suite wired into deploys and pull-request merges, so
the checks that used to depend on a person remembering are now the pipeline
refusing to continue. The test-plan and rollback-checklist templates I wrote
became the ones PM and QA reproduced for every release after.

For one stretch I was also release manager for a frontend codebase I did not
otherwise develop, because running the train is a skill apart from writing
the code it ships.

## Outcome

Sixty-plus releases and hotfixes shipped across four product naming eras
without the release process itself as the bottleneck. Releases paused while I
was on holiday — the strongest evidence I can offer both that the process
worked and that I had not yet finished making it replace me.