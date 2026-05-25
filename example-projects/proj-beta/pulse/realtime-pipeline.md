---
id: realtime-pipeline
project: realtime-pipeline
status: active
health: green
completion: 85
priority: p0
last_touched: 2026-05-22
paths:
  - src/streaming/**
  - infra/kafka/**
owner: claude-code-session-a91c
---

# Realtime Pipeline

## Last Stop
The Kafka → Snowflake landing path is live, processing ~120K events/min
with p99 < 800ms. Yesterday's load test showed no degradation at 3x peak.
What's left is observability polish and the runbook — code-complete on
the data path itself.

## Next Actions
- Wire the consumer-lag dashboard in Grafana, alert at 30s lag
- Write the runbook: failover, replay-from-offset, manual quarantine
- Get sign-off from on-call rotation before flipping the feature flag

## What Finishing Looks Like
- [x] Producer ships from app code (Wave 1)
- [x] Kafka cluster provisioned + IaC committed
- [x] Snowflake landing tables + Snowpipe configured
- [x] Consumer lag holds under load
- [ ] Grafana dashboard live with alerting
- [ ] Runbook reviewed by SRE
- [ ] Feature flag flipped to 100%

## Blockers
None.

## Notes
This is the kind of slice the finisher prompt is for — 85% done, three
small tasks separating it from shipped, and easy to leave at 85% while
something new and shinier appears on the priority list. Closeout pass
should take a day.
