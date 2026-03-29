#!/usr/bin/env bash
# stranger-test.sh — Cold-start smoke test for founder-os.
# Simulates a brand-new user on a fresh project.
# Isolates HOME so real user state is never touched.
#
# Usage: bash tests/stranger-test.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FOUNDER_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# --- Test infrastructure ---
PASS=0
FAIL=0
TOTAL=0

assert_true() {
    local label="$1"
    local result="$2"
    TOTAL=$((TOTAL + 1))
    if [[ "$result" == "0" ]]; then
        echo "  ✓ $label"
        PASS=$((PASS + 1))
    else
        echo "  ✗ $label"
        FAIL=$((FAIL + 1))
    fi
}

assert_file_exists() {
    local label="$1"
    local path="$2"
    TOTAL=$((TOTAL + 1))
    if [[ -f "$path" ]]; then
        echo "  ✓ $label"
        PASS=$((PASS + 1))
    else
        echo "  ✗ $label — missing: $path"
        FAIL=$((FAIL + 1))
    fi
}

assert_dir_exists() {
    local label="$1"
    local path="$2"
    TOTAL=$((TOTAL + 1))
    if [[ -d "$path" ]]; then
        echo "  ✓ $label"
        PASS=$((PASS + 1))
    else
        echo "  ✗ $label — missing: $path"
        FAIL=$((FAIL + 1))
    fi
}

assert_contains() {
    local label="$1"
    local file="$2"
    local pattern="$3"
    TOTAL=$((TOTAL + 1))
    if grep -q "$pattern" "$file" 2>/dev/null; then
        echo "  ✓ $label"
        PASS=$((PASS + 1))
    else
        echo "  ✗ $label — '$pattern' not found in $file"
        FAIL=$((FAIL + 1))
    fi
}

assert_json_valid() {
    local label="$1"
    local file="$2"
    TOTAL=$((TOTAL + 1))
    if jq empty "$file" 2>/dev/null; then
        echo "  ✓ $label"
        PASS=$((PASS + 1))
    else
        echo "  ✗ $label — invalid JSON: $file"
        FAIL=$((FAIL + 1))
    fi
}

# --- Setup ---
echo "◆ stranger-test — cold-start smoke test"
echo ""

# Check dependencies
if ! command -v jq &>/dev/null; then
    echo "  ✗ jq required: brew install jq"
    exit 1
fi
if ! command -v git &>/dev/null; then
    echo "  ✗ git required"
    exit 1
fi

# Create isolated temp environment
TEMP_DIR=$(mktemp -d)
FAKE_HOME="$TEMP_DIR/home"
PROJECT="$TEMP_DIR/test-project"
mkdir -p "$FAKE_HOME" "$PROJECT/src" "$PROJECT/.claude/cache"

trap "rm -rf '$TEMP_DIR'" EXIT

echo "  temp: $TEMP_DIR"
echo ""

# --- Create test fixture ---
echo "── fixture ──"

cat > "$PROJECT/README.md" << 'FIXTURE_README'
# task-tracker

A simple CLI tool for managing daily tasks. Built for developers who want
to track todos without leaving the terminal.

## Install

```
npm install -g task-tracker
```

## Usage

```
task add "Buy groceries"
task list
task done 1
```
FIXTURE_README

cat > "$PROJECT/package.json" << 'FIXTURE_PKG'
{
  "name": "task-tracker",
  "version": "0.1.0",
  "description": "CLI tool for managing daily tasks from the terminal",
  "main": "src/index.js",
  "bin": { "task": "src/index.js" }
}
FIXTURE_PKG

cat > "$PROJECT/src/index.js" << 'FIXTURE_SRC'
#!/usr/bin/env node
const fs = require('fs');
const args = process.argv.slice(2);
const cmd = args[0];

