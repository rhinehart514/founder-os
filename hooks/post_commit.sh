#!/usr/bin/env bash
# post_commit.sh — Score diff after git commit.
# Hook: PostToolUse (matcher: Bash). Target: <200ms.
# Runs quick health score, compares to last cached score, shows delta.

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# Read hook input from stdin
INPUT=$(cat)

# Extract the command from hook input JSON
COMMAND=$(echo "$INPUT" | grep -o '"input"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/"input"[[:space:]]*:[[:space:]]*"//;s/"$//' 2>/dev/null || true)

# Only act on git commit (not amend)
if echo "$COMMAND" | grep -q 'git commit' 2>/dev/null; then
    if echo "$COMMAND" | grep -q '\-\-amend' 2>/dev/null; then
        exit 0
    fi

    CACHE_FILE=".claude/cache/score-cache.json"
    HASH=$(git rev-parse --short HEAD 2>/dev/null || echo "???")

    # Capture previous score before clearing cache
    PREV_SCORE=""
    if [[ -f "$CACHE_FILE" ]] && command -v jq &>/dev/null; then
        PREV_SCORE=$(jq -r '.score // ""' "$CACHE_FILE" 2>/dev/null || true)
    fi

    # Clear stale cache
    rm -f "$CACHE_FILE"

    # Resolve FOUNDER_DIR for score.sh
    FOUNDER_DIR=""
    if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
        FOUNDER_DIR="$CLAUDE_PLUGIN_ROOT"
    else
        _PC_SOURCE="${BASH_SOURCE[0]}"
        while [[ -L "$_PC_SOURCE" ]]; do _PC_SOURCE="$(readlink "$_PC_SOURCE")"; done
        _PC_DIR="$(cd "$(dirname "$_PC_SOURCE")" && pwd)"
        FOUNDER_DIR="$(cd "$_PC_DIR/.." && pwd)"
    fi

    # Run quick score (no LLM, fast path)
    NEW_SCORE=""
    if [[ -f "$FOUNDER_DIR/bin/score.sh" ]]; then
        NEW_SCORE=$(bash "$FOUNDER_DIR/bin/score.sh" . --quiet 2>/dev/null || true)
    fi

    # Build output
    if [[ -n "$NEW_SCORE" && "$NEW_SCORE" =~ ^[0-9]+$ && -n "$PREV_SCORE" && "$PREV_SCORE" =~ ^[0-9]+$ ]]; then
        DELTA=$((NEW_SCORE - PREV_SCORE))
        if [[ $DELTA -gt 5 ]]; then
            echo -e "${GREEN}✓${NC} committed ${BOLD}$HASH${NC}  score ${PREV_SCORE}→${GREEN}${NEW_SCORE}${NC} ${GREEN}(+${DELTA})${NC}"
        elif [[ $DELTA -lt -5 ]]; then
            ABS_DELTA=$(( -DELTA ))
            echo -e "${YELLOW}✓${NC} committed ${BOLD}$HASH${NC}  score ${PREV_SCORE}→${RED}${NEW_SCORE}${NC} ${RED}(-${ABS_DELTA})${NC}"
            # Check for assertion regressions
            if [[ -f "$CACHE_FILE" ]] && command -v jq &>/dev/null; then
                PREV_PASS=$(jq -r '.assertion_pass_count // 0' "$CACHE_FILE" 2>/dev/null || echo "0")
                # Re-read new cache (score.sh just wrote it)
                if [[ -f "$CACHE_FILE" ]]; then
                    NEW_PASS=$(jq -r '.assertion_pass_count // 0' "$CACHE_FILE" 2>/dev/null || echo "0")
                    if [[ "$NEW_PASS" -lt "$PREV_PASS" ]]; then
                        echo -e "  ${RED}●${NC} assertion regression: ${PREV_PASS}→${NEW_PASS} passing"
                    fi
                fi
            fi
        else
            echo -e "${GREEN}✓${NC} committed ${BOLD}$HASH${NC}  score ${NEW_SCORE} ${DIM}(${DELTA:+$([[ $DELTA -ge 0 ]] && echo "+")$DELTA})${NC}"
        fi
    elif [[ -n "$NEW_SCORE" && "$NEW_SCORE" =~ ^[0-9]+$ ]]; then
        echo -e "${GREEN}✓${NC} committed ${BOLD}$HASH${NC}  score ${NEW_SCORE}"
    else
        echo -e "${GREEN}✓${NC} committed ${BOLD}$HASH${NC} ${DIM}— score cache cleared${NC}"
    fi

    # Vault sync (async, non-blocking)
    [[ -f "$FOUNDER_DIR/bin/vault-sync.sh" ]] && bash "$FOUNDER_DIR/bin/vault-sync.sh" "$(pwd)" &>/dev/null &
fi
