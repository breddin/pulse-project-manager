---
id: schema-migration-tool
project: schema-migration-tool
status: idea
completion: 0
priority: p3
last_touched: 2026-05-21
owner: human
---

# Schema Migration Tool — Idea

## Last Stop
Caught myself writing the same ad-hoc psql migration script for the third
time this quarter. Each one was 30-40 lines of "rename column, backfill,
drop old." Worth investing two days to build a small declarative migrator
instead of hand-rolling every time.

## Next Actions
- Spike: write the smallest possible YAML→SQL transformer for a single
  rename-column case
- Survey: check if `golang-migrate`, `sqitch`, or `dbmate` already cover
  this before building
- Decision: build vs adopt — write a one-pager when the spike is done

## What Finishing Looks Like
- [ ] Build-vs-adopt decision written and shared with the platform team
- [ ] If build: declarative format covers rename, add-with-default, drop,
      and backfill cases
- [ ] If adopt: one of our three pain-point migrations ported as a worked
      example

## Blockers
Just waiting on me to make space for it after realtime-pipeline lands.

## Notes
The reason this isn't `status: active` yet is the survey step. Half the
value of capturing it as an idea is forcing the survey before the build
instinct takes over.
