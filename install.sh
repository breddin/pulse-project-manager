#!/usr/bin/env bash
# install.sh — provision ~/.pulse from this starter.
#
# Idempotent: if ~/.pulse exists, backs it up first.
# Registers the two bundled example projects so the dashboard renders
# meaningfully on first run.
#
# Override the destination with PULSE_HOME (e.g. for dotfiles testing):
#   PULSE_HOME=/tmp/test-pulse bash install.sh

set -euo pipefail

STARTER_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PULSE_HOME="${PULSE_HOME:-$HOME/.pulse}"

# --- preflight checks --------------------------------------------------

if [[ "${BASH_VERSINFO[0]:-0}" -lt 4 ]]; then
  cat >&2 <<EOF
Pulse needs bash 4 or newer (you have ${BASH_VERSION}).

The hooks use associative arrays. On macOS, the system bash is 3.2 —
install a newer one and rerun with it:
  brew install bash
  /opt/homebrew/bin/bash install.sh    # Apple Silicon
  /usr/local/bin/bash install.sh       # Intel
EOF
  exit 1
fi

if [[ ! -d "$STARTER_DIR/home-pulse" ]]; then
  echo "install: can't find home-pulse/ next to install.sh at $STARTER_DIR" >&2
  echo "install: did you extract the starter tarball cleanly?" >&2
  exit 1
fi

# --- summary + confirmation -------------------------------------------

cat <<EOF
Pulse framework installer

  Starter:     $STARTER_DIR
  Destination: $PULSE_HOME

What this will do:
  1. (If $PULSE_HOME exists) Move it to $PULSE_HOME.bak-YYYYMMDD-HHMMSS
  2. Create $PULSE_HOME/{hooks,templates,observations,_archive}
  3. Install hooks, template, and config
  4. Generate projects.toml registering the two bundled example projects
     (so the dashboard shows something on first run)

This will NOT touch:
  - Any pulse/ directory inside your real projects
  - Your shell rc files or Claude Code settings (you'll wire those manually)

EOF

if [[ "${ASSUME_YES:-no}" != "yes" ]]; then
  read -r -p "Proceed? [y/N] " yn
  case "$yn" in
    [Yy]*) ;;
    *) echo "Aborted."; exit 1 ;;
  esac
fi

# --- backup existing ---------------------------------------------------

if [[ -d "$PULSE_HOME" ]]; then
  BACKUP="$PULSE_HOME.bak-$(date +%Y%m%d-%H%M%S)"
  echo "→ Backing up existing $PULSE_HOME"
  echo "   to $BACKUP"
  mv "$PULSE_HOME" "$BACKUP"
fi

# --- create structure --------------------------------------------------

echo "→ Creating $PULSE_HOME"
mkdir -p "$PULSE_HOME"/{hooks,templates,observations,_archive}

# --- install hooks -----------------------------------------------------

echo "→ Installing hooks"
cp "$STARTER_DIR/home-pulse/hooks/lib.sh" "$PULSE_HOME/hooks/"
cp "$STARTER_DIR/home-pulse/hooks/session-start-dashboard.sh" "$PULSE_HOME/hooks/"
cp "$STARTER_DIR/home-pulse/hooks/focus-lock.sh" "$PULSE_HOME/hooks/"
cp "$STARTER_DIR/home-pulse/hooks/pulse-bump.sh" "$PULSE_HOME/hooks/"
chmod +x "$PULSE_HOME/hooks/"*.sh

# --- install template and config --------------------------------------

echo "→ Installing template"
cp "$STARTER_DIR/home-pulse/templates/_template.md" "$PULSE_HOME/templates/"

echo "→ Writing config.toml"
cp "$STARTER_DIR/home-pulse/config.toml" "$PULSE_HOME/config.toml"

# --- generate registry pointing at example projects -------------------

echo "→ Generating projects.toml (registers the two bundled examples)"
cat > "$PULSE_HOME/projects.toml" <<EOF
# Pulse project registry
#
# Each [[projects]] entry registers one project:
#   name              — display name shown in the dashboard group header
#   path              — absolute path to that project's pulse/ directory
#   default_focus_dir — where the project's .focus-lock lives (typically
#                       the project root)
#
# The two entries below point at the example projects bundled with the
# starter. Use them to confirm the framework works, then replace with
# your real projects via:
#
#   bash $STARTER_DIR/add-project.sh
#
# or by editing this file directly.

[[projects]]
name = "example-alpha"
path = "$STARTER_DIR/example-projects/proj-alpha/pulse"
default_focus_dir = "$STARTER_DIR/example-projects/proj-alpha"

[[projects]]
name = "example-beta"
path = "$STARTER_DIR/example-projects/proj-beta/pulse"
default_focus_dir = "$STARTER_DIR/example-projects/proj-beta"
EOF

# --- done --------------------------------------------------------------

cat <<EOF

Done.

Verify the install:
  bash $PULSE_HOME/hooks/session-start-dashboard.sh

You should see two projects (example-alpha, example-beta), six visual
states across them (🟢 active, 🟡 stale, 🔴 blocked, ✅ done, ⚪ idea,
⬛ archived), a FINISHER prompt for realtime-pipeline, and a FOCUS LOCKS
section showing example-alpha is locked to search-api-v2.

Next steps:
  1. Register your real projects:
       bash $STARTER_DIR/add-project.sh
  2. Drop a first PULSE into each:
       cp $PULSE_HOME/templates/_template.md \\
          /path/to/your/project/pulse/your-first-slice.md
  3. Wire into Claude Code (see settings.example.json in the starter)
  4. (Optional) Remove the example projects from $PULSE_HOME/projects.toml
     once you have your real ones registered

To uninstall (does NOT touch your project pulse/ dirs):
  bash $STARTER_DIR/uninstall.sh
EOF