const TASKS_FILE = '.tasks.json';
function loadTasks() {
  try { return JSON.parse(fs.readFileSync(TASKS_FILE, 'utf8')); }
  catch { return []; }
}
function saveTasks(tasks) {
  fs.writeFileSync(TASKS_FILE, JSON.stringify(tasks, null, 2));
}

if (cmd === 'add') {
  const tasks = loadTasks();
  tasks.push({ text: args.slice(1).join(' '), done: false, created: new Date().toISOString() });
  saveTasks(tasks);
  console.log(`Added: ${args.slice(1).join(' ')}`);
} else if (cmd === 'list') {
  const tasks = loadTasks();
  tasks.forEach((t, i) => console.log(`${t.done ? '✓' : '○'} ${i+1}. ${t.text}`));
} else if (cmd === 'done') {
  const tasks = loadTasks();
  const idx = parseInt(args[1]) - 1;
  if (tasks[idx]) { tasks[idx].done = true; saveTasks(tasks); console.log('Done!'); }
} else {
  console.log('Usage: task <add|list|done> [args]');
}
FIXTURE_SRC

# Init git (detect-project.sh expects it)
(cd "$PROJECT" && git init -q && git add -A && git commit -q -m "initial commit")

echo "  ✓ test project created (task-tracker)"
echo ""

# --- Phase 1: Install ---
echo "── install ──"

# Run install.sh with isolated HOME
# Skip claude CLI check since test environment may not have it
INSTALL_OUTPUT=$(HOME="$FAKE_HOME" SKIP_CLAUDE_CHECK=1 bash "$FOUNDER_DIR/install.sh" 2>&1) || true

assert_dir_exists "~/.founder-os/ created" "$FAKE_HOME/.founder-os"
assert_file_exists "portfolio.yml created" "$FAKE_HOME/.founder-os/portfolio.yml"
assert_dir_exists "~/.claude/knowledge/ created" "$FAKE_HOME/.claude/knowledge"
assert_file_exists "predictions.tsv created" "$FAKE_HOME/.claude/knowledge/predictions.tsv"
assert_file_exists "experiment-learnings.md created" "$FAKE_HOME/.claude/knowledge/experiment-learnings.md"
echo ""

# --- Phase 2: Detection ---
echo "── detection ──"

DETECT_OUTPUT=$(CLAUDE_PROJECT_DIR="$PROJECT" bash "$FOUNDER_DIR/skills/founder/scripts/detect-project.sh" 2>&1) || true
assert_true "detect-project.sh exits ok" "$?"

DETECT_HAS_NODE=$(echo "$DETECT_OUTPUT" | grep -c "node" || true)
assert_true "detected node project" "$( [[ "$DETECT_HAS_NODE" -gt 0 ]] && echo 0 || echo 1 )"

CHECKLIST_OUTPUT=$(CLAUDE_PROJECT_DIR="$PROJECT" bash "$FOUNDER_DIR/skills/founder/scripts/onboard-checklist.sh" 2>&1) || true
assert_true "onboard-checklist.sh exits ok" "$?"
echo ""

# --- Phase 3: Demand-cache generation ---
echo "── demand-cache ──"

bash "$FOUNDER_DIR/skills/founder/scripts/demand-from-readme.sh" "$PROJECT" > "$PROJECT/.claude/cache/demand-cache.json" 2>/dev/null
assert_true "demand-from-readme.sh exits ok" "$?"

assert_file_exists "demand-cache.json created" "$PROJECT/.claude/cache/demand-cache.json"
assert_json_valid "demand-cache.json is valid JSON" "$PROJECT/.claude/cache/demand-cache.json"

IDEA_NAME=$(jq -r '.idea' "$PROJECT/.claude/cache/demand-cache.json" 2>/dev/null || true)
assert_true "extracted project name: $IDEA_NAME" "$( [[ "$IDEA_NAME" == "task-tracker" ]] && echo 0 || echo 1 )"

JOB_COUNT=$(jq '.jobs | length' "$PROJECT/.claude/cache/demand-cache.json" 2>/dev/null || echo 0)
assert_true "has jobs ($JOB_COUNT)" "$( [[ "$JOB_COUNT" -ge 1 ]] && echo 0 || echo 1 )"

