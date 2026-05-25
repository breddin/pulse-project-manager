---
id: short-slug-here
project: short-slug-here
status: active        # idea | active | design | research | blocked | done | archived
health: green         # green | yellow | red  (optional; overridden by stale/blocked)
completion: 0         # 0-100
priority: p2          # p0 | p1 | p2 | p3
last_touched: 2026-05-24
paths:                # optional; focus-lock uses this to detect drift
  - src/example/**
  - tests/example/**
owner: human          # human | claude-code-session-id | <teammate>
---

# Short Title

## Last Stop
Where you left off, in enough detail that a cold resume works. What state
is the code in. What was the last thing tested. What's loaded in your head
when you open this file.

## Next Actions
Concrete, executable. Not "improve performance." Closer to:
- Run `npm test src/foo` and triage the three failing cases
- Open PR for the migration script and tag @reviewer
- Write the rollback procedure into `docs/runbooks/foo.md`

## What Finishing Looks Like
Exit criteria. The line that prevents scope creep. If you can't write this,
the project isn't well-scoped enough to start.
- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2
- [ ] Acceptance criterion 3

## Blockers (if any)
What's stopping forward motion. Owner. Expected unblock date.

## Notes
Free-form context for Future You.
