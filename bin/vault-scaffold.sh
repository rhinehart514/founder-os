#!/usr/bin/env bash
# vault-scaffold.sh — Create an Obsidian vault optimized for founder-os
# Usage: bash bin/vault-scaffold.sh [vault-path]
# Idempotent — safe to re-run.
set -euo pipefail

VAULT_PATH="${1:-$HOME/obsidian-vault}"

echo "Scaffolding Obsidian vault at: $VAULT_PATH"

# Create directory structure
mkdir -p "$VAULT_PATH/Logs"
mkdir -p "$VAULT_PATH/Commonplace"
mkdir -p "$VAULT_PATH/Projects"
mkdir -p "$VAULT_PATH/Outputs"
mkdir -p "$VAULT_PATH/founder-os/sessions"
mkdir -p "$VAULT_PATH/Templates"
mkdir -p "$VAULT_PATH/Utilities"

# Minimal .obsidian config (only if not already initialized)
OBSIDIAN_DIR="$VAULT_PATH/.obsidian"
if [[ ! -d "$OBSIDIAN_DIR" ]]; then
    mkdir -p "$OBSIDIAN_DIR"
    cat > "$OBSIDIAN_DIR/app.json" << 'EOF'
{
  "showLineNumber": true,
  "strictLineBreaks": false,
  "readableLineLength": true
}
EOF
fi

# Daily note template
if [[ ! -f "$VAULT_PATH/Templates/Daily.md" ]]; then
    cat > "$VAULT_PATH/Templates/Daily.md" << 'EOF'
# {{date}}

## Plan
- [ ]

## Notes


## End of Day
- Score delta:
- Key learning:
EOF
fi

# Vault README
if [[ ! -f "$VAULT_PATH/README.md" ]]; then
    cat > "$VAULT_PATH/README.md" << 'EOF'
# Knowledge Vault

## Structure
- **Logs/** — Daily notes, scratchpad, session logs
- **Commonplace/** — Atomic notes (one idea per note)
- **Projects/** — Per-project research and strategy
- **Outputs/** — Content for sharing (copy, pitches, docs)
- **founder-os/** — Auto-synced from founder-os (read-only for humans)
- **Templates/** — Note templates
- **Utilities/** — Images, canvases, people

## founder-os/ (auto-generated)
Files in `founder-os/` are synced automatically at the end of each Claude Code session.
Do not edit them directly — they are overwritten on sync.

- `learnings.md` — Experiment learnings (known patterns, dead ends)
- `predictions.md` — Prediction log with grading
- `strategy.md` — Current strategic diagnosis
- `product-health.md` — Feature scores and product health
- `sessions/` — Per-session summaries
EOF
fi

echo "Vault scaffolded at: $VAULT_PATH"
echo "Folders: Logs, Commonplace, Projects, Outputs, founder-os, Templates, Utilities"
