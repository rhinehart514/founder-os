#!/usr/bin/env bash
# meta-score.sh — tracks scoring system integrity over time
# Usage:
#   meta-score.sh record <before> <after> <commit_hash>
#   meta-score.sh report [--json]

set -euo pipefail

DELTAS_FILE=".claude/cache/score-deltas.jsonl"

classify_commit() {
  local commit="$1"
  local diffstat
  diffstat=$(git diff --stat "$commit^" "$commit" 2>/dev/null || echo "")

  # Check if changes are only cosmetic (markdown, comments, formatting)
  local has_real=false
  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    # Skip the summary line (e.g. "3 files changed, 10 insertions...")
    [[ "$line" == *"files changed"* ]] && continue
    [[ "$line" == *"file changed"* ]] && continue

    local file
    file=$(echo "$line" | awk '{print $1}')

    # Cosmetic: .md files, .txt files, comments-only changes
    case "$file" in
      *.md|*.txt|*.yml|*.yaml|*.json)
        # Config/doc files are cosmetic unless they're founder.yml or beliefs
        case "$file" in
          *founder.yml|*beliefs.yml|*eval-cache*|*score-cache*)
            has_real=true
            ;;
        esac
        ;;
      *)
        has_real=true
        ;;
    esac
  done <<< "$diffstat"

  if $has_real; then
    echo "real"
  else
    echo "cosmetic"
  fi
}

cmd_record() {
  local before="$1"
  local after="$2"
  local commit="$3"
  local delta=$((after - before))
  local commit_type
  commit_type=$(classify_commit "$commit")
  local date
  date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")

  mkdir -p "$(dirname "$DELTAS_FILE")"

  echo "{\"date\":\"$date\",\"score_before\":$before,\"score_after\":$after,\"delta\":$delta,\"commit\":\"$commit\",\"commit_type\":\"$commit_type\"}" >> "$DELTAS_FILE"

  echo "Recorded: $before -> $after ($( [ $delta -ge 0 ] && echo "+")$delta, $commit_type)"
}

cmd_report() {
  local json_mode=false
  [[ "${1:-}" == "--json" ]] && json_mode=true

  if [[ ! -f "$DELTAS_FILE" ]]; then
    echo "No score deltas recorded yet. Use: meta-score.sh record <before> <after> <commit>"
    exit 0
  fi

  local total=0
  local real_count=0
  local cosmetic_count=0
  local real_delta=0
  local cosmetic_delta=0
  local total_delta=0

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    total=$((total + 1))

    local ctype delta
    # Parse commit_type and delta from JSON line
    ctype=$(echo "$line" | sed 's/.*"commit_type":"\([^"]*\)".*/\1/')
    delta=$(echo "$line" | sed 's/.*"delta":\(-*[0-9]*\).*/\1/')

    total_delta=$((total_delta + delta))

    if [[ "$ctype" == "real" ]]; then
      real_count=$((real_count + 1))
      real_delta=$((real_delta + delta))
    else
      cosmetic_count=$((cosmetic_count + 1))
      cosmetic_delta=$((cosmetic_delta + delta))
    fi
  done < "$DELTAS_FILE"

  if [[ $total -eq 0 ]]; then
    echo "No score deltas recorded yet."
    exit 0
  fi

  local integrity=0
  if [[ $total -gt 0 ]]; then
    integrity=$(( (real_count * 100) / total ))
  fi

  # Compute trend from first half vs second half
  local half=$(( total / 2 ))
  local first_real=0 first_total=0
  local second_real=0 second_total=0
  local count=0

  while IFS= read -r line; do
    [[ -z "$line" ]] && continue
    count=$((count + 1))
    local ctype
    ctype=$(echo "$line" | sed 's/.*"commit_type":"\([^"]*\)".*/\1/')

    if [[ $count -le $half ]]; then
      first_total=$((first_total + 1))
      [[ "$ctype" == "real" ]] && first_real=$((first_real + 1))
    else
      second_total=$((second_total + 1))
      [[ "$ctype" == "real" ]] && second_real=$((second_real + 1))
    fi
  done < "$DELTAS_FILE"

  local first_pct=0 second_pct=0 trend="stable"
  if [[ $first_total -gt 0 ]]; then
    first_pct=$(( (first_real * 100) / first_total ))
  fi
  if [[ $second_total -gt 0 ]]; then
    second_pct=$(( (second_real * 100) / second_total ))
  fi

  if [[ $((second_pct - first_pct)) -gt 10 ]]; then
    trend="improving"
  elif [[ $((first_pct - second_pct)) -gt 10 ]]; then
    trend="degrading"
  fi

  if $json_mode; then
    cat <<ENDJSON
{"integrity":$integrity,"total":$total,"real":$real_count,"cosmetic":$cosmetic_count,"real_delta":$real_delta,"cosmetic_delta":$cosmetic_delta,"trend":"$trend","first_half_pct":$first_pct,"second_half_pct":$second_pct}
ENDJSON
  else
    echo "Score Integrity: ${integrity}%"
    echo "  $total total score changes · $real_count from real improvements · $cosmetic_count cosmetic"
    if [[ $total -ge 4 ]]; then
      echo "  trend: $trend (was ${first_pct}% -> ${second_pct}%)"
    else
      echo "  trend: insufficient data (need 4+ entries)"
    fi
  fi
}

# Main dispatch
action="${1:-}"
shift || true

case "$action" in
  record)
    if [[ $# -lt 3 ]]; then
      echo "Usage: meta-score.sh record <before> <after> <commit_hash>"
      exit 1
    fi
    cmd_record "$1" "$2" "$3"
    ;;
  report)
    cmd_report "${1:-}"
    ;;
  *)
    echo "Usage: meta-score.sh <record|report> [args]"
    echo "  record <before> <after> <commit_hash>  — log a score change"
    echo "  report [--json]                         — show integrity report"
    exit 1
    ;;
esac
