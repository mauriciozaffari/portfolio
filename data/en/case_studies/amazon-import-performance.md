---
id: amazon-import-performance
type: case_study
locale: en
status: published
confidentiality: public
updated: "2026-08-06"
title: Cutting a 46-minute import to 16 minutes
organization: Looper Insights
period: "2026"
technologies:
  - Ruby on Rails
  - PostgreSQL
  - Redis
---

## Problem

Amazon US merchandising imports took around 46 minutes. Client deliveries
queued behind them, so a single slow import delayed the reports people were
actually waiting for. The volume was the hard part: roughly 273,000 title spots
per scan, against 12.5 to 13 million titles processed weekly.

## Approach

The bottleneck was not the fetching, it was the write path — every row was
paying for durability and index maintenance it did not need while still in
flight. I moved the intake into UNLOGGED PostgreSQL staging tables, so
in-progress rows skip write-ahead logging entirely, then promoted them into the
real tables once complete. Alongside that I parallelised the fetch stage and
streamed results through Redis instead of accumulating them in process memory.

The staging tables are safe here specifically because the data is
reconstructible: an UNLOGGED table does not survive a crash, and that is an
acceptable trade when the recovery action is to re-run the import.

## Outcome

46 minutes down to about 16 — a 65% reduction, confirmed independently by a
colleague measuring the same pipeline. Client deliveries stopped queueing
behind the import window.
