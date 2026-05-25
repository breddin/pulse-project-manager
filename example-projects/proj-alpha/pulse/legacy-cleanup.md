---
id: legacy-cleanup
project: legacy-cleanup
status: active
completion: 15
priority: p3
last_touched: 2026-04-10
paths:
  - src/legacy/**
owner: human
---

# Legacy Module Cleanup

## Last Stop
Started removing the `src/legacy/auth/` shims that were left in place
during the OAuth migration two quarters ago. Got the first three files
deleted and the test suite still green. Then got pulled onto search-api-v2.

## Next Actions
- Audit remaining `src/legacy/` for callers in current code
- Delete in dependency order, run full suite between each batch
- Update `ARCHITECTURE.md` to reflect the simpler module graph

## What Finishing Looks Like
- [ ] No imports from `src/legacy/` in non-test code
- [ ] `src/legacy/` directory deleted entirely
- [ ] Architecture doc updated

## Blockers
None — just deprioritized.

## Notes
This is the canonical example of a project that's "easy to come back to"
and therefore never comes back to. It'll keep going yellow until I either
spend the half-day on it or formally archive it. Worth a finish-or-kill
decision next planning cycle.
