---
id: ci-pipeline-hardening
project: ci-pipeline-hardening
status: done
completion: 100
priority: p2
last_touched: 2026-05-12
paths:
  - .github/workflows/**
  - scripts/ci/**
owner: human
---

# CI Pipeline Hardening

## Last Stop
Shipped. The flaky-test quarantine job has been catching ~3 quarantines
per week for two sprints with no false positives. Merged the last piece
(the deploy-gate on quarantine-rate > 5%) on May 10.

## Next Actions
None. Closing this out.

## What Finishing Looks Like
- [x] Flaky-test detection in CI
- [x] Quarantine list auto-PR'd
- [x] Weekly digest to #eng-platform
- [x] Deploy gate on quarantine-rate
- [x] Runbook for un-quarantining tests
- [x] Team training session

## Blockers
None.

## Notes — Retrospective
**What worked:** Starting with the detection layer before the gating
layer. The first two weeks of just measuring made the case for the gate.

**What I'd do differently:** Built the quarantine PR automation before
the detection. The first two weeks generated 19 candidate quarantines
and clearing them manually was slow.

**Cost:** 11 working days across 4 weeks.
