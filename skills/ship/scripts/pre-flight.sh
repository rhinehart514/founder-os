#!/usr/bin/env bash
# Pre-flight check before shipping
# Checks: score regression, assertions, secrets, eval freshness, changelog, deploy confidence
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FOUNDER_DIR="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

echo "── pre-flight ──"
PASS=0
FAIL=0
WARN=0

# 1. Score check
SCORE_CACHE="$PROJECT_DIR/.claude/cache/score-cache.json"
if [[ -f "$SCORE_CACHE" ]] && command -v jq &>/dev/null; then
    SCORE=$(jq -r '.score // 0' "$SCORE_CACHE" 2>/dev/null)
    if [[ "$SCORE" -lt 30 ]]; then
        echo "  ✗ score: $SCORE (below 30 threshold)"
        FAIL=$((FAIL+1))
    else
        echo "  ✓ score: $SCORE"
        PASS=$((PASS+1))
    fi
else
    echo "  ⚠ no score cache — run \`founder score .\` first"
    WARN=$((WARN+1))
fi

# 2. Assertion check (eval)
EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
if [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
    # Check freshness — warn if older than 1 hour
    if command -v stat &>/dev/null; then
        if [[ "$(uname)" == "Darwin" ]]; then
            MTIME=$(stat -f %m "$EVAL_CACHE" 2>/dev/null || echo 0)
        else
            MTIME=$(stat -c %Y "$EVAL_CACHE" 2>/dev/null || echo 0)
        fi
        NOW=$(date +%s)
        AGE=$(( (NOW - MTIME) / 60 ))
        if [[ "$AGE" -gt 60 ]]; then
            echo "  ⚠ eval cache is ${AGE}min old — consider re-running \`/eval\`"
            WARN=$((WARN+1))
        else
            echo "  ✓ eval cache fresh (${AGE}min)"
            PASS=$((PASS+1))
        fi
    fi

    # Check for block-severity failures
    BLOCK_FAILS=$(jq -r '[to_entries[] | select(.value.score < 30)] | length' "$EVAL_CACHE" 2>/dev/null || echo 0)
    if [[ "$BLOCK_FAILS" -gt 0 ]]; then
        echo "  ✗ $BLOCK_FAILS features scoring below 30 (block threshold)"
        jq -r 'to_entries[] | select(.value.score < 30) | "    · \(.key): \(.value.score)"' "$EVAL_CACHE" 2>/dev/null
        FAIL=$((FAIL+1))
    else
        echo "  ✓ no block-severity eval failures"
        PASS=$((PASS+1))
    fi
else
    echo "  ⚠ no eval cache — run \`/eval\` for full pre-flight"
    WARN=$((WARN+1))
fi

# 3. Beliefs / assertions
BELIEFS_FILE="$PROJECT_DIR/config/beliefs.yml"
if [[ -f "$BELIEFS_FILE" ]]; then
    TOTAL=$(grep -c '^\s*- id:' "$BELIEFS_FILE" 2>/dev/null || echo 0)
    echo "  ✓ $TOTAL assertions defined"
    PASS=$((PASS+1))
else
    echo "  ⚠ no beliefs.yml — no assertions to check"
    WARN=$((WARN+1))
fi

# 4. Uncommitted changes
DIRTY=$(git -C "$PROJECT_DIR" status --porcelain 2>/dev/null | wc -l | tr -d ' ')
if [[ "$DIRTY" -gt 0 ]]; then
    echo "  ⚠ $DIRTY uncommitted files"
    WARN=$((WARN+1))
else
    echo "  ✓ clean working tree"
    PASS=$((PASS+1))
fi

# 5. Large changeset warning
CHANGED=$(git -C "$PROJECT_DIR" diff --stat HEAD 2>/dev/null | tail -1 | grep -oE '[0-9]+ file' | grep -oE '[0-9]+' || echo 0)
if [[ "$CHANGED" -gt 20 ]]; then
    echo "  ⚠ large changeset: $CHANGED files changed"
    WARN=$((WARN+1))
fi

# 6. Secret detection in staged diff
SECRETS=$(git -C "$PROJECT_DIR" diff --cached 2>/dev/null | grep -iE '(api_key|secret_key|password|token|credential|private_key).*=' | wc -l | tr -d ' ')
if [[ "$SECRETS" -gt 0 ]]; then
    echo "  ✗ $SECRETS potential secrets in staged diff"
    FAIL=$((FAIL+1))
else
    echo "  ✓ no secrets detected"
    PASS=$((PASS+1))
fi

# Also check unstaged diff for secrets
UNSTAGED_SECRETS=$(git -C "$PROJECT_DIR" diff 2>/dev/null | grep -iE '(api_key|secret_key|password|token|credential|private_key).*=' | wc -l | tr -d ' ')
if [[ "$UNSTAGED_SECRETS" -gt 0 ]]; then
    echo "  ⚠ $UNSTAGED_SECRETS potential secrets in unstaged changes"
    WARN=$((WARN+1))
fi

# 7. Changelog check
if [[ -f "$PROJECT_DIR/CHANGELOG.md" ]] || [[ -f "$PROJECT_DIR/.claude/cache/changelog.md" ]]; then
    echo "  ✓ changelog exists"
    PASS=$((PASS+1))
else
    echo "  ⚠ no changelog — run \`/ship changelog\` to generate"
    WARN=$((WARN+1))
fi

# 8. Deploy confidence
if [[ -f "$FOUNDER_DIR/bin/compute-deploy-confidence.sh" ]]; then
    CONFIDENCE=$("$FOUNDER_DIR/bin/compute-deploy-confidence.sh" 2>/dev/null | grep 'confidence:' | awk '{print $2}' || echo "")
    if [[ -n "$CONFIDENCE" && "$CONFIDENCE" -lt 50 ]]; then
        echo "  ✗ deploy confidence: ${CONFIDENCE}%"
        FAIL=$((FAIL+1))
    elif [[ -n "$CONFIDENCE" ]]; then
        echo "  ✓ deploy confidence: ${CONFIDENCE}%"
        PASS=$((PASS+1))
    fi
else
    echo "  · deploy confidence: not computed (no history)"
fi

# 9. Score regression since last deploy
DEPLOY_HISTORY="$PROJECT_DIR/.claude/cache/deploy-history.json"
if [[ -f "$DEPLOY_HISTORY" ]] && [[ -f "$SCORE_CACHE" ]] && command -v jq &>/dev/null; then
    LAST_SCORE=$(jq -r '.deploys[-1].score_after // empty' "$DEPLOY_HISTORY" 2>/dev/null || echo "")
    CURRENT_SCORE=$(jq -r '.score // 0' "$SCORE_CACHE" 2>/dev/null)
    if [[ -n "$LAST_SCORE" ]] && [[ "$CURRENT_SCORE" -lt "$LAST_SCORE" ]]; then
        echo "  ⚠ score regressed: $LAST_SCORE → $CURRENT_SCORE since last deploy"
        WARN=$((WARN+1))
    fi
fi

echo ""
echo "  result: $PASS pass · $FAIL fail · $WARN warn"
if [[ "$FAIL" -gt 0 ]]; then
    echo "  verdict: BLOCK"
    exit 1
elif [[ "$WARN" -gt 3 ]]; then
    echo "  verdict: WARN — multiple warnings, review before shipping"
    exit 0
else
    echo "  verdict: SHIP"
    exit 0
fi
