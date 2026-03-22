#!/usr/bin/env bash
# pre_commit_check.sh — Safety gate before git commit.
# Hook: PreToolUse (matcher: Bash). Target: <50ms.
# The ONLY hook that blocks. Checks for secrets, eval harness mods, shell syntax.

set -euo pipefail

# Read hook input from stdin
INPUT=$(cat)

# Extract the command from hook input JSON
COMMAND=$(echo "$INPUT" | grep -o '"input"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/"input"[[:space:]]*:[[:space:]]*"//;s/"$//' 2>/dev/null || true)

# Only act on git commit commands
if ! echo "$COMMAND" | grep -q 'git commit' 2>/dev/null; then
    echo '{"decision": "allow"}'
    exit 0
fi

# Check staged files for secrets
STAGED=$(git diff --cached --name-only 2>/dev/null || true)
if [[ -z "$STAGED" ]]; then
    echo '{"decision": "allow"}'
    exit 0
fi

# Secret patterns check
SECRETS_FOUND=""
for file in $STAGED; do
    [[ ! -f "$file" ]] && continue
    if grep -qE '(sk-[a-zA-Z0-9]{20,}|AKIA[A-Z0-9]{16}|ghp_[a-zA-Z0-9]{36})' "$file" 2>/dev/null; then
        SECRETS_FOUND="$SECRETS_FOUND $file"
    fi
done

if [[ -n "$SECRETS_FOUND" ]]; then
    echo "{\"decision\": \"block\", \"reason\": \"Potential secrets detected in staged files:$SECRETS_FOUND\"}"
    exit 0
fi

# Check for eval harness modifications
HARNESS_FILES="bin/score.sh bin/eval.sh lens/product/eval/taste.mjs skills/taste/SKILL.md"
for harness in $HARNESS_FILES; do
    if echo "$STAGED" | grep -q "^${harness}$" 2>/dev/null; then
        echo "{\"decision\": \"block\", \"reason\": \"Eval harness file staged: $harness — these are immutable during builds\"}"
        exit 0
    fi
done

# Check shell syntax on staged .sh files
for file in $STAGED; do
    if [[ "$file" == *.sh && -f "$file" ]]; then
        if ! bash -n "$file" 2>/dev/null; then
            echo "{\"decision\": \"block\", \"reason\": \"Shell syntax error in $file\"}"
            exit 0
        fi
    fi
done

echo '{"decision": "allow"}'
