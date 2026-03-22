#!/usr/bin/env bash
# config_change.sh — PostToolUse hook for Edit|Write on founder.yml
# Validates founder.yml edits: stage, mode, thresholds.
# Target: <50ms (pure validation, no external calls).

set -euo pipefail

INPUT=$(cat)

# --- Parse file path from input JSON ---
FILE_PATH=""
if command -v jq &>/dev/null; then
    FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // ""' 2>/dev/null || echo "")
else
    FILE_PATH=$(echo "$INPUT" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/"file_path"[[:space:]]*:[[:space:]]*"//;s/"$//' 2>/dev/null || echo "")
fi

# Only validate founder.yml
if [[ "$FILE_PATH" != *"founder.yml"* ]]; then
    exit 0
fi

[[ ! -f "$FILE_PATH" ]] && exit 0

# Colors
C_RED='\033[0;31m'
C_YELLOW='\033[1;33m'
C_GREEN='\033[0;32m'
C_DIM='\033[2m'
C_NC='\033[0m'

WARNINGS=""

# --- Validate stage (may be indented under project:) ---
STAGE=$(grep -m1 '^\s*stage:' "$FILE_PATH" 2>/dev/null | sed 's/.*stage: *//' | sed 's/#.*//' | tr -d ' ' || true)
if [[ -n "$STAGE" ]]; then
    case "$STAGE" in
        mvp|early|growth|mature) ;;
        *)
            WARNINGS+="${C_RED}●${C_NC} Invalid stage: \"${STAGE}\" — must be mvp|early|growth|mature\n"
            ;;
    esac
fi

# --- Validate mode (may be indented under project:) ---
MODE=$(grep -m1 '^\s*mode:' "$FILE_PATH" 2>/dev/null | sed 's/.*mode: *//' | sed 's/#.*//' | tr -d ' ' || true)
if [[ -n "$MODE" ]]; then
    case "$MODE" in
        build|ship) ;;
        *)
            WARNINGS+="${C_RED}●${C_NC} Invalid mode: \"${MODE}\" — must be build|ship\n"
            ;;
    esac
fi

# --- Validate numeric thresholds ---
validate_threshold() {
    local key="$1"
    local min="$2"
    local max="$3"
    local val
    val=$(grep -m1 "^\s*${key}:" "$FILE_PATH" 2>/dev/null | sed "s/.*${key}: *//" | sed 's/#.*//' | tr -d ' ' || true)
    if [[ -n "$val" ]]; then
        if ! [[ "$val" =~ ^[0-9]+(\.[0-9]+)?$ ]]; then
            WARNINGS+="${C_RED}●${C_NC} ${key}: \"${val}\" is not a number\n"
        elif awk "BEGIN { exit !($val < $min || $val > $max) }" 2>/dev/null; then
            WARNINGS+="${C_YELLOW}⚠${C_NC} ${key}: ${val} outside expected range [${min}-${max}]\n"
        fi
    fi
}

# Check actual threshold keys from founder.yml scoring section
validate_threshold "health_gate_threshold" 0 100
validate_threshold "health_warn_threshold" 0 100
validate_threshold "cache_ttl" 0 86400
validate_threshold "plateau_threshold" 1 20

# --- Output warnings ---
if [[ -n "$WARNINGS" ]]; then
    echo -e "${C_YELLOW}⚠${C_NC} ${C_DIM}founder.yml validation:${C_NC}"
    echo -e "$WARNINGS"
else
    echo -e "${C_GREEN}✓${C_NC} ${C_DIM}founder.yml valid${C_NC}"
fi

exit 0
