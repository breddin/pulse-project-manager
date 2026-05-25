#!/usr/bin/env bash
# lib.sh — shared functions for pulse hooks.
#
# Sourced by:
#   session-start-dashboard.sh
#   focus-lock.sh
#   pulse-bump.sh
#
# Single source of truth for: registry parsing, project lookup by path,
# YAML frontmatter field extraction, days-since with GNU+BSD date fallback,
# and config loading with env > config > builtin precedence.
#
# All functions are pure (no side effects) except:
#   - find_project_for_path sets globals PROJECT_NAME, PROJECT_DIR, PROJECT_PULSE_DIR
#   - load_config sets globals STALE_THRESHOLD_DAYS, FINISHER_THRESHOLD_PCT

PULSE_HOME="${PULSE_HOME:-$HOME/.pulse}"
PULSE_REGISTRY="${PULSE_REGISTRY:-$PULSE_HOME/projects.toml}"
PULSE_CONFIG="${PULSE_CONFIG:-$PULSE_HOME/config.toml}"

# ---------------------------------------------------------------------
# parse_registry — emit one project per line, tab-separated:
#   <name>\t<path>\t<default_focus_dir>
#
# Tolerant of blank lines, comments, and inconsistent whitespace.
# Does NOT validate that paths exist — that's the caller's job.
# ---------------------------------------------------------------------
parse_registry() {
  local file="${1:-$PULSE_REGISTRY}"
  [[ -f "$file" ]] || return 0
  awk '
    BEGIN { name=""; path=""; focus="" }
    /^[[:space:]]*#/ { next }
    /^\[\[projects\]\]/ {
      if (name != "") print name "\t" path "\t" focus
      name=""; path=""; focus=""
      next
    }
    /^name[[:space:]]*=/ {
      sub(/^name[[:space:]]*=[[:space:]]*/, ""); gsub(/^"|"$/, "")
      name=$0; next
    }
    /^path[[:space:]]*=/ {
      sub(/^path[[:space:]]*=[[:space:]]*/, ""); gsub(/^"|"$/, "")
      path=$0; next
    }
    /^default_focus_dir[[:space:]]*=/ {
      sub(/^default_focus_dir[[:space:]]*=[[:space:]]*/, ""); gsub(/^"|"$/, "")
      focus=$0; next
    }
    END { if (name != "") print name "\t" path "\t" focus }
  ' "$file"
}

# ---------------------------------------------------------------------
# get_field — extract a single key from YAML frontmatter.
# Returns empty string if key not found.
# Strips surrounding quotes and any inline `# comment` annotation so
# values from a freshly-bootstrapped PULSE template (which contains
# field documentation like `priority: p2  # p0 | p1 | p2 | p3`) parse
# as clean values.
# ---------------------------------------------------------------------
get_field() {
  local file="$1" field="$2"
  awk -v f="$field" '
    BEGIN { in_fm = 0 }
    /^---$/ { in_fm = !in_fm; next }
    in_fm && $1 == f":" {
      sub(/^[^:]+:[[:space:]]*/, "")
      sub(/[[:space:]]+#.*$/, "")
      gsub(/^[[:space:]]+|[[:space:]]+$/, "")
      gsub(/^"|"$/, "")
      print
      exit
    }
  ' "$file"
}

# ---------------------------------------------------------------------
# days_since — days between $1 (YYYY-MM-DD) and today.
# Returns 9999 for empty/unparseable input (callers use this as a
# "stale forever" sentinel).
# Cross-platform: GNU `date -d` first, BSD `date -j -f` fallback.
# ---------------------------------------------------------------------
days_since() {
  local date_str="$1"
  [[ -z "$date_str" ]] && { echo 9999; return; }
  local today_epoch then_epoch
  today_epoch=$(date +%s)
  then_epoch=$(date -d "$date_str" +%s 2>/dev/null \
            || date -j -f "%Y-%m-%d" "$date_str" +%s 2>/dev/null \
            || echo 0)
  [[ "$then_epoch" -eq 0 ]] && { echo 9999; return; }
  echo $(( (today_epoch - then_epoch) / 86400 ))
}

# ---------------------------------------------------------------------
# find_project_for_path — given an absolute path, find which registered
# project contains it. Uses longest-prefix match in case projects nest.
#
# Sets: PROJECT_NAME, PROJECT_DIR, PROJECT_PULSE_DIR
# Returns: 0 on match, 1 on no match.
# ---------------------------------------------------------------------
find_project_for_path() {
  local target="$1"
  PROJECT_NAME=""; PROJECT_DIR=""; PROJECT_PULSE_DIR=""
  local best_len=0
  local name path focus
  while IFS=$'\t' read -r name path focus; do
    [[ -z "$focus" ]] && continue
    if [[ "$target" == "$focus" ]] || [[ "$target" == "$focus"/* ]]; then
      local len=${#focus}
      if (( len > best_len )); then
        best_len=$len
        PROJECT_NAME="$name"
        PROJECT_DIR="$focus"
        PROJECT_PULSE_DIR="$path"
      fi
    fi
  done < <(parse_registry "$PULSE_REGISTRY")
  [[ -n "$PROJECT_NAME" ]]
}

# ---------------------------------------------------------------------
# load_config — populate config globals with precedence:
#   env var > $PULSE_CONFIG value > builtin default
# ---------------------------------------------------------------------
load_config() {
  local cfg_stale="" cfg_finisher=""
  if [[ -f "$PULSE_CONFIG" ]]; then
    cfg_stale=$(awk -F'=' '
      /^[[:space:]]*stale_threshold_days[[:space:]]*=/ {
        gsub(/[ \t"]/, "", $2); print $2; exit
      }' "$PULSE_CONFIG")
    cfg_finisher=$(awk -F'=' '
      /^[[:space:]]*finisher_threshold_pct[[:space:]]*=/ {
        gsub(/[ \t"]/, "", $2); print $2; exit
      }' "$PULSE_CONFIG")
  fi
  STALE_THRESHOLD_DAYS="${STALE_THRESHOLD_DAYS:-${cfg_stale:-21}}"
  FINISHER_THRESHOLD_PCT="${FINISHER_THRESHOLD_PCT:-${cfg_finisher:-80}}"
}
