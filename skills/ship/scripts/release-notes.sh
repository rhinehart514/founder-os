#!/usr/bin/env bash
# Generate release notes from git log + roadmap.yml + eval-cache deltas
# Usage: release-notes.sh [tag] [--since tag|commit]
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
TAG="${1:-}"
SINCE=""

shift || true
while [[ $# -gt 0 ]]; do
    case "$1" in
        --since) SINCE="$2"; shift 2 ;;
        *)       shift ;;
    esac
done

echo "── release notes ──"

# 1. Determine version and range
ROADMAP="$PROJECT_DIR/.claude/plans/roadmap.yml"
VERSION=""
THESIS=""

if [[ -f "$ROADMAP" ]] && command -v grep &>/dev/null; then
    VERSION=$(grep -E '^\s*version:' "$ROADMAP" | head -1 | awk '{print $2}' | tr -d '"' || echo "")
    THESIS=$(grep -E '^\s*thesis:' "$ROADMAP" | head -1 | sed 's/.*thesis:\s*//' | tr -d '"' || echo "")
fi

if [[ -n "$TAG" ]]; then
    VERSION="$TAG"
fi

if [[ -z "$VERSION" ]]; then
    VERSION=$(git -C "$PROJECT_DIR" describe --tags --abbrev=0 2>/dev/null || echo "unreleased")
fi

echo "  version: $VERSION"
if [[ -n "$THESIS" ]]; then
    echo "  thesis: $THESIS"
fi

# 2. Determine git range
if [[ -n "$SINCE" ]]; then
    RANGE="$SINCE..HEAD"
elif git -C "$PROJECT_DIR" describe --tags --abbrev=0 HEAD^ &>/dev/null 2>&1; then
    PREV_TAG=$(git -C "$PROJECT_DIR" describe --tags --abbrev=0 HEAD^ 2>/dev/null)
    RANGE="$PREV_TAG..HEAD"
else
    # No previous tag — use last 20 commits
    RANGE="HEAD~20..HEAD"
fi

echo "  range: $RANGE"
echo ""

# 3. Categorized commits
echo "## $VERSION"
if [[ -n "$THESIS" ]]; then
    echo ""
    echo "$THESIS"
fi
echo ""

echo "### What's new"
git -C "$PROJECT_DIR" log "$RANGE" --oneline --no-merges 2>/dev/null | while IFS= read -r line; do
    HASH=$(echo "$line" | awk '{print $1}')
    MSG=$(echo "$line" | cut -d' ' -f2-)

    # Categorize by conventional commit prefix
    case "$MSG" in
        feat:*|feat\(*) echo "- ${MSG}" ;;
    esac
done

echo ""
echo "### Improvements"
git -C "$PROJECT_DIR" log "$RANGE" --oneline --no-merges 2>/dev/null | while IFS= read -r line; do
    MSG=$(echo "$line" | cut -d' ' -f2-)
    case "$MSG" in
        fix:*|fix\(*)       echo "- ${MSG}" ;;
        refactor:*|chore:*) echo "- ${MSG}" ;;
    esac
done

# 4. Eval-cache deltas (if available)
EVAL_CACHE="$PROJECT_DIR/.claude/cache/eval-cache.json"
if [[ -f "$EVAL_CACHE" ]] && command -v jq &>/dev/null; then
    echo ""
    echo "### Feature scores"
    jq -r 'to_entries[] | "- \(.key): \(.value.score // "–")/100"' "$EVAL_CACHE" 2>/dev/null
fi

# 5. Known limitations from roadmap
if [[ -f "$ROADMAP" ]]; then
    # Extract unproven evidence items as limitations
    UNPROVEN=$(grep -A1 'status:.*unproven\|status:.*testing' "$ROADMAP" 2>/dev/null | grep -v 'status:' | grep -v '^--$' | sed 's/^\s*-\s*//' | head -5)
    if [[ -n "$UNPROVEN" ]]; then
        echo ""
        echo "### Known limitations"
        echo "$UNPROVEN" | while IFS= read -r line; do
            [[ -n "$line" ]] && echo "- $line"
        done
    fi
fi

echo ""
echo "---"
echo "  generated from: git log + roadmap.yml + eval-cache"
echo "  edit before publishing — every bullet should trace to evidence"
