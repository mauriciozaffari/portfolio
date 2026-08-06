---
id: webstores-replatform
type: case_study
locale: en
status: published
confidentiality: public
updated: "2026-08-06"
title: Replatforming the core product without stopping it
organization: Looper Insights
period: 2024 - 2025
technologies:
  - Ruby on Rails
  - React
  - PostgreSQL
  - RSpec
---

## Problem

The core product had accumulated the usual decade of decisions: a React
frontend embedded inside the Rails monolith, so the two could not be deployed
or tested independently, and a large share of the codebase predating the
patterns the team had since settled on. Rewriting it wholesale was not an
option — it serves Disney, Warner Bros, Sony and NBCUniversal, and it earns
55% of company revenue.

## Approach

I led the replatforming as a sequence of shippable steps rather than a branch
that lived for six months. Over 261 commits across 844 files I rewrote more
than 20% of a roughly 244,000-line codebase, raising test coverage as I went
because the tests were what made the next step safe.

Separately I extracted the frontend — about 138,759 lines of React — out of the
monolith into its own repository, which let the frontend and backend be built,
tested and deployed on their own cadences.

## Outcome

Shipped incrementally, with test coverage moving from 72% to 80% across the
effort and continuing to climb afterwards. The product manager described the
result as a transformational release. The frontend extraction is what made
subsequent frontend work independent of backend release cycles.
