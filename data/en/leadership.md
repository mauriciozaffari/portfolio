---
id: leadership
type: leadership
locale: en
status: published
confidentiality: public
updated: "2026-08-06"
title: How I work
---

I lead a small engineering team and I never stopped writing the code. I am
still the top contributor to the codebase I lead, and that combination is
deliberate rather than a failure to delegate: I review code I could have
written myself, and I do not hand down an architecture I am not willing to
build. The leverage runs both ways — through the decisions other people
inherit, and through the work I ship.

**I find the cause before I write the fix.** A slow page usually has more than
one reason for being slow, and the first one you find is rarely the expensive
one. I profile, I read the query plan, and I fix the actual thing. One page I
inherited took over four minutes to load for five compounding reasons; fixing
them one at a time, with a measurement after each, got it under a second.
Guessing would have fixed one of the five.

**A regression test that passes before the fix is worthless.** I have rejected
my own tests for this. One seeded a blank value through an ActiveRecord write
path that silently coerced it to `nil`, so the test never exercised the bug it
claimed to cover. That is false confidence, and it is worse than no test,
because it stops anyone from looking again.

**Correctness belongs in the database when it can.** Application-level
uniqueness checks lose races. If a duplicate must never exist, I would rather
deduplicate once and add the unique index, and let the system fail closed
afterwards.

**Code review is where standards actually propagate.** I comment on test rigour
and architectural shape, not formatting — a linter handles formatting. A
principle I keep returning to: a controller with no matching model is a smell,
because a state change on a record is almost always that record's `update`, not
a new controller.

**Releases need a rollback plan you have actually thought about.** I own release
checklists: migration reversibility, queue drain, a recorded last-known-good
reference. When our release tooling hit a merge pattern that made rebasing
unsafe, I fixed the tool and wrote down why, so the next person meets a
documented failure mode instead of a mystery.

**I write things down.** Architecture decisions, domain notes on the subsystems
that surprise people, and the AI agent standards our organisation now works to.
A decision that lives only in a Slack thread has to be re-litigated every time
someone new asks.
