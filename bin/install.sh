#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PKG_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

CLAUDE_DIR="$HOME/.claude"
SKILLS_DIR="$CLAUDE_DIR/skills"
AGENTS_DIR="$CLAUDE_DIR/agents"

echo "Installing multi-agent primitives into $CLAUDE_DIR..."
echo ""
echo "Note: For plugin mode, use: claude plugin install rhinehart514/founder-os"
echo ""

# Skills
mkdir -p "$SKILLS_DIR"
PRIMITIVES=(fanout model-chat stochastic skillbuilder autoresearch)
for skill in "${PRIMITIVES[@]}"; do
  rm -rf "$SKILLS_DIR/$skill"
done
cp -r "$PKG_ROOT/skills/"* "$SKILLS_DIR/" 2>/dev/null || true
echo "  Skills: ${#PRIMITIVES[@]} installed (${PRIMITIVES[*]})"

# Agents
mkdir -p "$AGENTS_DIR"
AGENTS=(parent.md qa.md researcher.md)
for agent in "${AGENTS[@]}"; do
  cp "$PKG_ROOT/agents/$agent" "$AGENTS_DIR/" 2>/dev/null || true
done
echo "  Agents: ${#AGENTS[@]} installed (parent, qa, researcher)"

echo ""
echo "Done. Restart Claude Code to load skills."
echo ""
echo "  /stochastic    — poll N agents, aggregate consensus"
echo "  /model-chat    — multi-agent debate room"
echo "  /fanout        — parallel research, Opus synthesis"
echo "  /skillbuilder  — generate new leverage skills"
echo "  /autoresearch  — hill-climb optimization loop"
