# Example Projects

These two project directories are **visual reference**, not a workspace. They demonstrate:

- The layout of a project's `pulse/` directory at its repo root
- A spread of PULSE files showing every status and glyph the dashboard can render
- A `.focus-lock` in `proj-alpha` so the dashboard's `FOCUS LOCKS` section renders populated

After `install.sh` runs, the bundled `projects.toml` registers both of these so the very first invocation of `session-start-dashboard.sh` shows a fully-populated dashboard. Once you've confirmed everything works, swap them out for your real projects (via `add-project.sh` or by editing `~/.pulse/projects.toml`).

## What each project shows

**proj-alpha** — a hypothetical backend service portfolio:

| PULSE | Status | Glyph | Why it's here |
|---|---|---|---|
| `search-api-v2` | active 55% | 🟢 | the active-and-healthy baseline |
| `billing-webhook-rewrite` | blocked | 🔴 | shows how vendor blockers surface |
| `legacy-cleanup` | active but stale | 🟡 | the canonical "easy to come back to, never came back to" |
| `ci-pipeline-hardening` | done 100% | ✅ | retrospective notes pattern |

A `.focus-lock` pins `proj-alpha` to `search-api-v2` so you can see how the dashboard reports active focus.

**proj-beta** — a hypothetical data-platform portfolio:

| PULSE | Status | Glyph | Why it's here |
|---|---|---|---|
| `realtime-pipeline` | active 85% | 🟢 | triggers the FINISHER prompt (≥ 80% threshold) |
| `schema-migration-tool` | idea | ⚪ | shows how an idea is captured before becoming active |
| `vector-search-spike` | archived | ⬛ | a spike that succeeded by answering "no" |

## Reading order

Read the PULSEs in this order — it's roughly the lifecycle a slice moves through:

1. `proj-beta/pulse/schema-migration-tool.md` (idea: how to capture without committing)
2. `proj-alpha/pulse/search-api-v2.md` (active: Last Stop and Next Actions in detail)
3. `proj-beta/pulse/realtime-pipeline.md` (near-done: what high completion looks like)
4. `proj-alpha/pulse/billing-webhook-rewrite.md` (blocked: how to park a slice cleanly)
5. `proj-alpha/pulse/legacy-cleanup.md` (stale: the failure mode the framework targets)
6. `proj-alpha/pulse/ci-pipeline-hardening.md` (done: the retrospective pattern)
7. `proj-beta/pulse/vector-search-spike.md` (archived: how to kill a slice without losing the learnings)
