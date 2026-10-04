---
id: ai-delivery
type: case_study
locale: en
status: published
confidentiality: public
updated: "2026-10-04"
title: Shipping the first AI features into a client platform
organization: Looper Insights
period: "2026"
technologies:
  - Ruby on Rails
  - LLM integrations
  - ClickHouse
---

## Problem

The company wanted AI features in the client-facing product, and had six
engineers it trusted to figure out where AI actually pays for itself. Inside
engineering, AI coding assistants were already changing how people worked,
with no shared standards: every engineer invented their own workflow.

## Approach

I was one of the six in the company's AI pilot, and I took the two halves of
the problem — how we build with AI, and what we ship with AI.

For the first half, I authored the team's AGENTS.md workflow standard and
shared it across the organisation, so assistant-driven development went from
personal habits to a documented, reviewable way of working. I published model
evaluations that informed the organisation's tool choice.

For the second half, I was delivery lead for the AI initiative on the core
product: client-facing AI pages including one authenticated through a studio's
own single sign-on, and the multi-tenant data-security architecture that lets
an LLM chat feature answer from one client's data without another client's
data ever being in reach. That isolation was designed before the feature was
green-lit, not retrofitted after.

## Outcome

Standards adopted organisation-wide; AI pages live in front of clients whose
names everyone recognises; a chat architecture whose security model was
reviewed before it shipped.