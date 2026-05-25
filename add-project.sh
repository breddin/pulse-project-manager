#!/usr/bin/env bash
# add-project.sh — register a project in ~/.pulse/projects.toml.
#
# Idempotent: re-running with an already-registered name is a no-op
# (won't duplicate the entry, won't clobber an existing pulse/ dir).
#
# Usage:
#   bash add-project.sh                              # interactive
#   bash add-project.sh <name> <project-root>        # explicit
#   bash add-project.sh <name> <project-root> --init # also bootstrap pulse/ + a first PULSE
#
# After registering: bash ~/.pulse/hooks/session-start-dashboard.sh

set -euo pipefail

PULSE_HOME="${PULSE_HOME:-$HOME/.pulse}"
REGISTRY="$PULSE_HOME/projects.toml"
TEMPLATE="$PULSE_HOME/templates/_template.md"

if [[ ! -f "$REGISTRY" ]]; then
  echo "add-project: no registry at $REGISTRY — run install.sh first." >&2
  exit 1
fi

# --- parse args --------------------------------------------------------

name=""
project_root=""
init_pulse=false

for arg in "$@"; do
  case "$arg" in
    --init)  init_pulse=true ;;
    -h|--help)
      sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
      exit 0 ;;
    *)
      if [[ -z "$name" ]]; then
        name="$arg"
      elif [[ -z "$project_root" ]]; then
        project_root="$arg"
      else
        echo "add-project: unexpected argument: $arg" >&2
        exit 2
      fi ;;
  esac
done

# --- interactive fill-in ----------------------------------------------

if [[ -z "$name" ]]; then
  read -r -p "Project display name: " name
fi
if [[ -z "$project_root" ]]; then
  read -r -p "Project root directory (absolute path): " project_root
fi

[[ -z "$name" ]]         && { echo "add-project: need a name." >&2;        exit 2; }
[[ -z "$project_root" ]] && { echo "add-project: need a project root." >&2; exit 2; }

# --- validate and normalize -------------------------------------------

if [[ ! -d "$project_root" ]]; then
  echo "add-project: project root does not exist: $project_root" >&2
  exit 2
fi
project_root=$(cd "$project_root" && pwd)
pulse_dir="$project_root/pulse"

# --- idempotency: already registered? ---------------------------------

if grep -qE "^name[[:space:]]*=[[:space:]]*\"$name\"" "$REGISTRY"; then
  echo "add-project: '$name' is already registered. No changes."
  exit 0
fi

# --- bootstrap pulse/ (only with --init) ------------------------------

if [[ "$init_pulse" == true ]]; then
  if [[ ! -d "$pulse_dir" ]]; then
    mkdir -p "$pulse_dir"
    echo "→ Created $pulse_dir"
  fi
  first_pulse="$pulse_dir/getting-started.md"
  if [[ ! -f "$first_pulse" ]]; then
    if [[ ! -f "$TEMPLATE" ]]; then
      echo "add-project: template missing at $TEMPLATE — skipping first-PULSE creation." >&2
    else
      # Substitute slug + date into the template via awk-to-tempfile (portable
      # across GNU/BSD sed)
      tmp=$(mktemp)
      awk -v slug="getting-started" -v today="$(date +%Y-%m-%d)" '
        /^id: short-slug-here/      { print "id: " slug; next }
        /^project: short-slug-here/ { print "project: " slug; next }
        /^last_touched:/            { print "last_touched: " today; next }
        { print }
      ' "$TEMPLATE" > "$tmp"
      mv "$tmp" "$first_pulse"
      echo "→ Created $first_pulse"
    fi
  fi
fi

# --- append to registry -----------------------------------------------

cat >> "$REGISTRY" <<EOF

[[projects]]
name = "$name"
path = "$pulse_dir"
default_focus_dir = "$project_root"
EOF

echo "Registered: $name"
echo "  pulse dir:        $pulse_dir"
echo "  default focus dir: $project_root"
echo ""
echo "Verify with:"
echo "  bash $PULSE_HOME/hooks/session-start-dashboard.sh"
