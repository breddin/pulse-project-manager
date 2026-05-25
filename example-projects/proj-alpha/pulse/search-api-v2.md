---
id: search-api-v2
project: search-api-v2
status: active
health: green
completion: 55
priority: p1
last_touched: 2026-05-23
paths:
  - src/search/**
  - src/api/search_handler.go
  - tests/search/**
owner: claude-code-session-7f3a
---

# Search API v2

## Last Stop
Indexer rewrite is in, 12/19 tests passing. The seven failures are all in
the faceted-search path — looks like the new tokenizer is splitting
hyphenated terms differently than v1. Have a hypothesis but haven't
validated: I think the `SplitGraphemes` call needs a custom rule for
`\w-\w` runs.

Last commit: `feat(search): wire v2 indexer into the query path` on
`feature/search-api-v2`.

## Next Actions
- Reproduce one faceted-search failure in isolation:
  `go test ./src/search -run TestFacetedHyphenated -v`
- Patch the tokenizer rule, re-run the seven failures
- If green: open the draft PR and request review from @leila
- If red: escalate to a deeper review (subtle tokenizer behavior)

## What Finishing Looks Like
- [x] v2 indexer wired into query path behind feature flag
- [x] Migration shipped to staging
- [ ] All 19 search tests passing
- [ ] p95 latency at or below v1 under the standard load profile
- [ ] Feature flag flipped to 10% in prod with monitoring dashboard live
- [ ] Rollback procedure documented in `docs/runbooks/search-v2-rollback.md`

## Blockers
None active.

## Notes
Tokenizer behavior change is a breaking change for anyone querying through
the raw API — but that's nobody in practice. Worth a heads-up in the
changelog regardless.
