#!/usr/bin/env bash
# todo.test.sh — Tests for bin/todo.sh
# Run: bash bin/tests/todo.test.sh

set -euo pipefail

PASS=0
FAIL=0
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TODO_SH="$SCRIPT_DIR/todo.sh"

# ── Test helpers ─────────────────────────────────────────

assert_eq() {
    local name="$1" expected="$2" actual="$3"
    if [[ "$expected" == "$actual" ]]; then
        PASS=$((PASS + 1))
        echo "  PASS  $name"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL  $name"
        echo "        expected: '$expected'"
        echo "        actual:   '$actual'"
    fi
}

assert_contains() {
    local name="$1" needle="$2" haystack="$3"
    if echo "$haystack" | grep -q "$needle"; then
        PASS=$((PASS + 1))
        echo "  PASS  $name"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL  $name — '$needle' not found in output"
    fi
}

assert_not_contains() {
    local name="$1" needle="$2" haystack="$3"
    if ! echo "$haystack" | grep -q "$needle"; then
        PASS=$((PASS + 1))
        echo "  PASS  $name"
    else
        FAIL=$((FAIL + 1))
        echo "  FAIL  $name — '$needle' should NOT be in output"
    fi
}

assert_exit() {
    local name="$1" expected_code="$2"
    shift 2
    local actual_code=0
    "$@" >/dev/null 2>&1 || actual_code=$?
    assert_eq "$name" "$expected_code" "$actual_code"
}

# Create isolated temp workspace for each test
setup() {
    TEST_DIR=$(mktemp -d)
    mkdir -p "$TEST_DIR/.claude/plans"
    # Pre-create todos.yml so BACKLOG_FILE resolves to project dir (not founder-os fallback)
    cat > "$TEST_DIR/.claude/plans/todos.yml" << 'SEED'
# todos.yml — Persistent backlog

items:
SEED
    # Clean any stale lock
    rmdir /tmp/founder-todo.lock 2>/dev/null || true
}

teardown() {
    rm -rf "$TEST_DIR"
    rmdir /tmp/founder-todo.lock 2>/dev/null || true
}

# Run todo.sh in the test workspace
run_todo() {
    (cd "$TEST_DIR" && bash "$TODO_SH" "$@" 2>&1)
}

echo ""
echo "=== todo.sh unit tests ==="
echo ""

# ─── Test: add ──────────────────────────────────────────
echo "--- add ---"

setup
out=$(run_todo add "Fix the login bug" high)
assert_contains "add: success message" "Fix the login bug" "$out"
assert_contains "add: shows priority" "high" "$out"

# Verify YAML was created
assert_eq "add: file created" "true" "$([[ -f "$TEST_DIR/.claude/plans/todos.yml" ]] && echo true || echo false)"

# Verify content
content=$(cat "$TEST_DIR/.claude/plans/todos.yml")
assert_contains "add: has id" "id: fix-the-login-bug" "$content"
assert_contains "add: has title" 'title: "Fix the login bug"' "$content"
assert_contains "add: has priority" "priority: high" "$content"
assert_contains "add: has status" "status: backlog" "$content"
assert_contains "add: has created date" "created:" "$content"

# Add second item
run_todo add "Update docs" low >/dev/null
content2=$(cat "$TEST_DIR/.claude/plans/todos.yml")
assert_contains "add: second item exists" "id: update-docs" "$content2"
teardown
echo ""

# ─── Test: done ─────────────────────────────────────────
echo "--- done ---"

setup
run_todo add "Task to complete" >/dev/null
out=$(run_todo done "task-to-complete")
assert_contains "done: success" "done" "$out"

content=$(cat "$TEST_DIR/.claude/plans/todos.yml")
assert_contains "done: status updated" "status: done" "$content"
assert_contains "done: done_at set" "done_at:" "$content"

# done on missing item
out2=$(run_todo done "nonexistent" 2>&1 || true)
assert_contains "done: missing item error" "not found" "$out2"
teardown
echo ""

# ─── Test: tag ──────────────────────────────────────────
echo "--- tag ---"

setup
run_todo add "Needs tagging" >/dev/null
out=$(run_todo tag "needs-tagging" "scoring")
assert_contains "tag: success" "scoring" "$out"

content=$(cat "$TEST_DIR/.claude/plans/todos.yml")
assert_contains "tag: feature set" "feature: scoring" "$content"

