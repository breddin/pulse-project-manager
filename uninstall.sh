#!/usr/bin/env bash
# uninstall.sh — remove ~/.pulse.
#
# Does NOT touch any project's pulse/ directory or .focus-lock — those
# live in the projects themselves and are out of scope here.
#
# Doesn't actually delete: moves ~/.pulse aside to a timestamped backup
# so you can recover if you change your mind. Delete the backup manually
# when you're sure.

set -euo pipefail

PULSE_HOME="${PULSE_HOME:-$HOME/.pulse}"

if [[ ! -d "$PULSE_HOME" ]]; then
  echo "uninstall: nothing to do — $PULSE_HOME doesn't exist."
  exit 0
fi

# Show what won't be touched (data the user might worry about)
if [[ -f "$PULSE_HOME/projects.toml" ]]; then
  echo "These registered project pulse dirs will NOT be touched:"
  awk -F'"' '/^path[[:space:]]*=/{print "  " $2}' "$PULSE_HOME/projects.toml"
  echo ""
fi

if [[ "${ASSUME_YES:-no}" != "yes" ]]; then
  read -r -p "Move $PULSE_HOME aside (backup, not delete)? [y/N] " yn
  case "$yn" in
    [Yy]*) ;;
    *) echo "Aborted."; exit 1 ;;
  esac
fi

BACKUP="$PULSE_HOME.removed-$(date +%Y%m%d-%H%M%S)"
mv "$PULSE_HOME" "$BACKUP"

cat <<EOF
Moved to $BACKUP

Delete it manually when you're sure:
  rm -rf "$BACKUP"

To reinstall later: bash <starter>/install.sh
EOF
