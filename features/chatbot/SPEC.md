---
title: "Chatbot - Spec"
type: "feature-spec"
status: "spec'd"
created: "2026-08-06"
updated: "2026-08-06"
origin: "user request (chat bot that can answer questions about me — explicitly the last feature)"
---

# Chatbot

- Status: spec'd
- Created: 2026-08-06
- Updated: 2026-08-06
- Origin: user request (chat bot that can answer questions about me — explicitly the last feature)

## Problem / motivation

A visitor with a specific question — "has he led a Postgres performance
rewrite?", "how big were the teams?" — currently has to scan the whole page.
A grounded assistant answers directly, and for someone whose recent work
includes production LLM integrations, it doubles as the most relevant work
sample on the site.

It is deliberately last. It is the only feature that adds an external
dependency, a running cost, an abuse surface, and a class of failure where the
system invents biography. None of that is worth carrying while the corpus and
the page are still moving.

The corpus question is already settled by
[curated-content](../curated-content/SPEC.md): there is exactly one published
record set, and the chatbot reads it. A second ingestion path is how a chatbot
ends up disclosing what the page correctly withholds.

## Desired behavior

- Ships behind a flag, **default off**. The site passes every check with the
  chatbot disabled, and a model-API outage never affects the page.
- Grounded strictly in the same `published` + `public` records the page
  renders. One corpus, one ingestion path, no separate index of private
  material.
- Every answer cites the source record it drew from.
- Questions the corpus does not support produce an **explicit refusal**, never
  a plausible guess. Inventing employment history is the worst possible failure
  for this feature.
- Answers in the reader's locale (`en` / `pt-BR`).
- Adversarial specs cover: prompt injection via user input, requests for direct
  contact details, requests for compensation figures, requests for the excluded
  private categories, and attempts to extract the system instructions.
- Per-IP and global rate limits. Abuse returns a clean error, never a stack
  trace.
- A cost ceiling with a hard cap or kill switch.
- No conversation persistence unless a retention decision is explicitly
  recorded in this spec first.

## Constraints

- **No vector database and no embeddings infrastructure.** The corpus is one
  person's professional history — small enough to pass directly as grounded
  context. This spec records the corpus size that would justify revisiting.
- Retrieved records are treated as untrusted input in the prompt, delimited and
  labelled as reference material rather than instructions.
- The chatbot has no filesystem path to the private source material and no
  access to `draft` or `restricted` records.
- Citations reference published records and their public `source_url` only.
- This feature does not begin until the corpus and the landing page are stable.

## Out of scope

- Multi-turn memory across sessions.
- Answering questions unrelated to the author's professional background.
- Voice, file upload, or any non-text modality.
- Lead capture or routing conversations to an inbox.

## Decisions

- **Provider: Google Gemini.** Already in production use in Inscripto, so one
  fewer vendor and a familiar SDK.
- **Cost ceiling: USD 20 per month, enforced as a hard cap with a kill
  switch**, not an alert. An alert on a public endpoint tells you after the
  money is gone.

## Pending TODOs
- [ ] Decide whether conversations are logged at all, and if so under what
      retention and what disclosure to the visitor.
- [ ] Record the corpus-size threshold that would justify revisiting the
      no-vector-database decision.
- [ ] Decide the UI surface (inline section vs dialog) once the landing page
      design direction exists.
