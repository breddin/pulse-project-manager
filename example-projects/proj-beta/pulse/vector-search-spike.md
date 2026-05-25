---
id: vector-search-spike
project: vector-search-spike
status: archived
completion: 40
priority: p3
last_touched: 2026-04-21
owner: human
---

# Vector Search Spike — Archived

## Last Stop
Explored adding pgvector to the search path over a two-week timebox. Got
working similarity queries against a 200K-row corpus, p95 around 80ms.
Then ran the numbers: our actual query patterns are 95% prefix and
fuzzy-match, which trigram indexes already handle at half the
infrastructure cost. The vector path was a solution to a problem we
mostly don't have.

Killed the spike on April 21. Branch preserved as `archive/vector-spike`.

## Next Actions
None. Archived.

If anyone picks this back up: the worked prototype is at
`spikes/vector-search/`, and the decision memo is in
`docs/decisions/2026-04-vector-search-no-go.md`. Re-read the memo first —
the conclusion was specific to our query mix, not to pgvector itself.

## What Finishing Looks Like
~~Would have been:~~
- [x] Working spike with similarity queries
- [x] Latency profile under load
- [ ] ~~Production cutover plan~~
- [ ] ~~Index-maintenance runbook~~

The spike succeeded in the only way that matters for a spike: it
answered the question. The answer was "no."

## Notes — Retrospective
**What worked:** Two-week timebox. We hit the decision point at exactly
the right time, with enough info to make it and not so much sunk cost
that "we've come this far" was tempting.

**What I'd do differently:** Should have profiled the query mix on day
one, not day eight. The 95/5 split was knowable from existing dashboards.

**Cost:** 9 working days.
