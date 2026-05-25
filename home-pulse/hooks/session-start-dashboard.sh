#!/usr/bin/env bash
# session-start-dashboard.sh — SessionStart hook
#
# Reads ~/.pulse/projects.toml, walks each registered project's pulse/
# directory, and prints a portfolio dashboard grouped by project, sorted
# by priority + staleness, with visual health indicators in the Health
# column.
#
# Backwards-compat single-project mode:
#   PULSE_DIR=/some/project/pulse bash session-start-dashboard.sh
#
# Visual indicators (Health column):
#   🟢 active + healthy
#   🟡 stale (last_touched > STALE_THRESHOLD_DAYS ago)
#   🔴 blocked
#   ✅ done
#   ⬛ archived
#   ⚪ idea / design / research (not yet in flight)
#
# Conventions:
#   - Yellow if last_touched > STALE_THRESHOLD_DAYS ago and not done/archived
#   - Red if status == blocked
#   - Done/archived PULSEs excluded from yellow/red counts
#   - Finisher = highest-completion in-flight PULSE at or above
#     FINISHER_THRESHOLD_PCT, across all projects

set -euo pipefail

HOOK_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=./lib.sh
source "$HOOK_DIR/lib.sh"

load_config

# ---------------------------------------------------------------------
# Collect projects to scan
# ---------------------------------------------------------------------

projects=()   # each entry: name<TAB>path<TAB>default_focus_dir

if [[ -n "${PULSE_DIR:-}" ]]; then
  # Backwards-compat single-project mode
  projects+=("local"$'\t'"$PULSE_DIR"$'\t'".")
else
  if [[ ! -f "$PULSE_REGISTRY" ]]; then
    echo "[pulse] no registry at $PULSE_REGISTRY and no PULSE_DIR set — nothing to display"
    exit 0
  fi
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    projects+=("$line")
  done < <(parse_registry "$PULSE_REGISTRY")
fi

