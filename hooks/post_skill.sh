#!/usr/bin/env bash
# post_skill.sh — PostToolUse hook for Edit/Write on skill output artifacts
# Validates schema of .claude/plans/ files after skills write them.
# Warns (never blocks). Must be fast (<200ms).

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

INPUT="$(cat)"
FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"

[[ -z "$FILE_PATH" ]] && exit 0
[[ ! -f "$FILE_PATH" ]] && exit 0

# Only validate skill output artifacts in .claude/plans/
[[ "$FILE_PATH" != *".claude/plans/"* ]] && exit 0

BASENAME="$(basename "$FILE_PATH")"
WARNINGS=""

case "$BASENAME" in
    plan.yml)
        # Check for tasks section with at least one entry
        if ! grep -q 'tasks:' "$FILE_PATH" 2>/dev/null; then
            WARNINGS+="${YELLOW}⚠${NC} plan.yml missing tasks: section\n"
        else
            task_count=$(grep -cE '^\s+-\s' "$FILE_PATH" 2>/dev/null || echo "0")
            if (( task_count == 0 )); then
                WARNINGS+="${YELLOW}⚠${NC} plan.yml has tasks: but no task entries\n"
            fi
        fi
        ;;

    strategy.yml)
        # Check for bottleneck field
        if ! grep -q 'bottleneck:' "$FILE_PATH" 2>/dev/null; then
            WARNINGS+="${YELLOW}⚠${NC} strategy.yml missing bottleneck: field — /plan can't find the constraint\n"
        fi
        ;;
esac

if [[ -n "$WARNINGS" ]]; then
    echo -e "$WARNINGS"
fi

exit 0
