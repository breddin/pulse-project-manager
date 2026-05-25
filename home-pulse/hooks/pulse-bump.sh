#!/usr/bin/env bash
# pulse-bump.sh — update a PULSE file's frontmatter in place.
#
# Determines which registered project to operate on based on cwd. The
# slice is either passed explicitly or read from the project's
# .focus-lock — so the common case (cd into your project, bump the
# currently-locked slice) is a single short command.
#
# Usage (with .focus-lock present in the current project):
#   pulse-bump.sh                       # today's date, no other changes
#   pulse-bump.sh 65                    # completion → 65%
#   pulse-bump.sh 100 done              # completion → 100%, status → done
#
# Usage (explicit slice):
#   pulse-bump.sh <slice>               # touch a specific PULSE
#   pulse-bump.sh <slice> 65            # explicit slice, completion → 65%
#   pulse-bump.sh <slice> 100 done      # explicit slice, completion + status

set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$HOOK_DIR/lib.sh"

# Project lookup based on cwd
if ! find_project_for_path "$PWD"; then
  cat >&2 <<EOF
pulse-bump: cwd is not inside any registered project.

  cwd:      $PWD
  registry: $PULSE_REGISTRY

Either:
  1. cd into a registered project, then retry
  2. Register this project:  bash <starter>/add-project.sh
EOF
  exit 2
fi

# Resolve slice from args (if first arg matches an existing PULSE) or focus-lock
slice=""
if (( $# >= 1 )) && [[ -f "$PROJECT_PULSE_DIR/$1.md" ]]; then
  slice="$1"; shift
fi

if [[ -z "$slice" ]]; then
  if [[ -f "$PROJECT_DIR/.focus-lock" ]]; then
    slice=$(head -n1 "$PROJECT_DIR/.focus-lock" | tr -d '[:space:]')
  fi
fi

if [[ -z "$slice" ]]; then
  cat >&2 <<EOF
pulse-bump: no slice specified and no $PROJECT_DIR/.focus-lock present.

Usage:
  pulse-bump.sh [<slice>] [completion] [status]
EOF
  exit 2
fi

pulse_file="$PROJECT_PULSE_DIR/$slice.md"
if [[ ! -f "$pulse_file" ]]; then
  echo "pulse-bump: no PULSE found at $pulse_file" >&2
  exit 2
fi

completion=""
status=""
(( $# >= 1 )) && { completion="$1"; shift; }
(( $# >= 1 )) && { status="$1"; shift; }

today=$(date +%Y-%m-%d)

# In-place update via temp + mv (portable across GNU/BSD sed)
tmp=$(mktemp)
awk -v today="$today" -v comp="$completion" -v stat="$status" '
  BEGIN { in_fm = 0; fm_done = 0 }
  /^---[[:space:]]*$/ {
    if (!fm_done) {
      in_fm = !in_fm
      if (!in_fm) fm_done = 1
    }
    print; next
  }
  in_fm && /^last_touched:/                  { print "last_touched: " today; next }
  in_fm && /^completion:/  && comp != ""     { print "completion: " comp; next }
  in_fm && /^status:/      && stat != ""     { print "status: " stat; next }
  { print }
' "$pulse_file" > "$tmp"
mv "$tmp" "$pulse_file"

echo "bumped: $PROJECT_NAME/$slice"
[[ -n "$completion" ]] && echo "  completion   → $completion%"
[[ -n "$status" ]]     && echo "  status       → $status"
echo "  last_touched → $today"