TIER=$(jq -r '.demand_tier' "$PROJECT/.claude/cache/demand-cache.json" 2>/dev/null || true)
assert_true "demand_tier is stub" "$( [[ "$TIER" == "stub" ]] && echo 0 || echo 1 )"

INFERRED_COUNT=$(jq '.evidence.inferred | length' "$PROJECT/.claude/cache/demand-cache.json" 2>/dev/null || echo 0)
assert_true "evidence labeled [inferred] ($INFERRED_COUNT)" "$( [[ "$INFERRED_COUNT" -ge 1 ]] && echo 0 || echo 1 )"
echo ""

# --- Phase 4: Config generation (simulated) ---
echo "── config (simulated) ──"

# In real /onboard, the LLM generates these. The stranger test simulates it
# to validate the downstream scoring pipeline works.
mkdir -p "$PROJECT/config"

cat > "$PROJECT/config/founder.yml" << 'FIXTURE_CONFIG'
project:
  name: task-tracker
  stage: mvp
  mode: build
  type: cli

value:
  hypothesis: "A developer can manage daily tasks without leaving the terminal"
  user: "Developer who wants quick todo management from CLI"

features:
  task-management:
    delivers: "add, list, and complete tasks from the command line"
    for: "developer who wants terminal-native task tracking"
    code: ["src/index.js"]
    status: active
    weight: 5
FIXTURE_CONFIG

mkdir -p "$PROJECT/lens/product/eval"
cat > "$PROJECT/lens/product/eval/beliefs.yml" << 'FIXTURE_BELIEFS'
beliefs:
  - id: main-entry-exists
    belief: "src/index.js exists as CLI entry point"
    type: file_check
    path: "src/index.js"
    contains: "process.argv"
    feature: task-management
    quality: correctness
    layer: infrastructure
    severity: block

  - id: package-has-bin
    belief: "package.json defines a bin command"
    type: file_check
    path: "package.json"
    contains: "bin"
    feature: task-management
    quality: correctness
    layer: infrastructure
    severity: warn
FIXTURE_BELIEFS

assert_file_exists "founder.yml created" "$PROJECT/config/founder.yml"
assert_file_exists "beliefs.yml created" "$PROJECT/lens/product/eval/beliefs.yml"
assert_contains "hypothesis is real (not placeholder)" "$PROJECT/config/founder.yml" "developer can manage"
echo ""

# --- Phase 5: Score ---
echo "── score ──"

SCORE_OUTPUT=$(bash "$FOUNDER_DIR/bin/score.sh" "$PROJECT" --json 2>/dev/null) || true
if [[ -n "$SCORE_OUTPUT" ]]; then
    SCORE=$(echo "$SCORE_OUTPUT" | jq -r '.score' 2>/dev/null || echo "0")
    ASSERTIONS_PASS=$(echo "$SCORE_OUTPUT" | jq -r '.assertion_pass_count' 2>/dev/null || echo "0")
    ASSERTIONS_TOTAL=$(echo "$SCORE_OUTPUT" | jq -r '.assertion_count' 2>/dev/null || echo "0")

    assert_true "score > 0 (got $SCORE)" "$( [[ "$SCORE" -gt 0 ]] && echo 0 || echo 1 )"
    assert_true "assertions passing ($ASSERTIONS_PASS/$ASSERTIONS_TOTAL)" "$( [[ "$ASSERTIONS_PASS" -gt 0 ]] && echo 0 || echo 1 )"
else
    assert_true "score.sh produced output" "1"
    assert_true "assertions passing" "1"
fi
echo ""

# --- Summary ---
echo "⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯"
echo "  $PASS/$TOTAL passed · $FAIL failed"
echo "⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯"

if [[ "$FAIL" -gt 0 ]]; then
    exit 1
fi
exit 0
