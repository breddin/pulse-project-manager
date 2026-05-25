# QUICKSTART

Five minutes to a working PULSE setup with two example projects, then a path to your real projects.

## Prerequisites

- bash 4 or newer (macOS ships with 3.2 — `brew install bash` to get a newer one)
- A terminal that renders emoji as 2 visual cols (macOS Terminal, iTerm2, modern VS Code terminal, Linux terminal emulators — all fine)

## 1. Install

From the unpacked starter directory:

```bash
bash install.sh
```

The installer will:

1. Back up any existing `~/.pulse/` to `~/.pulse.bak-YYYYMMDD-HHMMSS` (so it's safe to re-run)
2. Create `~/.pulse/{hooks,templates,observations,_archive}`
3. Install the three hooks + shared library, the PULSE template, and `config.toml`
4. Write `~/.pulse/projects.toml` registering the two bundled example projects

It does **not** touch your shell rc files or Claude Code settings — those you wire manually in step 4.

## 2. Verify

```bash
bash ~/.pulse/hooks/session-start-dashboard.sh
```

You should see two projects (`example-alpha` and `example-beta`), all six glyphs (🟢🟡🔴✅⚪⬛), a `FINISHER` prompt for `realtime-pipeline`, and a `FOCUS LOCKS` section showing `example-alpha` locked to `search-api-v2`.

If you see "PULSE: no pulse/ directory found" or "bash: associative arrays" errors, see the Troubleshooting section below.

## 3. Register your real projects

Two options. Either way, each project gets a `pulse/` directory at its root and an entry in `~/.pulse/projects.toml`.

**Interactive:**

```bash
bash <starter>/add-project.sh
# prompts for: name, project root
```

**Scripted with bootstrap (creates `pulse/` and a first PULSE for you):**

```bash
bash <starter>/add-project.sh my-service /Users/you/code/my-service --init
```

The `--init` flag creates `<project>/pulse/getting-started.md` from the template with `id`, `project`, and `last_touched` pre-filled. Open it and replace the placeholder content with your actual Last Stop / Next Actions.

After registering, re-run the dashboard. Your new project should appear in the table.

## 4. Wire into Claude Code

Merge the `hooks` and `permissions` blocks from `settings.example.json` (in the starter) into either:

- `.claude/settings.json` at your project root (team-shared, checked into git)
- `~/.claude/settings.json` (personal, applies across all repos)

The wired hooks:

| Event | Hook | What it does |
|---|---|---|
| `SessionStart` | `session-start-dashboard.sh` | Renders the dashboard when a Claude Code session opens |
| `PostToolUse` (Write/Edit/etc.) | `focus-lock.sh` | Blocks edits outside the locked slice's allowed paths |

Restart Claude Code after merging. The next session opens with the dashboard rendered automatically.

## 5. The daily loop

**Start of work block.** Read the dashboard. Pick a slice. Lock in:

```bash
cd /path/to/your/project
echo "your-slice-slug" > .focus-lock
```

**Mid-session.** Edit code freely inside the slice's declared `paths:`. If you try to touch something outside, the focus-lock blocks the edit and tells you the three escape hatches:

1. Widen scope — add the path to the locked PULSE's `paths:` list
2. Switch focus — `echo new-slice > .focus-lock`
3. Bypass — `touch ~/.pulse/.focus-lock-bypass` (cleared on next install)

**End of work block.** Bump the PULSE:

```bash
bash ~/.pulse/hooks/pulse-bump.sh 65          # completion → 65%
bash ~/.pulse/hooks/pulse-bump.sh 100 done    # complete and mark done
```

With no slice argument, `pulse-bump.sh` reads it from `.focus-lock` — so the common case is one command, run from the project root.

**Weekly.** Open the dashboard. Notice which 🟡 rows you keep walking past. Close the next one.

## 6. Clean up the examples (optional)

Once your real projects are registered and you no longer need the example dashboard:

```bash
# Edit ~/.pulse/projects.toml and remove the [[projects]] blocks for
# example-alpha and example-beta. (The example PULSE files themselves
# stay in the starter dir as reference — only the registry entries
# come out.)
$EDITOR ~/.pulse/projects.toml
```

## Troubleshooting

**`bash: associative arrays`** or similar syntax error. macOS bash 3.2 doesn't support `declare -A`. Install bash 4+: `brew install bash`, then re-run with the new binary path explicitly (e.g. `/opt/homebrew/bin/bash install.sh`).

**Dashboard shows `touched ?d ago`.** Your `date` command can't parse the `last_touched:` value. `lib.sh` tries GNU `date -d` and BSD `date -j -f` — if neither works, install GNU coreutils (`brew install coreutils`) or hand-patch `days_since` in `lib.sh`.

**Focus-lock isn't blocking anything.** Check that `.focus-lock` exists at the project root (matching `default_focus_dir` in `projects.toml`) and contains the slice slug on the first line. Then check that the PULSE for that slice has a `paths:` block — without one, focus-lock is permissive by design.

**Focus-lock blocks edits unexpectedly.** Run the dashboard — the `FOCUS LOCKS` section names every active lock. If one is pointed at a stale or completed PULSE, the dashboard surfaces it with `[STALE — PULSE marked done]` and tells you how to clear or switch it.

**Hooks work in your terminal but not when Claude Code triggers them.** Claude Code inherits your shell's environment at launch. If you change a relevant env var, restart Claude Code. For `PULSE_HOME` overrides specifically, put the export in `~/.bashrc` / `~/.zshrc` so it's there at launch.

**`add-project.sh: '<name>' is already registered.`** Idempotent guard — the script won't duplicate the entry. If you actually need to re-register (e.g. the path changed), edit `~/.pulse/projects.toml` directly.

**Dashboard reports `missing pulse dir`.** A registered project's `path` in `projects.toml` doesn't resolve. Either the project moved, or it's on an unmounted volume. The dashboard skips it and keeps going.
