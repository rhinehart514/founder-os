#!/usr/bin/env bash
# skill-catalog.sh — Lists all installed skills with file counts and descriptions.
# Powers /founder help. Outputs structured data for the agent to render.
#
# Usage: bash skills/founder/scripts/skill-catalog.sh
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FOUNDER_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
SKILLS_DIR="$FOUNDER_DIR/skills"

echo "=== QUICK START ==="
echo ""
echo "  New project?"
echo "    /onboard → /plan → /go"
echo "    Sets up config, finds the bottleneck, builds autonomously."
echo ""
echo "  Existing project?"
echo "    /eval → /plan → /go"
echo "    Scores every feature, picks the weakest, fixes it."
echo ""
echo "  Just exploring?"
echo "    /decide → /research → /plan"
echo "    Brainstorm ideas, gather evidence, then decide what to build."
echo ""
echo "=== SKILL CATALOG ==="

# Count totals
SKILL_CT=0
SCRIPT_CT=0
REF_CT=0
TEMPLATE_CT=0

for SKILL_FILE in "$SKILLS_DIR"/*/SKILL.md; do
    [[ -f "$SKILL_FILE" ]] || continue
    SKILL_CT=$((SKILL_CT + 1))
    SKILL_DIR="$(dirname "$SKILL_FILE")"
    SKILL_NAME="$(basename "$SKILL_DIR")"

    # Extract description and argument-hint from frontmatter
    DESC=$(awk '/^---/{n++; next} n==1 && /^description:/{gsub(/^description: *"?/,""); gsub(/"$/,""); print; exit}' "$SKILL_FILE" 2>/dev/null)
    HINT=$(awk '/^---/{n++; next} n==1 && /^argument-hint:/{gsub(/^argument-hint: *"?/,""); gsub(/"$/,""); print; exit}' "$SKILL_FILE" 2>/dev/null)

    # Count folder contents
    SCRIPTS=$(find "$SKILL_DIR/scripts" -type f 2>/dev/null | wc -l | tr -d ' ')
    REFS=$(find "$SKILL_DIR/references" -type f 2>/dev/null | wc -l | tr -d ' ')
    TEMPLATES=$(find "$SKILL_DIR/templates" -type f 2>/dev/null | wc -l | tr -d ' ')
    TECHNIQUES=$(find "$SKILL_DIR/techniques" -type f 2>/dev/null | wc -l | tr -d ' ')
    HAS_GOTCHAS="no"
    [[ -f "$SKILL_DIR/gotchas.md" ]] && HAS_GOTCHAS="yes"

    SCRIPT_CT=$((SCRIPT_CT + SCRIPTS))
    REF_CT=$((REF_CT + REFS))
    TEMPLATE_CT=$((TEMPLATE_CT + TEMPLATES))

    # Build file count summary
    FILES=""
    if [[ "$SCRIPTS" -gt 0 ]]; then FILES="${FILES}${SCRIPTS}s "; fi
    if [[ "$REFS" -gt 0 ]]; then FILES="${FILES}${REFS}r "; fi
    if [[ "$TEMPLATES" -gt 0 ]]; then FILES="${FILES}${TEMPLATES}t "; fi
    if [[ "$TECHNIQUES" -gt 0 ]]; then FILES="${FILES}${TECHNIQUES}tech "; fi
    if [[ "$HAS_GOTCHAS" == "yes" ]]; then FILES="${FILES}gotchas "; fi
    FILES="${FILES:-bare }"

    if [[ -n "$HINT" ]]; then
        echo "SKILL: /$SKILL_NAME $HINT | files: ${FILES}| $DESC"
    else
        echo "SKILL: /$SKILL_NAME | files: ${FILES}| $DESC"
    fi
done

echo ""
echo "=== TOTALS ==="
echo "skills: $SKILL_CT"
echo "scripts: $SCRIPT_CT"
echo "references: $REF_CT"
echo "templates: $TEMPLATE_CT"
echo ""

# Agent count
AGENTS_DIR="$FOUNDER_DIR/agents"
if [[ -d "$AGENTS_DIR" ]]; then
    AGENT_CT=$(find "$AGENTS_DIR" -name "*.md" -maxdepth 1 2>/dev/null | wc -l | tr -d ' ')
    echo "agents: $AGENT_CT"
    echo ""
    echo "=== AGENTS ==="
    for AGENT_FILE in "$AGENTS_DIR"/*.md; do
        [[ -f "$AGENT_FILE" ]] || continue
        AGENT_NAME="$(basename "$AGENT_FILE" .md)"
        # Extract model from frontmatter
        MODEL=$(awk '/^---/{n++; next} n==1 && /^model:/{gsub(/^model: */,""); print; exit}' "$AGENT_FILE" 2>/dev/null || echo "?")
        echo "AGENT: $AGENT_NAME | model: $MODEL"
    done
fi

echo ""
echo "=== CATALOG COMPLETE ==="
