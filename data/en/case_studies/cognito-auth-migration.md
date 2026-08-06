---
id: cognito-auth-migration
type: case_study
locale: en
status: published
confidentiality: public
updated: "2026-08-06"
title: Moving every user onto managed authentication
organization: Looper Insights
period: 2021 - 2022
technologies:
  - Ruby on Rails
  - AWS Cognito
  - OIDC
  - Redis
---

## Problem

Authentication was homegrown, and enterprise clients were starting to ask for
things homegrown auth is bad at: federated identity, their own single sign-on,
and token handling we could point at during a security review.

## Approach

I led the company-wide migration to AWS Cognito over roughly two months:
OIDC integration, bearer-token verification, refresh handling, and sessions
kept in Redis with database persistence so a restart did not sign everyone out.

The part that takes the care is not the new system, it is the transition. Every
existing user had to keep working throughout, which meant running both paths
against real traffic before the legacy code could be deleted — and then
actually deleting it, rather than leaving a dead branch to confuse the next
reader.

## Outcome

One managed identity provider for the whole platform, with client SSO becoming
a configuration exercise rather than an engineering project. I later built
client-facing pages authenticated through a studio's own single sign-on on top
of it.
