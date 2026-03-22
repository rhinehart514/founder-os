#!/usr/bin/env bash
# post_edit.sh — PostToolUse hook for Edit/Write
# Returns additionalContext JSON so Claude SEES warnings and self-corrects.
# Also detects product-quality gaps in new code (missing error/loading/empty states).
# Must be fast (<100ms). Slow checks (tsc) moved to post_edit_slow.sh.

INPUT="$(cat)"
TOOL_NAME="$(echo "$INPUT" | jq -r '.tool_name // empty' 2>/dev/null)"
FILE_PATH="$(echo "$INPUT" | jq -r '.tool_input.file_path // empty' 2>/dev/null)"

[[ -z "$FILE_PATH" ]] && exit 0
[[ ! -f "$FILE_PATH" ]] && exit 0

# Determine file extension
EXT="${FILE_PATH##*.}"
WARNINGS=()       # Array for Claude-visible warnings (RED — must fix)
HINTS=()          # Array for human-only hints (YELLOW — nice to fix)

# Colors (for human-visible stderr output)
RED='\033[0;31m'
YELLOW='\033[1;33m'
DIM='\033[2m'
NC='\033[0m'

# --- TypeScript / JavaScript checks ---
if [[ "$EXT" =~ ^(ts|tsx|js|jsx)$ ]]; then

    # console.log in non-test files
    if [[ "$FILE_PATH" != *test* && "$FILE_PATH" != *spec* && "$FILE_PATH" != *__test__* ]]; then
        console_count=$(grep -c 'console\.log' "$FILE_PATH" 2>/dev/null || echo "0")
        if (( console_count > 0 )); then
            HINTS+=("${console_count} console.log(s) in $(basename "$FILE_PATH") — remove before commit")
        fi
    fi

    # `: any` type annotations
    any_count=$(grep -c ': any' "$FILE_PATH" 2>/dev/null || echo "0")
    if (( any_count > 3 )); then
        HINTS+=("${any_count} \`: any\` types in $(basename "$FILE_PATH") — type these properly")
    fi

    # --- Diff-based product quality checks (new code patterns) ---
    # Check for React/Vue/Svelte component without error handling
    if [[ "$EXT" =~ ^(tsx|jsx)$ ]]; then
        FILE_CONTENT=$(cat "$FILE_PATH" 2>/dev/null)

        # New component with no loading state
        if echo "$FILE_CONTENT" | grep -qE '(fetch|axios|useQuery|useSWR|useEffect.*fetch|\.get\(|\.post\()' 2>/dev/null; then
            if ! echo "$FILE_CONTENT" | grep -qiE '(loading|isLoading|skeleton|spinner|Suspense|pending|fallback)' 2>/dev/null; then
                WARNINGS+=("$(basename "$FILE_PATH") fetches data but has no loading state — add a loading indicator")
            fi
        fi

        # New component with no error handling for async operations
        if echo "$FILE_CONTENT" | grep -qE '(fetch|axios|useQuery|useSWR|\.get\(|\.post\()' 2>/dev/null; then
            if ! echo "$FILE_CONTENT" | grep -qiE '(error|isError|onError|catch|ErrorBoundary|try)' 2>/dev/null; then
                WARNINGS+=("$(basename "$FILE_PATH") fetches data but has no error handling — add error state")
            fi
        fi

        # Empty return / placeholder component
        if echo "$FILE_CONTENT" | grep -qE 'return\s*(null|\(\s*\)|\(<>\s*</>)' 2>/dev/null; then
            WARNINGS+=("$(basename "$FILE_PATH") has an empty return — add content or a meaningful empty state")
        fi

        # New page/route with no navigation back
        if echo "$FILE_CONTENT" | grep -qiE '(Page|Screen|View|Route)' 2>/dev/null; then
            if ! echo "$FILE_CONTENT" | grep -qiE '(Link|navigate|router|back|href|<a )' 2>/dev/null; then
                HINTS+=("$(basename "$FILE_PATH") looks like a page but has no navigation links — possible dead end")
            fi
        fi

        # Form with no validation
        if echo "$FILE_CONTENT" | grep -qE '<form|onSubmit|handleSubmit' 2>/dev/null; then
            if ! echo "$FILE_CONTENT" | grep -qiE '(required|validate|validation|pattern=|minLength|maxLength|zod|yup|formik)' 2>/dev/null; then
                HINTS+=("$(basename "$FILE_PATH") has a form but no visible validation — consider adding input validation")
            fi
        fi
    fi
fi

# --- Python checks ---
if [[ "$EXT" == "py" ]]; then
    # Syntax check (fast)
    if command -v python3 &>/dev/null; then
        if ! PYFILE="$FILE_PATH" python3 -c "import ast, os; ast.parse(open(os.environ['PYFILE']).read())" 2>/dev/null; then
            WARNINGS+=("Python syntax error in $(basename "$FILE_PATH") — fix immediately")
        fi
    fi
fi

# --- Shell script checks ---
if [[ "$EXT" == "sh" || "$EXT" == "bash" ]]; then
    if ! bash -n "$FILE_PATH" 2>/dev/null; then
        WARNINGS+=("Shell syntax error in $(basename "$FILE_PATH") — fix immediately")
    fi
fi

# --- Universal checks ---
# Hardcoded secrets (basic patterns)
if grep -qE '(sk-[a-zA-Z0-9]{20,}|AKIA[A-Z0-9]{16}|ghp_[a-zA-Z0-9]{36})' "$FILE_PATH" 2>/dev/null; then
    WARNINGS+=("Possible hardcoded secret in $(basename "$FILE_PATH") — remove immediately")
fi

# --- Output ---
# Human-visible hints go to stderr (yellow warnings the user sees in terminal)
for hint in "${HINTS[@]}"; do
    echo -e "${YELLOW}⚠${NC} ${hint}" >&2
done

# Claude-visible warnings go to stdout as additionalContext JSON
# Only emit for RED warnings (things Claude should fix in the next turn)
if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    # Also show warnings to human on stderr
    for warn in "${WARNINGS[@]}"; do
        echo -e "${RED}●${NC} ${warn}" >&2
    done

    # Build additionalContext string for Claude
    CONTEXT="Post-edit quality check found issues that need fixing:"
    for warn in "${WARNINGS[@]}"; do
        CONTEXT="${CONTEXT}\n- ${warn}"
    done
    CONTEXT="${CONTEXT}\nFix these before continuing with other work."

    # Escape for JSON
    JSON_CONTEXT=$(printf '%s' "$CONTEXT" | python3 -c "import sys,json; print(json.dumps(sys.stdin.read()))" 2>/dev/null || printf '"%s"' "$CONTEXT")

    echo "{\"additionalContext\": ${JSON_CONTEXT}}"
fi

exit 0