if [[ ${#projects[@]} -eq 0 ]]; then
  echo "[pulse] registry $PULSE_REGISTRY has no project entries"
  exit 0
fi

# ---------------------------------------------------------------------
# Walk each project, collect rows + per-project focus state
# ---------------------------------------------------------------------

all_rows=()           # each: <project_name>\t<pri_num>\t<stale_days>\t<row_text>
focus_lines=()        # each: <project>\t<slice>\t<focus_dir>\t<stale_marker>
finisher_project=""
finisher_file=""
finisher_completion=0
yellow_count=0
red_count=0

declare -A done_pulses_by_project   # key: "<project>|<pulse_slug>" → 1 if done/archived

for entry in "${projects[@]}"; do
  IFS=$'\t' read -r proj_name proj_path proj_focus_dir <<< "$entry"

  if [[ ! -d "$proj_path" ]]; then
    echo "[pulse] project '$proj_name' has missing pulse dir: $proj_path"
    continue
  fi

  shopt -s nullglob
  for f in "$proj_path"/*.md; do
    base=$(basename "$f")
    [[ "$base" == "_template.md" ]] && continue

    pulse_id=$(get_field "$f" "id")
    pulse_title=$(get_field "$f" "title")
    pulse_project_field=$(get_field "$f" "project")
    status=$(get_field "$f" "status")
    health=$(get_field "$f" "health")
    completion=$(get_field "$f" "completion")
    priority=$(get_field "$f" "priority")
    last_touched=$(get_field "$f" "last_touched")

    # Display name precedence: project > id > title > filename
    display="${pulse_project_field:-${pulse_id:-${pulse_title:-${base%.md}}}}"

    [[ -z "$status" ]] && status="active"
    [[ -z "$completion" ]] && completion=0
    [[ -z "$priority" ]] && priority="p3"

    stale_days=$(days_since "$last_touched")
    pulse_slug="${pulse_id:-${base%.md}}"

    # Track done/archived PULSEs for stale-focus detection later
    if [[ "$status" == "done" || "$status" == "archived" ]]; then
      done_pulses_by_project["$proj_name|$pulse_slug"]=1
    fi

    # Visual status string (Status column)
    if [[ "$status" == "blocked" ]]; then
      visual="BLOCKED"
    elif (( stale_days > STALE_THRESHOLD_DAYS )) && [[ "$status" != "done" && "$status" != "archived" ]]; then
      visual="STALE($stale_days d)"
    else
      visual="$status"
    fi

    # Health flag (drives glyph + portfolio counters)
    if [[ "$status" == "done" || "$status" == "archived" ]]; then
      flag=""
    elif [[ "$status" == "blocked" ]]; then
      flag="red"
    elif (( stale_days > STALE_THRESHOLD_DAYS )); then
      flag="yellow"
    else
      flag="$health"
    fi

    # Glyph for the Health column. Status overrides flag for terminal
    # states (done/archived) and not-yet-started states (idea/design/
    # research), so the colored column gives a complete read at a glance.
    case "$status" in
      done)                 glyph="✅" ;;
      archived)             glyph="⬛" ;;
      idea|design|research) glyph="⚪" ;;
      *)
        case "$flag" in
          red)    glyph="🔴" ;;
          yellow) glyph="🟡" ;;
          *)      glyph="🟢" ;;
        esac
        ;;
    esac

    # Counters off the flag — single source of truth that survives glyph swaps
    case "$flag" in
      red)    ((red_count++))    || true ;;
      yellow) ((yellow_count++)) || true ;;
    esac

    pri_num="${priority#p}"; pri_num="${pri_num#P}"
    [[ ! "$pri_num" =~ ^[0-9]+$ ]] && pri_num=9

    # Finisher candidate (across all projects)
    if [[ "$status" != "done" && "$status" != "archived" && "$status" != "blocked" ]]; then
      if (( completion >= FINISHER_THRESHOLD_PCT )) && (( completion > finisher_completion )); then
        finisher_completion=$completion
        finisher_file="$pulse_slug"
        finisher_project="$proj_name"
      fi
    fi

    # Row layout: original Health slot was `%-7s  ` (7 ASCII cols + 2-col
    # separator). A 2-visual-col emoji + 7 literal spaces produces the
    # same 9 visual cols, so the header/separator rows (using `%-7s` for
    # "Health" / "-------") stay aligned with the data rows.
    row=$(printf "  %-3s  %-32s  %-12s  %s       %3d%%  %s" \
      "$priority" "$display" "$visual" "$glyph" "$completion" "${last_touched:-—}")

    all_rows+=("$proj_name"$'\t'"$pri_num"$'\t'"$stale_days"$'\t'"$row")
  done
  shopt -u nullglob

  # Per-project focus state
  if [[ -n "$proj_focus_dir" && -f "$proj_focus_dir/.focus-lock" ]]; then
    current_focus=$(cat "$proj_focus_dir/.focus-lock" 2>/dev/null | head -n1 | tr -d '[:space:]' || true)
    if [[ -n "$current_focus" ]]; then
      stale_marker=""
      if [[ -n "${done_pulses_by_project["$proj_name|$current_focus"]:-}" ]]; then
        stale_marker=" [STALE — PULSE marked done]"
      fi
      focus_lines+=("$proj_name"$'\t'"$current_focus"$'\t'"$proj_focus_dir"$'\t'"$stale_marker")
    fi
  fi
done

if [[ ${#all_rows[@]} -eq 0 ]]; then
  echo "[pulse] no PULSE files found in any registered project"
  exit 0
fi

# ---------------------------------------------------------------------
# Render — grouped by project, in registry order
# ---------------------------------------------------------------------

echo "PROJECT PULSE — Active Portfolio"
echo "================================"
echo ""

project_order=()
declare -A seen_proj
for entry in "${projects[@]}"; do
  IFS=$'\t' read -r proj_name _ _ <<< "$entry"
  if [[ -z "${seen_proj[$proj_name]:-}" ]]; then
    project_order+=("$proj_name")
    seen_proj["$proj_name"]=1
  fi
done

for proj_name in "${project_order[@]}"; do
  proj_rows=()
  for row in "${all_rows[@]}"; do
    IFS=$'\t' read -r row_proj _ _ _ <<< "$row"
    [[ "$row_proj" == "$proj_name" ]] && proj_rows+=("$row")
  done
  (( ${#proj_rows[@]} == 0 )) && continue

  echo "$proj_name"
  printf '%*s\n' "${#proj_name}" '' | tr ' ' '-'
  printf "  %-3s  %-32s  %-12s  %-7s  %4s  %s\n" "Pri" "Project" "Status" "Health" "Done" "Last Touch"
  printf "  %-3s  %-32s  %-12s  %-7s  %4s  %s\n" "---" "--------------------------------" "------------" "-------" "----" "----------"

  # Sort: priority ascending, staleness descending
  IFS=$'\n' sorted=($(printf '%s\n' "${proj_rows[@]}" | sort -t$'\t' -k2,2n -k3,3nr))
  unset IFS

  for r in "${sorted[@]}"; do
    echo "${r##*$'\t'}"
  done
  echo ""
done

# ---------------------------------------------------------------------
# Portfolio summary
# ---------------------------------------------------------------------

total=${#all_rows[@]}
echo "Portfolio: $total rows across ${#project_order[@]} project(s)  |  🟡 yellow: $yellow_count  |  🔴 red: $red_count"
echo ""

# ---------------------------------------------------------------------
# Finisher prompt
# ---------------------------------------------------------------------

if [[ -n "$finisher_file" ]]; then
  echo "FINISHER: '$finisher_file' is at ${finisher_completion}%, ~1 session from done."
  echo "          Project: $finisher_project"
  echo "          Close it before opening new work?"
  echo ""
fi

# ---------------------------------------------------------------------
# Focus locks
# ---------------------------------------------------------------------

if (( ${#focus_lines[@]} > 0 )); then
  echo "FOCUS LOCKS:"
  for line in "${focus_lines[@]}"; do
    IFS=$'\t' read -r fp fp_pulse fp_dir fp_marker <<< "$line"
    echo "  [$fp] focused on '$fp_pulse'$fp_marker"
    echo "        clear:  rm $fp_dir/.focus-lock"
    echo "        switch: echo NEW > $fp_dir/.focus-lock"
  done
  echo ""
else
  echo "FOCUS LOCKS: no active focus declared in any project"
  echo ""
fi
