#!/usr/bin/env bash
# plan.sh — Read/write .claude/plans/plan.yml
# Machine-readable plan viewer for founder-os.

set -euo pipefail

if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    FOUNDER_DIR="$CLAUDE_PLUGIN_ROOT"
else
    _PLAN_SOURCE="${BASH_SOURCE[0]}"
    while [[ -L "$_PLAN_SOURCE" ]]; do
        _PLAN_SOURCE="$(readlink "$_PLAN_SOURCE")"
    done
    FOUNDER_DIR="$(cd "$(dirname "$_PLAN_SOURCE")/.." && pwd)"
fi

# Project-local first, then founder-os's own plan
PROJECT_DIR="$(pwd)"
PLAN_FILE="$PROJECT_DIR/.claude/plans/plan.yml"
[[ ! -f "$PLAN_FILE" ]] && PLAN_FILE="$FOUNDER_DIR/.claude/plans/plan.yml"
FALLBACK="$PROJECT_DIR/.claude/plans/active-plan.md"
[[ ! -f "$FALLBACK" ]] && FALLBACK="$FOUNDER_DIR/.claude/plans/active-plan.md"

# Colors
BOLD='\033[1m'
DIM='\033[2m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# ── Helpers ─────────────────────────────────────────────

plan_exists() {
    [[ -f "$PLAN_FILE" ]]
}

# Read a simple key from plan.yml (top-level or under meta:)
plan_meta() {
    local key="$1"
    local default="${2:-}"
    if [[ ! -f "$PLAN_FILE" ]]; then
        echo "$default"
        return
    fi
    local val
    val=$(grep -E "^  ${key}:" "$PLAN_FILE" 2>/dev/null | head -1 | sed 's/.*: *//' | sed 's/^"//' | sed 's/"$//')
    if [[ -n "$val" ]]; then
        echo "$val"
    else
        echo "$default"
    fi
}

# Count tasks by status
count_tasks() {
    local status="$1"
    local count
    count=$(grep -c "status: ${status}" "$PLAN_FILE" 2>/dev/null) || count=0
    echo "$count"
}

# Get all task IDs
task_ids() {
    grep '^ *- id:' "$PLAN_FILE" 2>/dev/null | sed 's/.*id: *//'
}

# Get a field for a specific task ID
task_field() {
    local id="$1"
    local field="$2"
    # Find the task block, then find the field within it
    awk -v id="$id" -v field="$field" '
        /^ *- id:/ { found = ($0 ~ "id: *" id "$") }
        found && $0 ~ "^ *" field ":" {
            sub(/^[^:]+: */, "")
            gsub(/^"/, ""); gsub(/"$/, "")
            print
            exit
        }
        found && /^ *- id:/ && !($0 ~ "id: *" id "$") { exit }
    ' "$PLAN_FILE"
}

# Get the next todo task
next_task_id() {
    awk '
        /^ *- id:/ { current_id = $0; sub(/.*id: */, "", current_id) }
        /status: *todo/ { print current_id; exit }
    ' "$PLAN_FILE"
}

# ── Commands ────────────────────────────────────────────

cmd_show() {
    if ! plan_exists; then
        if [[ -f "$FALLBACK" ]]; then
            echo -e "  ${YELLOW}⚠${NC} No plan.yml — showing active-plan.md"
            cat "$FALLBACK"
            return
        fi
        echo -e "  ${YELLOW}⚠${NC} No active plan. Run /plan to create one."
        return 1
    fi

    local name total done_count todo_count in_progress
    name=$(plan_meta "name" "unnamed")
    total=$(grep -c '^ *- id:' "$PLAN_FILE" 2>/dev/null) || true
    [[ -z "$total" ]] && total=0
    done_count=$(count_tasks "done")
    todo_count=$(count_tasks "todo")
    in_progress=$(count_tasks "in_progress")

    echo ""
    echo -e "  ${CYAN}◆${NC} ${BOLD}${name}${NC}"
    echo -e "  ${DIM}$(plan_meta "bottleneck" "")${NC}"
    echo ""

    # Render each task
    while IFS= read -r id; do
        local status title value
        status=$(task_field "$id" "status")
        title=$(task_field "$id" "title")
        value=$(task_field "$id" "value")

        case "$status" in
            done)        echo -e "  ${GREEN}✓${NC} ${DIM}${title}${NC}" ;;
            in_progress) echo -e "  ${CYAN}▸${NC} ${BOLD}${title}${NC}"
                         [[ -n "$value" ]] && echo -e "    ${DIM}${value}${NC}" ;;
            todo)        echo -e "  · ${title}"
                         [[ -n "$value" ]] && echo -e "    ${DIM}${value}${NC}" ;;
            skipped)     echo -e "  ${DIM}✗ ${title} (skipped)${NC}" ;;
        esac
    done <<< "$(task_ids)"

    echo ""
    echo -e "  ${DIM}${done_count}/${total} done${NC}"
    if [[ "$in_progress" -gt 0 ]]; then
        echo -e "  ${CYAN}▸${NC} ${DIM}${in_progress} in progress${NC}"
    fi
    echo ""
}

cmd_next() {
    if ! plan_exists; then
        echo "No plan.yml found"
        return 1
    fi
    local id
    id=$(next_task_id)
    if [[ -z "$id" ]]; then
        echo "All tasks complete"
        return 0
    fi
    local title status value accept touch
    title=$(task_field "$id" "title")
    value=$(task_field "$id" "value")
    accept=$(task_field "$id" "accept")
    touch=$(task_field "$id" "touch")

    echo -e "  ${CYAN}▸${NC} ${BOLD}${title}${NC}  ${DIM}[${id}]${NC}"
    [[ -n "$value" ]] && echo -e "  ${DIM}value${NC}   ${value}"
    [[ -n "$accept" ]] && echo -e "  ${DIM}accept${NC}  ${accept}"
    [[ -n "$touch" ]] && echo -e "  ${DIM}touch${NC}   ${touch}"
}

cmd_done() {
    local target_id="$1"
    if [[ -z "$target_id" ]]; then
        echo "Usage: founder plan done <task-id>"
        return 1
    fi
    if ! plan_exists; then
        echo "No plan.yml found"
        return 1
    fi

    # Check task exists
    if ! grep -q "id: ${target_id}$" "$PLAN_FILE" 2>/dev/null; then
        echo "Task '$target_id' not found"
        return 1
    fi

    # Update status to done using awk
    awk -v id="$target_id" '
        /^ *- id:/ { found = ($0 ~ "id: *" id "$") }
        found && /status:/ { sub(/status: *[a-z_]+/, "status: done"); found = 0 }
        { print }
    ' "$PLAN_FILE" > "${PLAN_FILE}.tmp" && mv "${PLAN_FILE}.tmp" "$PLAN_FILE"

    # Update meta.updated
    local today
    today=$(date '+%Y-%m-%d')
    sed -i '' "s/^  updated:.*/  updated: ${today}/" "$PLAN_FILE" 2>/dev/null || true

    echo -e "  ${GREEN}✓${NC} ${target_id} → done"
}

cmd_json() {
    if ! plan_exists; then
        echo "{}"
        return 1
    fi
    cat "$PLAN_FILE"
}

# ── Main ────────────────────────────────────────────────

case "${1:-show}" in
    show|"")    cmd_show ;;
    next)       cmd_next ;;
    done)       shift; cmd_done "${1:-}" ;;
    json|raw)   cmd_json ;;
    *)
        echo "Usage: founder plan [show|next|done <id>|json]"
        exit 1
        ;;
esac
