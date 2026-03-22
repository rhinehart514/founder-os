#!/usr/bin/env bash
# Show what changed in assertions since last eval run
# Compares current beliefs.yml against cached state to find: new, removed, newly passing, newly failing
set -euo pipefail

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

BELIEFS=""
for bf in "$PROJECT_DIR/lens/product/eval/beliefs.yml" "$PROJECT_DIR/config/evals/beliefs.yml"; do
    [[ -f "$bf" ]] && BELIEFS="$bf" && break
done

CACHE_DIR="$PROJECT_DIR/.claude/cache"
SNAPSHOT="$CACHE_DIR/assertion-snapshot.txt"
HISTORY="$PROJECT_DIR/.claude/evals/assertion-history.tsv"

echo "── assertion diff ──"

if [[ -z "$BELIEFS" ]]; then
    echo "  no beliefs.yml found"
    exit 0
fi

# Current assertion IDs
CURRENT_IDS=$(grep '^\s*- id:' "$BELIEFS" | sed 's/.*- id: *//' | sort)
CURRENT_COUNT=$(echo "$CURRENT_IDS" | grep -c . 2>/dev/null || echo "0")

# --- Compare against snapshot ---
if [[ -f "$SNAPSHOT" ]]; then
    PREV_IDS=$(sort "$SNAPSHOT")

    # New assertions (in current, not in snapshot)
    NEW=$(comm -23 <(echo "$CURRENT_IDS") <(echo "$PREV_IDS"))
    # Removed assertions (in snapshot, not in current)
    REMOVED=$(comm -13 <(echo "$CURRENT_IDS") <(echo "$PREV_IDS"))

    NEW_COUNT=$(echo "$NEW" | grep -c . 2>/dev/null || echo "0")
    REMOVED_COUNT=$(echo "$REMOVED" | grep -c . 2>/dev/null || echo "0")

    echo "  since last snapshot:"
    echo ""

    if [[ "$NEW_COUNT" -gt 0 ]]; then
        echo "  ▸ new ($NEW_COUNT):"
        echo "$NEW" | while read -r id; do
            [[ -z "$id" ]] && continue
            FEAT=$(grep -A5 "id: $id" "$BELIEFS" 2>/dev/null | grep "feature:" | head -1 | sed 's/.*feature: *//' || echo "?")
            TYPE=$(grep -A5 "id: $id" "$BELIEFS" 2>/dev/null | grep "type:" | head -1 | sed 's/.*type: *//' || echo "?")
            echo "    + $id ($FEAT, $TYPE)"
        done
    fi

    if [[ "$REMOVED_COUNT" -gt 0 ]]; then
        echo "  ▸ removed ($REMOVED_COUNT):"
        echo "$REMOVED" | while read -r id; do
            [[ -z "$id" ]] && continue
            echo "    - $id"
        done
    fi

    if [[ "$NEW_COUNT" -eq 0 && "$REMOVED_COUNT" -eq 0 ]]; then
        echo "  ✓ no assertions added or removed"
    fi
else
    echo "  no previous snapshot — this is the first run"
    echo "  current: $CURRENT_COUNT assertions"
fi

# --- Check pass/fail changes from history ---
if [[ -f "$HISTORY" ]]; then
    echo ""
    # Get the two most recent run dates (skip header row)
    RUN_DATES=$(tail -n +2 "$HISTORY" | cut -f1 | sort -u | tail -2)
    DATE_COUNT=$(echo "$RUN_DATES" | grep -c . 2>/dev/null || echo "0")

    if [[ "$DATE_COUNT" -ge 2 ]]; then
        PREV_DATE=$(echo "$RUN_DATES" | head -1)
        CURR_DATE=$(echo "$RUN_DATES" | tail -1)

        echo "  pass/fail changes ($PREV_DATE → $CURR_DATE):"
        echo ""

        # Newly passing (was FAIL, now PASS) — history uses assertion_id in field 3
        PREV_FAILS=$(grep "^$PREV_DATE" "$HISTORY" | grep -i "FAIL" | cut -f3 | sort)
        CURR_PASSES=$(grep "^$CURR_DATE" "$HISTORY" | grep -i "PASS" | cut -f3 | sort)
        NEWLY_PASSING=$(comm -12 <(echo "$PREV_FAILS") <(echo "$CURR_PASSES"))

        if [[ -n "$NEWLY_PASSING" ]]; then
            NP_COUNT=$(echo "$NEWLY_PASSING" | grep -c . 2>/dev/null || echo "0")
            echo "  ✓ newly passing ($NP_COUNT):"
            echo "$NEWLY_PASSING" | while read -r id; do
                [[ -z "$id" ]] && continue
                echo "    ✓ $id"
            done
        fi

        # Newly failing (was PASS, now FAIL)
        PREV_PASSES=$(grep "^$PREV_DATE" "$HISTORY" | grep -i "PASS" | cut -f3 | sort)
        CURR_FAILS=$(grep "^$CURR_DATE" "$HISTORY" | grep -i "FAIL" | cut -f3 | sort)
        NEWLY_FAILING=$(comm -12 <(echo "$PREV_PASSES") <(echo "$CURR_FAILS"))

        if [[ -n "$NEWLY_FAILING" ]]; then
            NF_COUNT=$(echo "$NEWLY_FAILING" | grep -c . 2>/dev/null || echo "0")
            echo "  ✗ newly failing ($NF_COUNT):"
            echo "$NEWLY_FAILING" | while read -r id; do
                [[ -z "$id" ]] && continue
                echo "    ✗ $id"
            done
        fi

        if [[ -z "$NEWLY_PASSING" && -z "$NEWLY_FAILING" ]]; then
            echo "  · no status changes between runs"
        fi
    else
        echo "  only 1 eval run in history — need 2+ for diff"
    fi
else
    echo ""
    echo "  no assertion history — run /eval twice for pass/fail diff"
fi

# --- Save current snapshot for next diff ---
mkdir -p "$CACHE_DIR"
echo "$CURRENT_IDS" > "$SNAPSHOT"
echo ""
echo "  snapshot saved ($CURRENT_COUNT ids)"
