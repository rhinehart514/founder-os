#!/bin/bash
# founder-os session end — reminder to grade predictions + vault sync
set -euo pipefail

# Resolve FOUNDER_DIR
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    FOUNDER_DIR="$CLAUDE_PLUGIN_ROOT"
else
    _SOURCE="${BASH_SOURCE[0]}"
    while [[ -L "$_SOURCE" ]]; do _SOURCE="$(readlink "$_SOURCE")"; done
    _DIR="$(cd "$(dirname "$_SOURCE")" && pwd)"
    FOUNDER_DIR="$(cd "$_DIR/.." && pwd)"
fi

PREDICTIONS="$HOME/.claude/knowledge/predictions.tsv"

if [[ -f "$PREDICTIONS" ]]; then
  ungraded=$(tail -n +2 "$PREDICTIONS" | awk -F'\t' '$5 == ""' | wc -l | tr -d ' ')
  if [[ $ungraded -gt 0 ]]; then
    echo "  ${ungraded} ungraded predictions. Run /retro next session."
  fi
fi

# Vault sync (async — catches early exits before session_end fires)
[[ -f "$FOUNDER_DIR/bin/vault-sync.sh" ]] && bash "$FOUNDER_DIR/bin/vault-sync.sh" "$(pwd)" &>/dev/null &
