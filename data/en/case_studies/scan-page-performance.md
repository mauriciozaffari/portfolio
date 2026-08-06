---
id: scan-page-performance
type: case_study
locale: en
status: published
confidentiality: public
updated: "2026-08-06"
title: A page that took four minutes, and the five reasons why
organization: Looper Insights
period: "2026"
technologies:
  - Ruby on Rails
  - PostgreSQL
  - ActiveRecord
---

## Problem

The main scan page took over four minutes to load. For one client it was worse:
ten to fifteen minutes, which is long enough that people stop using the feature
and ask someone else to send them a spreadsheet instead.

## Approach

There was no single cause, which is the interesting part. Five separate things
compounded: a `COUNT DISTINCT` fanning out over a join, a scope that scanned
the whole table rather than the current request's slice, a sequential scan over
16.7 million rows, a join against a table of roughly 1.5 billion rows, and a
missing cache on an expensive grouped aggregate.

I fixed them one at a time and measured after each, because compounding causes
mask each other — fix the second-worst first and the improvement looks
negligible, which tempts you into concluding it was not the problem. Two of the
five needed denormalisation rather than query tuning: a boolean carried onto
the row that needed it, so the billion-row join disappeared, and a cached JSONB
aggregate refreshed by a dedicated worker instead of computed per request.

For the worst-affected client the fix was narrower and shipped the same day: an
existence check that had been doing linear work became an O(1) lookup.

## Outcome

Four minutes to under a second. The client-specific path went from ten to
fifteen minutes to effectively instant, delivered as a same-day hotfix. A
related filter on the same page went from 322 seconds cold to 25.5 seconds by
anchoring an unscoped subquery so it could use an index that already existed.

I later made the whole class of regression fail loudly, enabling
`strict_loading` across the test suite so an accidental N+1 breaks CI instead
of quietly reaching production.