# tag missing item
out2=$(run_todo tag "nonexistent" "feat" 2>&1 || true)
assert_contains "tag: missing item error" "not found" "$out2"
teardown
echo ""

# ─── Test: promote ──────────────────────────────────────
echo "--- promote ---"

setup
run_todo add "Promote me" >/dev/null
out=$(run_todo promote "promote-me")
assert_contains "promote: success" "active" "$out"

content=$(cat "$TEST_DIR/.claude/plans/todos.yml")
assert_contains "promote: status active" "status: active" "$content"
teardown
echo ""

# ─── Test: decay ────────────────────────────────────────
echo "--- decay ---"

setup
# Create a file with an old item (40 days ago)
old_date=$(date -j -v-40d '+%Y-%m-%d' 2>/dev/null || date -d '40 days ago' '+%Y-%m-%d' 2>/dev/null)
cat > "$TEST_DIR/.claude/plans/todos.yml" << EOF
# todos.yml — Persistent backlog

items:

  - id: old-item
    title: "Ancient task"
    priority: medium
    feature: ""
    status: backlog
    context: ""
    source: "manual"
    created: ${old_date}

  - id: fresh-item
    title: "New task"
    priority: medium
    feature: ""
    status: backlog
    context: ""
    source: "manual"
    created: $(date '+%Y-%m-%d')
EOF

out=$(run_todo decay)
assert_contains "decay: finds stale item" "Ancient task" "$out"
assert_contains "decay: shows age" "[0-9]\+d" "$out"
assert_not_contains "decay: fresh item not flagged" "New task" "$out"

# Verify auto-tag to stale
content=$(cat "$TEST_DIR/.claude/plans/todos.yml")
assert_contains "decay: auto-tagged stale" "status: stale" "$content"
teardown
echo ""

# ─── Test: health ───────────────────────────────────────
echo "--- health ---"

setup
# Build a backlog with mixed statuses and dates
today=$(date '+%Y-%m-%d')
week_ago=$(date -j -v-10d '+%Y-%m-%d' 2>/dev/null || date -d '10 days ago' '+%Y-%m-%d' 2>/dev/null)
cat > "$TEST_DIR/.claude/plans/todos.yml" << EOF
# todos.yml — Persistent backlog

items:

  - id: item-active
    title: "Active work"
    priority: high
    feature: "scoring"
    status: active
    context: ""
    source: "manual"
    created: ${today}

  - id: item-backlog
    title: "Queued work"
    priority: medium
    feature: "scoring"
    status: backlog
    context: ""
    source: "manual"
    created: ${week_ago}

  - id: item-done-1
    title: "Finished A"
    priority: low
    feature: "todo"
    status: done
    context: ""
    source: "manual"
    created: ${week_ago}
    done_at: ${today}

  - id: item-done-2
    title: "Finished B"
    priority: low
    feature: "todo"
    status: done
    context: ""
    source: "manual"
    created: ${week_ago}
    done_at: ${week_ago}
EOF

out=$(run_todo health)
assert_contains "health: shows total" "total" "$out"
assert_contains "health: shows active" "active" "$out"
assert_contains "health: shows done" "done" "$out"
assert_contains "health: shows completion" "completion" "$out"
assert_contains "health: shows age section" "age" "$out"
assert_contains "health: shows feature section" "by feature" "$out"
assert_contains "health: shows scoring feature" "scoring" "$out"
assert_contains "health: shows velocity section" "velocity" "$out"
assert_contains "health: shows items done" "2 items done" "$out"
teardown
echo ""

# ─── Test: import ───────────────────────────────────────
echo "--- import ---"

