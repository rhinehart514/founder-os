#!/usr/bin/env bash
# first-run-detect.sh — detect if this is a new/first-run project
# Returns via stdout: "first_run" or "returning"
# Criteria for first_run (ALL must be true):
#   - No eval-cache.json OR eval-cache.json has no features
#   - No beliefs.yml OR beliefs.yml has 0 entries
#   - No predictions.tsv or < 3 predictions

PROJECT_DIR="${1:-.}"

has_eval=false
has_beliefs=false
has_predictions=false

# Check eval-cache
eval_file="$PROJECT_DIR/.claude/cache/eval-cache.json"
if [[ -f "$eval_file" ]]; then
  feature_count=$(jq 'keys | length' "$eval_file" 2>/dev/null || echo "0")
  [[ "$feature_count" -gt 0 ]] 2>/dev/null && has_eval=true
fi

# Check beliefs
beliefs_file="$PROJECT_DIR/lens/product/eval/beliefs.yml"
if [[ -f "$beliefs_file" ]]; then
  # Count non-comment, non-empty lines after the header
  entry_count=$(grep -c '^\s*- ' "$beliefs_file" 2>/dev/null || echo "0")
  [[ "$entry_count" -gt 0 ]] && has_beliefs=true
fi

# Check predictions (project-local only — global predictions reflect the operator, not the project)
pred_file="$PROJECT_DIR/.claude/knowledge/predictions.tsv"
if [[ -f "$pred_file" ]]; then
  # Subtract 1 for header line
  line_count=$(wc -l < "$pred_file" | tr -d ' ')
  pred_count=$((line_count - 1))
  [[ "$pred_count" -ge 3 ]] && has_predictions=true
fi

# First run = none of the three signals present
if $has_eval || $has_beliefs || $has_predictions; then
  echo "returning"
else
  echo "first_run"
fi
