#!/bin/bash
# founder-os session end — reminder to grade predictions
set -euo pipefail

PREDICTIONS="$HOME/.claude/knowledge/predictions.tsv"

if [[ -f "$PREDICTIONS" ]]; then
  ungraded=$(tail -n +2 "$PREDICTIONS" | awk -F'\t' '$5 == ""' | wc -l | tr -d ' ')
  if [[ $ungraded -gt 0 ]]; then
    echo "  ${ungraded} ungraded predictions. Run /retro next session."
  fi
fi
