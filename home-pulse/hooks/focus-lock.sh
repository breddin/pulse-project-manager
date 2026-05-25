#!/usr/bin/env bash
# focus-lock.sh — PostToolUse hook
#
# When an edit occurs:
#   1. Determine which registered project owns the edited path (longest-
#      prefix match against default_focus_dir entries in projects.toml).
#   2. If that project has a .focus-lock, read the locked slice name.
#   3. Look up the slice's PULSE, extract its paths: allowlist.
#   4. If the edited path isn't covered by any glob in the allowlist,
#      block the edit with a message naming the three escape hatches.
#
# Edits outside any registered project are ignored — focus-lock is opt-in
# per project, not global.
#
# Escape hatches:
#   - Widen scope:  add the path to the locked PULSE's paths: list
#   - Switch focus: echo new-slice > <project>/.focus-lock
#   - Bypass:       touch ~/.pulse/.focus-lock-bypass (cleared next session)
#
# Hook wiring (in .claude/settings.json):
#   {
#     "hooks": {
#       "PostToolUse": [
#         { "matcher": "Write|Edit|MultiEdit|str_replace|create_file",
#           "hooks": [{ "type": "command",
#                       "command": "bash ~/.pulse/hooks/focus-lock.sh" }]}
#       ]
#     }
#   }

set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$HOOK_DIR/lib.sh"

BYPASS_FILE="$PULSE_HOME/.focus-lock-bypass"
[[ -f "$BYPASS_FILE" ]] && exit 0

# Read tool input from stdin (Claude Code passes JSON). Best-effort scrape —
# we don't want a hard jq dependency for a hook that runs on every tool call.
tool_input=$(cat 2>/dev/null || echo "")
edited_path=$(printf '%s' "$tool_input" \
  | grep -oE '"(file_path|path|filePath)"[[:space:]]*:[[:space:]]*"[^"]+"' \
  | head -n1 \
  | sed -E 's/.*"([^"]+)"$/\1/')

[[ -z "$edited_path" ]] && exit 0

# Normalize to absolute
if [[ "${edited_path:0:1}" != "/" ]]; then
  edited_path="$PWD/$edited_path"
fi

# Find which registered project this edit belongs to. If none, this is
# an edit outside any tracked workspace — let it through.
find_project_for_path "$edited_path" || exit 0

# Check for a focus lock in that project
lock_file="$PROJECT_DIR/.focus-lock"
[[ ! -f "$lock_file" ]] && exit 0

slice=$(head -n1 "$lock_file" | tr -d '[:space:]')
[[ -z "$slice" ]] && exit 0

# Always allow edits to the PULSE itself, the lock file, or the bypass marker
project_relative="${edited_path#$PROJECT_DIR/}"
pulse_dir_relative="${PROJECT_PULSE_DIR#$PROJECT_DIR/}"
case "$project_relative" in
  "$pulse_dir_relative/$slice.md"|".focus-lock"|".focus-lock-bypass") exit 0 ;;
esac

# Look up the locked PULSE
pulse_file="$PROJECT_PULSE_DIR/$slice.md"
if [[ ! -f "$pulse_file" ]]; then
  echo "focus-lock: locked slice '$slice' in project '$PROJECT_NAME' has no PULSE at $pulse_file" >&2
  echo "focus-lock: refusing to enforce against an unknown slice" >&2
  exit 0
fi

# Extract paths: glob allowlist
allowed_globs=$(awk '
  BEGIN { in_fm = 0; in_paths = 0 }
  /^---[[:space:]]*$/ { in_fm = !in_fm; if (!in_fm) exit; next }
  in_fm {
    if (/^paths:[[:space:]]*$/) { in_paths = 1; next }
    if (in_paths && /^[a-zA-Z_]+:/) { in_paths = 0 }
    if (in_paths && /^[[:space:]]*-[[:space:]]+/) {
      sub(/^[[:space:]]*-[[:space:]]+/, "")
      sub(/[[:space:]]+#.*/, "")
      gsub(/^[ \t]+|[ \t]+$/, "")
      print
    }
  }
' "$pulse_file")

# No paths declared on the PULSE = permissive by design (you can opt out
# of focus enforcement for a slice by leaving paths: off the frontmatter)
[[ -z "$allowed_globs" ]] && exit 0

# Glob → regex translator. Handles **, *, ?. Escapes regex metachars.
glob_match() {
  local glob="$1" path="$2" regex
  regex=$(printf '%s' "$glob" \
    | sed -e 's/[.[\^$+(){}|]/\\&/g' \
          -e 's#\*\*/#(.*/)?#g' \
          -e 's#\*\*#.*#g' \
          -e 's#\*#[^/]*#g' \
          -e 's#?#[^/]#g')
  [[ "$path" =~ ^${regex}$ ]]
}

while IFS= read -r glob; do
  [[ -z "$glob" ]] && continue
  if glob_match "$glob" "$project_relative"; then
    exit 0
  fi
done <<< "$allowed_globs"

cat >&2 <<EOF
focus-lock: blocked edit outside the locked slice.

  Project:       $PROJECT_NAME
  Locked slice:  $slice
  Edited path:   $project_relative
  Allowed globs: $(echo "$allowed_globs" | paste -sd, -)

Either:
  1. Widen scope:    add the path to the paths: list in $pulse_file
  2. Switch focus:   echo new-slice > $PROJECT_DIR/.focus-lock
  3. Bypass:         touch $BYPASS_FILE  (cleared on next install)
EOF
exit 1