setup
out=$(echo '{"title":"imported task","priority":"high","feature":"ux","source":"/eval"}
{"title":"second import","feature":"scoring"}
{"title":""}
{"bad json' | run_todo import)
assert_contains "import: count" "imported 2" "$out"

content=$(cat "$TEST_DIR/.claude/plans/todos.yml")
assert_contains "import: first item" "id: imported-task" "$content"
assert_contains "import: first priority" "priority: high" "$content"
assert_contains "import: first feature" 'feature: "ux"' "$content"
assert_contains "import: first source" 'source: "/eval"' "$content"
assert_contains "import: second item" "id: second-import" "$content"

# Import again — duplicates should be skipped
out2=$(echo '{"title":"imported task"}
{"title":"brand new"}' | run_todo import)
assert_contains "import: dedup skipped" "skipped 1" "$out2"
assert_contains "import: new item added" "imported 1" "$out2"
teardown
echo ""

# ─── Test: YAML validation on corrupt input ─────────────
echo "--- YAML validation ---"

setup
# File with no items: key
echo "garbage: true" > "$TEST_DIR/.claude/plans/todos.yml"
out=$(run_todo show 2>&1 || true)
assert_contains "validate: missing items key" "missing" "$out"

# File with duplicate IDs
cat > "$TEST_DIR/.claude/plans/todos.yml" << 'EOF'
items:

  - id: dupe
    title: "First"
    status: backlog

  - id: dupe
    title: "Second"
    status: backlog
EOF

out2=$(run_todo show 2>&1)
assert_contains "validate: duplicate IDs warned" "duplicate" "$out2"
teardown
echo ""

# ─── Test: file locking (concurrent writes) ─────────────
echo "--- file locking ---"

setup
# Pre-create the file
run_todo add "Base item" >/dev/null

# Simulate a held lock
mkdir -p /tmp/founder-todo.lock

# Attempt to add while lock is held — should fail after retries
# Use perl-based timeout (macOS compatible, no coreutils needed)
out=$(perl -e 'alarm 3; exec @ARGV' bash -c "cd '$TEST_DIR' && bash '$TODO_SH' add 'Blocked item' 2>&1" 2>&1 || true)
assert_contains "lock: reports lock failure" "could not acquire\|Alarm" "$out"

# Release the lock
rmdir /tmp/founder-todo.lock 2>/dev/null || true

# Now it should work
out2=$(run_todo add "Unblocked item")
assert_contains "lock: works after release" "Unblocked item" "$out2"
teardown
echo ""

# ─── Test: concurrent write safety ──────────────────────
echo "--- concurrent write safety ---"

setup
run_todo add "Seed item" >/dev/null

# Launch two adds in parallel — both should succeed (one waits for lock)
(cd "$TEST_DIR" && bash "$TODO_SH" add "Parallel A" >/dev/null 2>&1) &
pid1=$!
(cd "$TEST_DIR" && bash "$TODO_SH" add "Parallel B" >/dev/null 2>&1) &
pid2=$!

wait "$pid1" 2>/dev/null || true
wait "$pid2" 2>/dev/null || true

content=$(cat "$TEST_DIR/.claude/plans/todos.yml")
count=$(grep -c '^ *- id:' "$TEST_DIR/.claude/plans/todos.yml" || true)

# At minimum the seed item should survive; both parallels may or may not both make it
# depending on timing, but the file should remain valid YAML
assert_contains "concurrent: file has items key" "items:" "$content"
# Should have at least 2 items (seed + at least one parallel)
if [[ "$count" -ge 2 ]]; then
    PASS=$((PASS + 1))
    echo "  PASS  concurrent: at least 2 items survived ($count total)"
else
    FAIL=$((FAIL + 1))
    echo "  FAIL  concurrent: expected >=2 items, got $count"
fi
teardown
echo ""

# ─── Test: empty backlog ────────────────────────────────
echo "--- edge cases ---"

# Use a special setup without pre-created file
EDGE_DIR=$(mktemp -d)
mkdir -p "$EDGE_DIR/.claude/plans"
# No todos.yml here — test empty state
# But we need to prevent fallback to founder-os dir, so use a subdir approach
run_edge() {
    (cd "$EDGE_DIR" && CLAUDE_PLUGIN_ROOT="$EDGE_DIR" bash "$TODO_SH" "$@" 2>&1)
}

out=$(run_edge show)
assert_contains "empty: no file message" "empty" "$out"

out2=$(run_edge health)
assert_contains "empty: health handles missing" "empty" "$out2"

# Import with no stdin (but not a TTY — use /dev/null)
setup
out3=$(run_todo import < /dev/null || true)
assert_contains "import: zero items" "imported 0" "$out3"
teardown
rm -rf "$EDGE_DIR"
echo ""

# ─── Summary ────────────────────────────────────────────
TOTAL=$((PASS + FAIL))
echo "=== Results: $PASS/$TOTAL passed ==="
if [[ "$FAIL" -gt 0 ]]; then
    echo "FAILED"
    exit 1
else
    echo "ALL PASSED"
    exit 0
fi
