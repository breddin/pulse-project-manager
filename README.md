# PULSE — Multi-Project File-Based Portfolio Tracking

A framework for tracking a portfolio of in-flight projects across multiple repos using markdown files, a global registry, and three bash hooks. Designed for operators running many projects in parallel — typically with AI coding agents — where conventional project-management tools are too heavy and "just remember everything" stops working past about three concurrent threads.

The thesis: **visibility beats discipline**. Once your portfolio grows past what willpower can sustain, you don't need a better todo system — you need the state of the world rendered for you at the moment you sit down to work. PULSE is that rendering.

## Architecture

Two layers, with a registry binding them:

```
~/.pulse/                                      ← installed once per machine
├── projects.toml                              ← the registry — what's tracked, where
├── config.toml                                ← thresholds (stale days, finisher %)
├── hooks/
│   ├── lib.sh                                 ← shared functions
│   ├── session-start-dashboard.sh             ← portfolio render
│   ├── focus-lock.sh                          ← drift detection
│   └── pulse-bump.sh                          ← frontmatter updates
├── templates/_template.md
├── observations/                              ← optional, for cross-project notes
└── _archive/                                  ← optional, for retired PULSEs

<your project>/                                ← one of these per registered project
├── .focus-lock                                ← (optional) names the locked slice
└── pulse/
    ├── slice-one.md
    ├── slice-two.md
    └── ...
```

The hooks read the registry, walk each project's `pulse/` directory, and render a unified dashboard.

## What's in the starter

```
pulse-framework-starter/
├── README.md                       ← you are here
├── QUICKSTART.md                   ← 5-minute setup
├── install.sh                      ← idempotent installer for ~/.pulse
├── add-project.sh                  ← register a project (interactive or scripted)
├── uninstall.sh                    ← move ~/.pulse aside (does not touch projects)
├── settings.example.json           ← Claude Code hook wiring
├── .gitignore
├── home-pulse/                     ← contents that become ~/.pulse on install
│   ├── config.toml
│   ├── templates/_template.md
│   └── hooks/
│       ├── lib.sh
│       ├── session-start-dashboard.sh
│       ├── focus-lock.sh
│       └── pulse-bump.sh
└── example-projects/               ← two reference projects with seven PULSEs
    ├── README.md
    ├── proj-alpha/
    │   ├── .focus-lock
    │   └── pulse/
    │       ├── search-api-v2.md            (active 🟢)
    │       ├── billing-webhook-rewrite.md  (blocked 🔴)
    │       ├── legacy-cleanup.md           (stale 🟡)
    │       └── ci-pipeline-hardening.md    (done ✅)
    └── proj-beta/
        └── pulse/
            ├── realtime-pipeline.md        (active 85%, finisher 🟢)
            ├── schema-migration-tool.md    (idea ⚪)
            └── vector-search-spike.md      (archived ⬛)
```

`install.sh` registers the two example projects in `projects.toml` so the dashboard renders something on first run. Replace them with your real projects via `add-project.sh` once you've verified the framework works.

## The three primitives

**PULSE files** (`<project>/pulse/*.md`) — one markdown file per slice, with YAML frontmatter for the machine-readable state (status, completion, priority, `last_touched`, owned paths) and four prose sections for the human-readable state (Last Stop, Next Actions, What Finishing Looks Like, Blockers, Notes). The frontmatter drives the dashboard; the prose is what you read.

**The dashboard hook** (`session-start-dashboard.sh`) — walks every registered project's `pulse/` directory, renders a grouped status table with visual health indicators, and nominates a "finisher candidate" when an in-flight PULSE crosses the threshold (default 80%). Wired as a SessionStart hook so Claude Code shows you the portfolio before you start typing.

**The focus-lock hook** (`focus-lock.sh`) — wired as PostToolUse. When an edit occurs, the hook figures out which project owns the path, looks up that project's `.focus-lock`, finds the locked PULSE's `paths:` allowlist, and blocks the edit if it's outside scope. The point isn't to make drift impossible — `touch ~/.pulse/.focus-lock-bypass` is one keystroke. The point is to make drift *visible and intentional*.

## Visual indicators

The Health column uses six glyphs to encode the full status × health × staleness × lifecycle space at a glance:

| Glyph | Meaning |
|---|---|
| 🟢 | active + healthy (no health flag, or `health: green`) |
| 🟡 | stale — `last_touched` > `stale_threshold_days` (default 21) |
| 🔴 | blocked — `status: blocked` |
| ✅ | done — `status: done` |
| ⬛ | archived — `status: archived` |
| ⚪ | not yet in flight — `status: idea`, `design`, or `research` |

Status overrides flag for the terminal states (done, archived) and the not-yet-started states (idea, design, research), so the colored column is a complete read at a glance.

## Customization

The hooks are intentionally small so you can read them in full and modify them. Common knobs:

- `stale_threshold_days` in `~/.pulse/config.toml` — default 21
- `finisher_threshold_pct` in `~/.pulse/config.toml` — default 80
- Both can be overridden per-invocation via env vars (`STALE_THRESHOLD_DAYS=14 bash ...`)
- Glyph mapping is a `case` block at the top of the row-rendering loop in `session-start-dashboard.sh`
- The status set — add `experiment` or `paused` if those map to how you actually work
- The `pulse_dir` convention — defaults to `<project>/pulse` but can be anywhere; `projects.toml` records the absolute path

## What this is not

- **Not a project management tool.** PULSE files are for the operator and the agent, not for stakeholder reporting. Roll up to your real PM tool separately.
- **Not a substitute for thinking.** The dashboard surfaces information; it doesn't decide what to do. The finisher prompt nominates a candidate; you choose.
- **Not a discipline enforcer.** The focus-lock blocks accidental drift, but `touch ~/.pulse/.focus-lock-bypass` is one keystroke. The system makes drift visible and intentional, not impossible. That's the whole point.

## Credits

Patterns drawn from [AaronRoeF/claude-code-patterns](https://github.com/AaronRoeF/claude-code-patterns) and Aaron Fulkerson's *Visibility Beats Discipline*. The multi-project registry pattern, focus-lock semantics, and dashboard layout are Aaron's; the visual glyph layer and the packaging are extensions.
