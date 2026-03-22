#!/usr/bin/env bash
# post_edit_slow.sh — Slow PostToolUse checks (TypeScript, etc.)
# Runs async — does not block Claude's response.
# Output goes to stderr (human only) since async hooks can't return additionalContext.

INPUT="$(cat)"
FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"

[[ -z "$FILE_PATH" ]] && exit 0
[[ ! -f "$FILE_PATH" ]] && exit 0

EXT="${FILE_PATH##*.}"

YELLOW='\033[1;33m'
NC='\033[0m'

# --- TypeScript check (can take 2-10s) ---
if [[ "$EXT" =~ ^(ts|tsx)$ ]]; then
    PROJECT_DIR="$(pwd)"
    if [[ -f "$PROJECT_DIR/tsconfig.json" ]] && command -v npx &>/dev/null; then
        ts_errors=$(cd "$PROJECT_DIR" && perl -e 'alarm 10; exec @ARGV' npx --yes tsc --noEmit --pretty false 2>&1 | grep -c "^${FILE_PATH}" 2>/dev/null || echo "0")
        if (( ts_errors > 0 )); then
            echo -e "${YELLOW}⚠${NC} ${ts_errors} TypeScript error(s) in $(basename "$FILE_PATH")" >&2
        fi
    fi
fi

# --- Python print() check (not a blocker, just a hint) ---
if [[ "$EXT" == "py" && "$FILE_PATH" != *test* ]]; then
    print_count=$(grep -cE '^\s*print\(' "$FILE_PATH" 2>/dev/null || echo "0")
    if (( print_count > 2 )); then
        echo -e "${YELLOW}⚠${NC} ${print_count} print() calls in $(basename "$FILE_PATH") — use logging instead" >&2
    fi
fi

exit 0
