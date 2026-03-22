#!/usr/bin/env bash
# todo.sh — Read/write .claude/plans/todos.yml
# Persistent backlog that survives across plans.

set -uo pipefail
# NOTE: set -e intentionally omitted. Item parsing uses grep/awk patterns
# where empty results (missing fields) return 1 — that's normal, not an error.

if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    FOUNDER_DIR="$CLAUDE_PLUGIN_ROOT"
else
    _BACKLOG_SOURCE="${BASH_SOURCE[0]}"
    while [[ -L "$_BACKLOG_SOURCE" ]]; do
        _BACKLOG_SOURCE="$(readlink "$_BACKLOG_SOURCE")"
    done
    FOUNDER_DIR="$(cd "$(dirname "$_BACKLOG_SOURCE")/.." && pwd)"
fi

# Project-local first, then founder-os's own todos
PROJECT_DIR="$(pwd)"
BACKLOG_FILE="$PROJECT_DIR/.claude/plans/todos.yml"
[[ ! -f "$BACKLOG_FILE" ]] && BACKLOG_FILE="$FOUNDER_DIR/.claude/plans/todos.yml"
PLAN_FILE="$PROJECT_DIR/.claude/plans/plan.yml"
[[ ! -f "$PLAN_FILE" ]] && PLAN_FILE="$FOUNDER_DIR/.claude/plans/plan.yml"

# ── TTY-aware colors ──────────────────────────────────────
if [[ -t 1 ]]; then
    BOLD='\033[1m'
    DIM='\033[2m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    RED='\033[0;31m'
    CYAN='\033[0;36m'
    NC='\033[0m'
else
    BOLD='' DIM='' GREEN='' YELLOW='' RED='' CYAN='' NC=''
fi

# ── Helpers ─────────────────────────────────────────────

todo_exists() {
    [[ -f "$BACKLOG_FILE" ]]
}

# Basic YAML validation — check for items: key and valid structure
validate_yaml() {
    if [[ ! -f "$BACKLOG_FILE" ]]; then return 0; fi

    # Must contain items: key
    if ! grep -q '^items:' "$BACKLOG_FILE" 2>/dev/null; then
        echo -e "  ${RED}error${NC}: todos.yml missing 'items:' key" >&2
        return 1
    fi

    # Check for items with missing id field (malformed entries)
    local items_count id_count
    items_count=$(grep -c '^ *- ' "$BACKLOG_FILE" 2>/dev/null) || true
    id_count=$(grep -c '^ *- id:' "$BACKLOG_FILE" 2>/dev/null) || true
    # Note: items_count may be higher if fields like "- title:" exist, but
    # every list entry must start with "- id:". If list items outnumber ids,
    # there's a structural problem — but we only warn, don't block.

    # Check for duplicate IDs
    local dupes
    dupes=$(grep '^ *- id:' "$BACKLOG_FILE" 2>/dev/null | sed 's/.*id: *//' | sort | uniq -d)
    if [[ -n "$dupes" ]]; then
        echo -e "  ${YELLOW}warning${NC}: duplicate IDs in todos.yml: $dupes" >&2
    fi

    return 0
}

# Get all item IDs
item_ids() {
    grep '^ *- id:' "$BACKLOG_FILE" 2>/dev/null | sed 's/.*id: *//'
}

# Get a field for a specific item ID
item_field() {
    local id="$1"
    local field="$2"
    awk -v id="$id" -v field="$field" '
        /^ *- id:/ {
            # Exact string match on ID to prevent substring false-matches
            line = $0
            gsub(/^ *- id: */, "", line)
            found = (line == id)
            next
        }
        found && $0 ~ "^ *" field ":" {
            sub("^ *" field ": *", "")
            gsub(/^"/, ""); gsub(/"$/, "")
            print
            exit
        }
        found && /^ *- id:/ { exit }
    ' "$BACKLOG_FILE"
}

# Set a field for a specific item ID
item_set_field() {
    local id="$1"
    local field="$2"
    local value="$3"

    # Check if field exists for this item
    local existing
    existing=$(item_field "$id" "$field")

    if [[ -n "$existing" ]]; then
        # Update existing field
        awk -v id="$id" -v field="$field" -v value="$value" '
            /^ *- id:/ { found = ($0 ~ "id: *" id "$") }
            found && $0 ~ "^ *" field ":" {
                match($0, /^[ ]*/)
                indent = substr($0, RSTART, RLENGTH)
                if (value ~ / /) {
                    print indent field ": \"" value "\""
                } else {
                    print indent field ": " value
                }
                next
            }
            found && /^ *- id:/ && !($0 ~ "id: *" id "$") { found = 0 }
            { print }
        ' "$BACKLOG_FILE" > "${BACKLOG_FILE}.tmp" && mv "${BACKLOG_FILE}.tmp" "$BACKLOG_FILE"
    else
        # Add new field after the id line
        awk -v id="$id" -v field="$field" -v value="$value" '
            /^ *- id:/ && ($0 ~ "id: *" id "$") { found_target = 1 }
            /^ *- id:/ && !($0 ~ "id: *" id "$") { found_target = 0 }
            { print }
            found_target && /^ *- id:/ {
                # Detect indent from the "- id:" line: leading whitespace + "- " → field indent
                match($0, /^[ ]*/)
                id_indent = substr($0, RSTART, RLENGTH)
                # The "- " prefix is 2 chars; field indent replaces those with spaces
                field_indent = id_indent "  "
                if (value ~ / /) {
                    print field_indent field ": \"" value "\""
                } else {
                    print field_indent field ": " value
                }
                found_target = 0
            }
        ' "$BACKLOG_FILE" > "${BACKLOG_FILE}.tmp" && mv "${BACKLOG_FILE}.tmp" "$BACKLOG_FILE"
    fi
}

priority_color() {
    case "$1" in
        urgent) echo -e "${RED}●${NC}" ;;
        high)   echo -e "${YELLOW}●${NC}" ;;
        medium) echo -e "${CYAN}·${NC}" ;;
        low)    echo -e "${DIM}·${NC}" ;;
        *)      echo -e "${DIM}·${NC}" ;;
    esac
}

priority_sort_key() {
    case "${1:-}" in
        urgent) echo "0" ;;
        high)   echo "1" ;;
        medium) echo "2" ;;
        low)    echo "3" ;;
        *)      echo "4" ;;
    esac
}

status_icon() {
    case "$1" in
        active) echo -e "${GREEN}▸${NC}" ;;
        done)   echo -e "${GREEN}✓${NC}" ;;
        *)      echo -e " " ;;  # backlog = no icon
    esac
}

# ── Decay detection ──────────────────────────────────────

# Check item age and return decay bracket: fresh, stale-7, stale-14, stale-30
item_age_days() {
    local id="$1"
    local created
    created=$(item_field "$id" "created_at")
    # Fall back to "created" for backward compat
    [[ -z "$created" ]] && created=$(item_field "$id" "created")
    [[ -z "$created" || "$created" == "null" ]] && echo "" && return

    local today_ts created_ts
    today_ts=$(date +%s)
    created_ts=$(date -j -f "%Y-%m-%d" "$created" +%s 2>/dev/null || date -d "$created" +%s 2>/dev/null || echo "0")
    [[ "$created_ts" == "0" ]] && echo "" && return

    echo $(( (today_ts - created_ts) / 86400 ))
}

# Print decay warnings for stale items
cmd_decay() {
    if ! todo_exists; then
        echo -e "  ${DIM}No todos.yml${NC}"
        return 0
    fi

    echo ""
    echo -e "  ${BOLD}Decay check${NC}"
    echo ""

    local stale_count=0
    local tagged_stale=0
    while IFS= read -r id; do
        [[ -z "$id" ]] && continue
        local status
        status=$(item_field "$id" "status")
        [[ "$status" == "done" ]] && continue

        local age
        age=$(item_age_days "$id")
        [[ -z "$age" ]] && continue

        local title feature current_status
        title=$(item_field "$id" "title")
        feature=$(item_field "$id" "feature")
        current_status=$(item_field "$id" "status")

        if [[ "$age" -ge 30 ]]; then
            echo -e "  ${RED}●${NC} ${title}  ${DIM}[${id}]${NC}  ${RED}${age}d${NC}"
            echo -e "    ${DIM}→ 30+ days. Kill or promote?${NC}"
            echo -e "    ${DIM}  founder todo done ${id}       # kill it${NC}"
            echo -e "    ${DIM}  founder todo promote ${id}    # activate it${NC}"
            stale_count=$((stale_count + 1))
            # Auto-tag as stale if not already
            if [[ "$current_status" != "stale" ]]; then
                acquire_lock || continue
                item_set_field "$id" "status" "stale"
                release_lock
                tagged_stale=$((tagged_stale + 1))
            fi
        elif [[ "$age" -ge 14 ]]; then
            echo -e "  ${YELLOW}●${NC} ${title}  ${DIM}[${id}]${NC}  ${YELLOW}${age}d${NC}"
            echo -e "    ${DIM}→ Stale. Promote / kill / needs research?${NC}"
            echo -e "    ${DIM}  founder todo promote ${id}    # activate it${NC}"
            echo -e "    ${DIM}  founder todo done ${id}       # kill it${NC}"
            stale_count=$((stale_count + 1))
        elif [[ "$age" -ge 7 && -z "$feature" ]]; then
            echo -e "  ${CYAN}●${NC} ${title}  ${DIM}[${id}]${NC}  ${CYAN}${age}d${NC}"
            echo -e "    ${DIM}→ 7+ days untagged. Tag or kill.${NC}"
            echo -e "    ${DIM}  founder todo tag ${id} <feature>${NC}"
            echo -e "    ${DIM}  founder todo done ${id}${NC}"
            stale_count=$((stale_count + 1))
        fi
    done <<< "$(item_ids)"

    if [[ "$stale_count" -eq 0 ]]; then
        echo -e "  ${GREEN}✓${NC} no stale items — backlog is healthy"
    else
        echo ""
        if [[ "$tagged_stale" -gt 0 ]]; then
            echo -e "  ${DIM}${tagged_stale} item(s) auto-tagged as stale (30+ days)${NC}"
        fi
        echo -e "  ${DIM}${stale_count} item(s) need attention${NC}"
    fi
    echo ""
}

# Inline decay summary for cmd_show — just counts, not full detail
decay_summary() {
    local stale_count=0
    while IFS= read -r id; do
        [[ -z "$id" ]] && continue
        local status
        status=$(item_field "$id" "status")
        [[ "$status" == "done" ]] && continue

        local age
        age=$(item_age_days "$id")
        [[ -z "$age" ]] && continue

        [[ "$age" -ge 7 ]] && stale_count=$((stale_count + 1))
    done <<< "$(item_ids)"

    if [[ "$stale_count" -gt 0 ]]; then
        echo -e "  ${YELLOW}⚠${NC} ${stale_count} stale item(s) — run ${DIM}/todo decay${NC} for details"
        echo ""
    fi
}

# ── File locking ─────────────────────────────────────────

LOCK_DIR="/tmp/founder-todo.lock"

acquire_lock() {
    local retries=0
    while ! mkdir "$LOCK_DIR" 2>/dev/null; do
        retries=$((retries + 1))
        # Auto-clean stale locks older than 30 seconds
        if [[ "$retries" -eq 5 ]]; then
            local lock_age=0
            if [[ -d "$LOCK_DIR" ]]; then
                local lock_mtime now_ts
                lock_mtime=$(stat -f %m "$LOCK_DIR" 2>/dev/null || stat -c %Y "$LOCK_DIR" 2>/dev/null || echo "0")
                now_ts=$(date +%s)
                lock_age=$((now_ts - lock_mtime))
            fi
            if [[ "$lock_age" -gt 30 ]]; then
                rmdir "$LOCK_DIR" 2>/dev/null || true
                continue
            fi
        fi
        if [[ "$retries" -ge 10 ]]; then
            echo -e "  ${RED}error${NC}: could not acquire todo lock after ${retries} attempts" >&2
            echo -e "  ${DIM}stale lock? run: rmdir ${LOCK_DIR}${NC}" >&2
            return 1
        fi
        sleep 0.1
    done
    # Ensure cleanup on exit
    trap 'rmdir "$LOCK_DIR" 2>/dev/null || true' EXIT
}

release_lock() {
    rmdir "$LOCK_DIR" 2>/dev/null || true
}

# ── Display helpers ───────────────────────────────────────

# Print a single item line
print_item() {
    local id="$1"
    local priority title feature status
    priority=$(item_field "$id" "priority")
    title=$(item_field "$id" "title")
    feature=$(item_field "$id" "feature")
    status=$(item_field "$id" "status")
    local context
    context=$(item_field "$id" "context")

    local marker
    marker=$(priority_color "$priority")
    local s_icon
    s_icon=$(status_icon "$status")

    local feature_tag=""
    [[ -n "$feature" ]] && feature_tag="${DIM}[${feature}]${NC} "

    # Show age indicator for stale items
    local age_tag=""
    local age
    age=$(item_age_days "$id")
    if [[ -n "$age" && "$age" -ge 14 ]]; then
        age_tag=" ${YELLOW}${age}d${NC}"
    elif [[ -n "$age" && "$age" -ge 7 ]]; then
        age_tag=" ${DIM}${age}d${NC}"
    fi

    echo -e "  ${s_icon}${marker} ${feature_tag}${title}${age_tag}  ${DIM}[${id}]${NC}"
    [[ -n "$context" ]] && echo -e "    ${DIM}${context}${NC}"
}

# Collect items with sort keys, optionally filtered
collect_items() {
    local filter_status="${1:-}"
    local filter_feature="${2:-}"
    local items=()

    while IFS= read -r id; do
        [[ -z "$id" ]] && continue
        local priority status feature
        priority=$(item_field "$id" "priority")
        status=$(item_field "$id" "status")
        feature=$(item_field "$id" "feature")
        [[ -z "$status" ]] && status="backlog"

        # Apply filters
        [[ -n "$filter_status" && "$status" != "$filter_status" ]] && continue
        [[ -n "$filter_feature" && "$feature" != "$filter_feature" ]] && continue

        local sort_key
        sort_key=$(priority_sort_key "$priority")
        items+=("${sort_key}|${id}")
    done <<< "$(item_ids)"

    if [[ ${#items[@]} -gt 0 ]]; then
        printf '%s\n' "${items[@]}" | sort
    fi
}

# ── Commands ────────────────────────────────────────────

cmd_show() {
    if ! todo_exists; then
        echo -e "  ${DIM}No todos.yml — backlog is empty${NC}"
        echo -e "  ${GREEN}▸${NC} ${DIM}founder todo add \"title\" to capture ideas${NC}"
        return 0
    fi

    validate_yaml || return 1

    local total
    total=$(grep -c '^ *- id:' "$BACKLOG_FILE" 2>/dev/null) || true
    [[ -z "$total" ]] && total=0

    if [[ "$total" -eq 0 ]]; then
        echo -e "  ${DIM}Backlog empty${NC}"
        echo -e "  ${GREEN}▸${NC} ${DIM}founder todo add \"title\" to capture ideas${NC}"
        return 0
    fi

    # Check if any items have features
    local has_features=false
    if grep -q '^ *feature: [^ ""]' "$BACKLOG_FILE" 2>/dev/null || grep -q '^ *feature: ".' "$BACKLOG_FILE" 2>/dev/null; then
        has_features=true
    fi

    echo ""

    # Source counts header — shows this is an evidence-fed backlog, not a generic one
    local src_eval=0 src_taste=0 src_ideate=0 src_manual=0 src_other=0
    while IFS= read -r id; do
        [[ -z "$id" ]] && continue
        local src
        src=$(item_field "$id" "source")
        case "$src" in
            */eval|eval)     src_eval=$((src_eval + 1)) ;;
            */taste|taste)   src_taste=$((src_taste + 1)) ;;
            */ideate|ideate) src_ideate=$((src_ideate + 1)) ;;
            manual|"")       src_manual=$((src_manual + 1)) ;;
            *)               src_other=$((src_other + 1)) ;;
        esac
    done <<< "$(item_ids)"

    local has_imports=false
    [[ "$src_eval" -gt 0 || "$src_taste" -gt 0 || "$src_ideate" -gt 0 || "$src_other" -gt 0 ]] && has_imports=true

    if $has_imports; then
        local parts=""
        [[ "$src_eval" -gt 0 ]] && parts="${parts}/eval(${src_eval}) "
        [[ "$src_taste" -gt 0 ]] && parts="${parts}/taste(${src_taste}) "
        [[ "$src_ideate" -gt 0 ]] && parts="${parts}/ideate(${src_ideate}) "
        [[ "$src_manual" -gt 0 ]] && parts="${parts}manual(${src_manual}) "
        [[ "$src_other" -gt 0 ]] && parts="${parts}other(${src_other}) "
        echo -e "  ${DIM}sources: ${parts% }${NC}"
        echo ""
    fi

    # Show active items first
    local active_items
    active_items=$(collect_items "active" "")
    if [[ -n "$active_items" ]]; then
        echo -e "  ${GREEN}▸${NC} ${BOLD}Active${NC}"
        echo ""
        while IFS='|' read -r _ id; do
            [[ -z "$id" ]] && continue
            print_item "$id"
        done <<< "$active_items"
        echo ""
    fi

    # Show backlog grouped by feature if features exist
    local backlog_items
    backlog_items=$(collect_items "backlog" "")
    if [[ -n "$backlog_items" ]]; then
        if $has_features; then
            # Group by feature
            local features=()
            local no_feature_ids=()

            while IFS='|' read -r _ id; do
                [[ -z "$id" ]] && continue
                local feat
                feat=$(item_field "$id" "feature")
                if [[ -n "$feat" ]]; then
                    # Add feature to list if not already there
                    local found=false
                    for f in "${features[@]:-}"; do
                        [[ "$f" == "$feat" ]] && found=true && break
                    done
                    $found || features+=("$feat")
                else
                    no_feature_ids+=("$id")
                fi
            done <<< "$backlog_items"

            echo -e "  ${CYAN}◆${NC} ${BOLD}Backlog${NC}"
            echo ""

            for feat in "${features[@]:-}"; do
                [[ -z "$feat" ]] && continue
                echo -e "    ${BOLD}${feat}${NC}"
                while IFS='|' read -r _ id; do
                    [[ -z "$id" ]] && continue
                    local item_feat
                    item_feat=$(item_field "$id" "feature")
                    [[ "$item_feat" == "$feat" ]] && print_item "$id"
                done <<< "$backlog_items"
            done

            if [[ ${#no_feature_ids[@]} -gt 0 ]]; then
                echo -e "    ${BOLD}untagged${NC}"
                for id in "${no_feature_ids[@]}"; do
                    print_item "$id"
                done
            fi
        else
            echo -e "  ${CYAN}◆${NC} ${BOLD}Backlog${NC}  ${DIM}${total} items${NC}"
            echo ""
            while IFS='|' read -r _ id; do
                [[ -z "$id" ]] && continue
                print_item "$id"
            done <<< "$backlog_items"
        fi
        echo ""
    fi

    # Decay summary at the bottom
    decay_summary
}

cmd_add() {
    local title="$1"
    local priority="${2:-medium}"

    if [[ -z "$title" ]]; then
        echo "Usage: founder todo add \"title\" [priority]"
        return 1
    fi

    acquire_lock || return 1

    # Generate ID from title
    local id
    id=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-' | head -c 30)

    # Check for duplicate ID
    if todo_exists && grep -qF "id: ${id}" "$BACKLOG_FILE" 2>/dev/null; then
        # Append timestamp suffix to make unique
        id="${id}-$(date +%s | tail -c 5)"
    fi

    local today
    today=$(date '+%Y-%m-%d')

    if ! todo_exists; then
        mkdir -p "$(dirname "$BACKLOG_FILE")"
        cat > "$BACKLOG_FILE" << EOF
# todos.yml — Persistent backlog

items:
EOF
    fi

    # Clear empty array literal before first append
    if grep -q '^items: \[\]' "$BACKLOG_FILE"; then
        local _sedtmp="${BACKLOG_FILE}.sedtmp"
        sed 's/^items: \[\]/items:/' "$BACKLOG_FILE" > "$_sedtmp" && mv "$_sedtmp" "$BACKLOG_FILE"
    fi

    cat >> "$BACKLOG_FILE" << EOF

  - id: ${id}
    title: "${title}"
    priority: ${priority}
    feature: ""
    status: backlog
    context: ""
    source: "manual"
    created_at: ${today}
EOF

    # Auto-tag: detect feature from title by matching against founder.yml feature names
    # Still under the same lock — no release/re-acquire gap
    local founder_yml="$PROJECT_DIR/config/founder.yml"
    [[ ! -f "$founder_yml" ]] && founder_yml="$FOUNDER_DIR/config/founder.yml"
    local detected_feature=""
    if [[ -f "$founder_yml" ]]; then
        local title_lower
        title_lower=$(echo "$title" | tr '[:upper:]' '[:lower:]')
        while IFS= read -r feat_name; do
            [[ -z "$feat_name" ]] && continue
            local feat_lower
            feat_lower=$(echo "$feat_name" | tr '[:upper:]' '[:lower:]')
            if [[ "$title_lower" == *"$feat_lower"* ]]; then
                detected_feature="$feat_name"
                break
            fi
        done < <(awk '/^  features:/,/^[^ ]/' "$founder_yml" 2>/dev/null | grep -E '^\s+[a-z]' | sed 's/:.*//' | tr -d ' ')
        if [[ -n "$detected_feature" ]]; then
            item_set_field "$id" "feature" "$detected_feature"
        fi
    fi

    release_lock

    if [[ -n "$detected_feature" ]]; then
        echo -e "  ${GREEN}+${NC} ${title}  ${DIM}[${id}] ${priority} → ${detected_feature}${NC}"
    else
        echo -e "  ${GREEN}+${NC} ${title}  ${DIM}[${id}] ${priority}${NC}"
    fi
}

cmd_done() {
    local target_id="$1"
    if [[ -z "$target_id" ]]; then
        echo "Usage: founder todo done <item-id>"
        return 1
    fi
    if ! todo_exists; then
        echo "No todos.yml found"
        return 1
    fi
    if ! grep -qF "id: ${target_id}" "$BACKLOG_FILE" 2>/dev/null; then
        echo "Item '$target_id' not found"
        return 1
    fi

    acquire_lock || return 1
    item_set_field "$target_id" "status" "done"
    item_set_field "$target_id" "done_at" "$(date '+%Y-%m-%d')"
    # Increment done_count for graduation detection
    local current_done_count
    current_done_count=$(item_field "$target_id" "done_count")
    current_done_count=${current_done_count:-0}
    item_set_field "$target_id" "done_count" "$((current_done_count + 1))"
    release_lock
    echo -e "  ${GREEN}✓${NC} ${target_id} → done"

    # Graduation check: should this recurring pattern become an assertion?
    local promote_script="$FOUNDER_DIR/skills/todo/scripts/todo-promote.sh"
    if [[ -f "$promote_script" ]]; then
        bash "$promote_script" "$PROJECT_DIR" graduate "$target_id" 2>/dev/null || true
    fi
}

cmd_edit() {
    local target_id="$1"
    local field="$2"
    local value="$3"

    if [[ -z "$target_id" || -z "$field" || -z "$value" ]]; then
        echo "Usage: founder todo edit <id> <field> <value>"
        return 1
    fi
    if ! todo_exists; then
        echo "No todos.yml found"
        return 1
    fi
    if ! grep -qF "id: ${target_id}" "$BACKLOG_FILE" 2>/dev/null; then
        echo "Item '$target_id' not found"
        return 1
    fi

    # Prevent editing the id field
    if [[ "$field" == "id" ]]; then
        echo "Cannot edit item ID"
        return 1
    fi

    acquire_lock || return 1
    item_set_field "$target_id" "$field" "$value"
    release_lock
    echo -e "  ${GREEN}✓${NC} ${target_id}.${field} → ${value}"
}

cmd_tag() {
    local target_id="$1"
    local feature="$2"

    if [[ -z "$target_id" || -z "$feature" ]]; then
        echo "Usage: founder todo tag <id> <feature>"
        return 1
    fi
    if ! todo_exists; then
        echo "No todos.yml found"
        return 1
    fi
    if ! grep -qF "id: ${target_id}" "$BACKLOG_FILE" 2>/dev/null; then
        echo "Item '$target_id' not found"
        return 1
    fi

    acquire_lock || return 1
    item_set_field "$target_id" "feature" "$feature"
    release_lock
    echo -e "  ${GREEN}✓${NC} ${target_id} tagged → ${feature}"
}

cmd_promote() {
    local target_id="${1:-}"

    # Smart promote: no arg = read eval-cache bottleneck, suggest candidates
    if [[ -z "$target_id" ]]; then
        if ! todo_exists; then
            echo -e "  ${DIM}No todos.yml${NC}"
            return 0
        fi

        # Find bottleneck feature from eval-cache.json
        local cache_file="$PROJECT_DIR/.claude/cache/eval-cache.json"
        [[ ! -f "$cache_file" ]] && cache_file="$FOUNDER_DIR/.claude/cache/eval-cache.json"

        local bottleneck_feature=""
        local bottleneck_score=999
        local bottleneck_weight=0
        if [[ -f "$cache_file" ]] && command -v jq &>/dev/null; then
            # Find lowest-scoring active feature, weighted by importance
            # Read feature weights from founder.yml
            local founder_yml="$PROJECT_DIR/config/founder.yml"
            [[ ! -f "$founder_yml" ]] && founder_yml="$FOUNDER_DIR/config/founder.yml"
            while IFS='|' read -r feat score; do
                [[ -z "$feat" || -z "$score" || "$score" == "null" ]] && continue
                [[ ! "$score" =~ ^[0-9]+$ ]] && continue
                # Get weight from founder.yml (default 1)
                local w=1
                if [[ -f "$founder_yml" ]]; then
                    w=$(grep -A 10 "^  ${feat}:" "$founder_yml" 2>/dev/null | grep "weight:" | head -1 | awk '{print $2}')
                    w="${w:-1}"
                fi
                # Bottleneck = lowest score among highest-weight features
                # Prioritize: lower score wins, then higher weight breaks ties
                if [[ "$score" -lt "$bottleneck_score" || ("$score" -eq "$bottleneck_score" && "$w" -gt "$bottleneck_weight") ]]; then
                    bottleneck_score="$score"
                    bottleneck_feature="$feat"
                    bottleneck_weight="$w"
                fi
            done < <(jq -r 'to_entries[] | select(.value.score != null) | "\(.key)|\(.value.score)"' "$cache_file" 2>/dev/null)
        fi

        echo ""
        echo -e "  ${BOLD}Smart promote${NC}"
        echo ""

        if [[ -n "$bottleneck_feature" ]]; then
            echo -e "  bottleneck: ${BOLD}${bottleneck_feature}${NC} at ${bottleneck_score} (w:${bottleneck_weight})"
            echo ""

            # Find todos tagged to bottleneck feature
            local candidates=0
            while IFS= read -r id; do
                [[ -z "$id" ]] && continue
                local status feat
                status=$(item_field "$id" "status")
                feat=$(item_field "$id" "feature")
                [[ "$status" == "done" || "$status" == "active" ]] && continue
                if [[ "$feat" == "$bottleneck_feature" ]]; then
                    print_item "$id"
                    candidates=$((candidates + 1))
                fi
            done <<< "$(item_ids)"

            if [[ "$candidates" -eq 0 ]]; then
                echo -e "  ${DIM}no backlog items tagged '${bottleneck_feature}'${NC}"
                echo -e "  ${DIM}→ tag items with: founder todo tag <id> ${bottleneck_feature}${NC}"
            else
                echo ""
                echo -e "  ${DIM}promote with: founder todo promote <id>${NC}"
            fi
        else
            echo -e "  ${DIM}no eval-cache found — run /eval to detect bottleneck${NC}"
            echo -e "  ${DIM}showing all backlog items instead:${NC}"
            echo ""
            local backlog_items
            backlog_items=$(collect_items "backlog" "")
            if [[ -n "$backlog_items" ]]; then
                while IFS='|' read -r _ id; do
                    [[ -z "$id" ]] && continue
                    print_item "$id"
                done <<< "$backlog_items"
            else
                echo -e "  ${DIM}backlog empty${NC}"
            fi
        fi
        echo ""
        return 0
    fi

    # Promote a specific item by ID
    if ! todo_exists; then
        echo "No todos.yml found"
        return 1
    fi
    if ! grep -qF "id: ${target_id}" "$BACKLOG_FILE" 2>/dev/null; then
        echo "Item '$target_id' not found"
        return 1
    fi

    acquire_lock || return 1

    # Set status to active
    item_set_field "$target_id" "status" "active"

    release_lock

    # Append to plan.yml if it exists
    local title
    title=$(item_field "$target_id" "title")
    if [[ -f "$PLAN_FILE" ]]; then
        echo "" >> "$PLAN_FILE"
        echo "- [ ] ${title} [${target_id}]" >> "$PLAN_FILE"
        echo -e "  ${GREEN}▸${NC} ${target_id} promoted → active (added to plan.yml)"
    else
        echo -e "  ${GREEN}▸${NC} ${target_id} promoted → active"
    fi
}

cmd_active() {
    if ! todo_exists; then
        echo -e "  ${DIM}No todos.yml${NC}"
        return 0
    fi

    local active_items
    active_items=$(collect_items "active" "")

    echo ""
    if [[ -z "$active_items" ]]; then
        echo -e "  ${DIM}No active items. Use 'founder todo promote <id>' to activate.${NC}"
    else
        echo -e "  ${GREEN}▸${NC} ${BOLD}Active${NC}"
        echo ""
        while IFS='|' read -r _ id; do
            [[ -z "$id" ]] && continue
            print_item "$id"
        done <<< "$active_items"
    fi
    echo ""
}

cmd_feature() {
    local feature_name="${1:-}"

    if ! todo_exists; then
        echo -e "  ${DIM}No todos.yml${NC}"
        return 0
    fi

    if [[ -z "$feature_name" ]]; then
        # List all features with counts
        echo ""
        echo -e "  ${CYAN}◆${NC} ${BOLD}Features${NC}"
        echo ""
        local features=()
        while IFS= read -r id; do
            [[ -z "$id" ]] && continue
            local feat
            feat=$(item_field "$id" "feature")
            [[ -z "$feat" ]] && continue
            local found=false
            for f in "${features[@]:-}"; do
                [[ "$f" == "$feat" ]] && found=true && break
            done
            $found || features+=("$feat")
        done <<< "$(item_ids)"

        for feat in "${features[@]:-}"; do
            [[ -z "$feat" ]] && continue
            local count=0
            while IFS= read -r id; do
                [[ -z "$id" ]] && continue
                local item_feat
                item_feat=$(item_field "$id" "feature")
                [[ "$item_feat" == "$feat" ]] && count=$((count + 1))
            done <<< "$(item_ids)"
            echo -e "    ${BOLD}${feat}${NC}  ${DIM}(${count})${NC}"
        done
        echo ""
    else
        # Show items for a specific feature
        echo ""
        echo -e "  ${BOLD}${feature_name}${NC}"
        echo ""
        local feature_items
        feature_items=$(collect_items "" "$feature_name")
        if [[ -z "$feature_items" ]]; then
            echo -e "  ${DIM}No items tagged '${feature_name}'${NC}"
        else
            while IFS='|' read -r _ id; do
                [[ -z "$id" ]] && continue
                print_item "$id"
            done <<< "$feature_items"
        fi
        echo ""
    fi
}

cmd_version() {
    local version_tag="${1:-}"

    if ! todo_exists; then
        echo -e "  ${DIM}No todos.yml${NC}"
        return 0
    fi

    if [[ -z "$version_tag" ]]; then
        # List all version tags with counts
        echo ""
        echo -e "  ${CYAN}◆${NC} ${BOLD}Versions${NC}"
        echo ""
        local versions=()
        while IFS= read -r id; do
            [[ -z "$id" ]] && continue
            local ver
            ver=$(item_field "$id" "version")
            [[ -z "$ver" ]] && continue
            local found=false
            for v in "${versions[@]+"${versions[@]}"}"; do
                [[ "$v" == "$ver" ]] && found=true && break
            done
            if ! $found; then
                versions+=("$ver")
                local count=0
                while IFS= read -r vid; do
                    [[ -z "$vid" ]] && continue
                    local vv
                    vv=$(item_field "$vid" "version")
                    [[ "$vv" == "$ver" ]] && count=$((count + 1))
                done <<< "$(item_ids)"
                echo -e "    ${BOLD}${ver}${NC}  ${DIM}(${count})${NC}"
            fi
        done <<< "$(item_ids)"
        [[ ${#versions[@]} -eq 0 ]] && echo -e "  ${DIM}No version-tagged items. Tag with: founder todo edit <id> version v9.4${NC}"
        echo ""
    else
        # Show items for a specific version
        echo ""
        echo -e "  ${BOLD}${version_tag}${NC}"
        echo ""
        local found_any=false
        while IFS= read -r id; do
            [[ -z "$id" ]] && continue
            local ver
            ver=$(item_field "$id" "version")
            if [[ "$ver" == "$version_tag" ]]; then
                print_item "$id"
                found_any=true
            fi
        done <<< "$(item_ids)"
        $found_any || echo -e "  ${DIM}No items tagged '${version_tag}'${NC}"
        echo ""
    fi
}

cmd_all() {
    if ! todo_exists; then
        echo -e "  ${DIM}No todos.yml${NC}"
        return 0
    fi

    echo ""

    # Active
    local active_items
    active_items=$(collect_items "active" "")
    if [[ -n "$active_items" ]]; then
        echo -e "  ${GREEN}▸${NC} ${BOLD}Active${NC}"
        echo ""
        while IFS='|' read -r _ id; do
            [[ -z "$id" ]] && continue
            print_item "$id"
        done <<< "$active_items"
        echo ""
    fi

    # Backlog
    local backlog_items
    backlog_items=$(collect_items "backlog" "")
    if [[ -n "$backlog_items" ]]; then
        echo -e "  ${CYAN}◆${NC} ${BOLD}Backlog${NC}"
        echo ""
        while IFS='|' read -r _ id; do
            [[ -z "$id" ]] && continue
            print_item "$id"
        done <<< "$backlog_items"
        echo ""
    fi

    # Done
    local done_items
    done_items=$(collect_items "done" "")
    if [[ -n "$done_items" ]]; then
        echo -e "  ${DIM}Done${NC}"
        echo ""
        while IFS='|' read -r _ id; do
            [[ -z "$id" ]] && continue
            print_item "$id"
        done <<< "$done_items"
        echo ""
    fi
}

cmd_health() {
    if ! todo_exists; then
        echo -e "  ${DIM}No todos.yml — backlog is empty${NC}"
        return 0
    fi

    validate_yaml || return 1

    echo ""
    echo -e "  ${BOLD}Backlog health${NC}"
    echo ""

    # ── Status counts ───────────────────────────────────
    local total active_ct backlog_ct done_ct stale_ct
    total=$(grep -c '^ *- id:' "$BACKLOG_FILE" 2>/dev/null) || true
    active_ct=0; backlog_ct=0; done_ct=0; stale_ct=0
    while IFS= read -r id; do
        [[ -z "$id" ]] && continue
        local st
        st=$(item_field "$id" "status")
        case "$st" in
            active)  active_ct=$((active_ct + 1)) ;;
            done)    done_ct=$((done_ct + 1)) ;;
            stale)   stale_ct=$((stale_ct + 1)) ;;
            *)       backlog_ct=$((backlog_ct + 1)) ;;
        esac
    done <<< "$(item_ids)"

    local open_ct=$((active_ct + backlog_ct + stale_ct))
    echo -e "  ${BOLD}total${NC}: ${total:-0}  ${GREEN}active${NC}: ${active_ct}  ${CYAN}backlog${NC}: ${backlog_ct}  ${GREEN}done${NC}: ${done_ct}  ${YELLOW}stale${NC}: ${stale_ct}"
    if [[ "${total:-0}" -gt 0 ]]; then
        echo -e "  completion: $((done_ct * 100 / total))%"
    fi
    echo ""

    # ── Age distribution ────────────────────────────────
    local fresh=0 week=0 fortnight=0 month=0 no_date=0
    while IFS= read -r id; do
        [[ -z "$id" ]] && continue
        local st
        st=$(item_field "$id" "status")
        [[ "$st" == "done" ]] && continue

        local age
        age=$(item_age_days "$id")
        if [[ -z "$age" ]]; then
            no_date=$((no_date + 1))
        elif [[ "$age" -ge 30 ]]; then
            month=$((month + 1))
        elif [[ "$age" -ge 14 ]]; then
            fortnight=$((fortnight + 1))
        elif [[ "$age" -ge 7 ]]; then
            week=$((week + 1))
        else
            fresh=$((fresh + 1))
        fi
    done <<< "$(item_ids)"

    echo -e "  ${BOLD}age (open items)${NC}"
    echo -e "    <7d: ${fresh}  7-14d: ${week}  14-30d: ${fortnight}  >30d: ${month}"
    [[ "$no_date" -gt 0 ]] && echo -e "    ${DIM}no date: ${no_date}${NC}"
    echo ""

    # ── By feature ──────────────────────────────────────
    echo -e "  ${BOLD}by feature${NC}"
    local untagged=0
    local feat_data=""  # newline-separated feature names (one per open item)
    while IFS= read -r id; do
        [[ -z "$id" ]] && continue
        local st feat
        st=$(item_field "$id" "status")
        [[ "$st" == "done" ]] && continue
        feat=$(item_field "$id" "feature")
        if [[ -z "$feat" || "$feat" == '""' ]]; then
            untagged=$((untagged + 1))
        else
            feat_data="${feat_data}${feat}"$'\n'
        fi
    done <<< "$(item_ids)"

    # Count and sort features (bash 3.2 compatible — no associative arrays)
    if [[ -n "$feat_data" ]]; then
        echo "$feat_data" | grep -v '^$' | sort | uniq -c | sort -rn | while read -r cnt feat; do
            if [[ "$cnt" -ge 3 ]]; then
                echo -e "    ${BOLD}${feat}${NC}: ${cnt}  ${YELLOW}(cluster)${NC}"
            else
                echo -e "    ${feat}: ${cnt}"
            fi
        done
    fi
    [[ "$untagged" -gt 0 ]] && echo -e "    ${DIM}untagged: ${untagged}${NC}"
    echo ""

    # ── Velocity ────────────────────────────────────────
    echo -e "  ${BOLD}velocity${NC}"
    local done_with_date=0
    local earliest_done="" latest_done=""
    while IFS= read -r id; do
        [[ -z "$id" ]] && continue
        local st
        st=$(item_field "$id" "status")
        [[ "$st" != "done" ]] && continue

        local done_date
        done_date=$(item_field "$id" "done_at")
        [[ -z "$done_date" || "$done_date" == "null" ]] && continue

        local done_ts
        done_ts=$(date -j -f "%Y-%m-%d" "$done_date" +%s 2>/dev/null || date -d "$done_date" +%s 2>/dev/null || echo "0")
        [[ "$done_ts" == "0" ]] && continue

        done_with_date=$((done_with_date + 1))

        if [[ -z "$earliest_done" ]] || [[ "$done_ts" -lt "$earliest_done" ]]; then
            earliest_done="$done_ts"
        fi
        if [[ -z "$latest_done" ]] || [[ "$done_ts" -gt "$latest_done" ]]; then
            latest_done="$done_ts"
        fi
    done <<< "$(item_ids)"

    if [[ "$done_with_date" -ge 2 && -n "$earliest_done" && -n "$latest_done" ]]; then
        local span_days=$(( (latest_done - earliest_done) / 86400 ))
        if [[ "$span_days" -gt 0 ]]; then
            local span_weeks=$(( (span_days + 6) / 7 ))  # round up
            [[ "$span_weeks" -lt 1 ]] && span_weeks=1
            local per_week=$(( done_with_date / span_weeks ))
            local remainder=$(( (done_with_date * 10 / span_weeks) % 10 ))
            echo -e "    ${done_with_date} items done over ${span_days}d → ${per_week}.${remainder}/week"
        else
            echo -e "    ${done_with_date} items done (same day)"
        fi
    elif [[ "$done_with_date" -eq 1 ]]; then
        echo -e "    ${done_with_date} item done ${DIM}(need 2+ for velocity)${NC}"
    elif [[ "$done_ct" -gt 0 && "$done_with_date" -eq 0 ]]; then
        echo -e "    ${DIM}${done_ct} done items lack done_at dates — mark new completions with 'founder todo done' to track velocity${NC}"
    else
        echo -e "    ${DIM}no completed items yet${NC}"
    fi
    echo ""
}

cmd_sources() {
    if ! todo_exists; then
        echo -e "  ${DIM}No todos.yml${NC}"
        return 0
    fi

    echo ""
    echo -e "  ${BOLD}Backlog sources${NC}"
    echo ""

    # Collect source → count mapping (bash 3.2 compatible)
    local source_data=""
    while IFS= read -r id; do
        [[ -z "$id" ]] && continue
        local src status
        src=$(item_field "$id" "source")
        status=$(item_field "$id" "status")
        [[ -z "$src" ]] && src="manual"
        source_data="${source_data}${src}|${status}"$'\n'
    done <<< "$(item_ids)"

    # Get unique sources
    local sources
    sources=$(echo "$source_data" | grep -v '^$' | cut -d'|' -f1 | sort -u)

    while IFS= read -r src; do
        [[ -z "$src" ]] && continue
        local total_ct open_ct done_ct
        total_ct=$(echo "$source_data" | grep "^${src}|" | wc -l | tr -d ' ')
        done_ct=$(echo "$source_data" | grep "^${src}|done" | wc -l | tr -d ' ')
        open_ct=$((total_ct - done_ct))

        local icon=""
        case "$src" in
            */eval|eval)       icon="${CYAN}/eval${NC}" ;;
            */taste|taste)     icon="${CYAN}/taste${NC}" ;;
            */ideate|ideate)   icon="${CYAN}/ideate${NC}" ;;
            */research|research) icon="${CYAN}/research${NC}" ;;
            manual)            icon="${DIM}manual${NC}" ;;
            import)            icon="${DIM}import${NC}" ;;
            *)                 icon="${DIM}${src}${NC}" ;;
        esac

        echo -e "    ${icon}  ${BOLD}${total_ct}${NC} total  ${open_ct} open  ${done_ct} done"
    done <<< "$sources"

    echo ""
    echo -e "  ${DIM}Evidence-fed backlog — items imported from /eval, /taste, /ideate, /research${NC}"
    echo ""
}

cmd_import() {
    # Read JSON lines from stdin and bulk-add as todo items.
    # Each line: {"title":"...", "priority":"...", "feature":"...", "source":"...", "context":"..."}
    # Only "title" is required. Defaults: priority=medium, source=import, others empty.

    if [[ -t 0 ]]; then
        echo "Usage: <generator> | founder todo import"
        echo ""
        echo "  Reads JSON lines from stdin. Each line is an object with:"
        echo "    title    (required)  — what needs to happen"
        echo "    priority (optional)  — urgent|high|medium|low (default: medium)"
        echo "    feature  (optional)  — feature tag"
        echo "    source   (optional)  — origin skill (default: import)"
        echo "    context  (optional)  — additional context"
        echo ""
        echo "  Example:"
        echo '    echo '"'"'{"title":"fix contrast","feature":"ux","priority":"high"}'"'"' | founder todo import'
        return 1
    fi

    acquire_lock || return 1

    if ! todo_exists; then
        mkdir -p "$(dirname "$BACKLOG_FILE")"
        cat > "$BACKLOG_FILE" << EOF
# todos.yml — Persistent backlog

items:
EOF
    fi

    # Clear empty array literal before first append
    if grep -q '^items: \[\]' "$BACKLOG_FILE"; then
        local _sedtmp="${BACKLOG_FILE}.sedtmp"
        sed 's/^items: \[\]/items:/' "$BACKLOG_FILE" > "$_sedtmp" && mv "$_sedtmp" "$BACKLOG_FILE"
    fi

    local today count=0 skipped=0
    today=$(date '+%Y-%m-%d')

    while IFS= read -r line; do
        [[ -z "$line" ]] && continue

        # Parse JSON fields — uses bash string manipulation to avoid jq dependency
        # But prefer jq if available for robustness
        local title="" priority="medium" feature="" source="import" context=""

        if command -v jq &>/dev/null; then
            title=$(echo "$line" | jq -r '.title // empty' 2>/dev/null)
            priority=$(echo "$line" | jq -r '.priority // "medium"' 2>/dev/null)
            feature=$(echo "$line" | jq -r '.feature // ""' 2>/dev/null)
            source=$(echo "$line" | jq -r '.source // "import"' 2>/dev/null)
            context=$(echo "$line" | jq -r '.context // ""' 2>/dev/null)
        else
            # Minimal fallback: extract title with sed
            title=$(echo "$line" | sed -n 's/.*"title" *: *"\([^"]*\)".*/\1/p')
            priority=$(echo "$line" | sed -n 's/.*"priority" *: *"\([^"]*\)".*/\1/p')
            feature=$(echo "$line" | sed -n 's/.*"feature" *: *"\([^"]*\)".*/\1/p')
            source=$(echo "$line" | sed -n 's/.*"source" *: *"\([^"]*\)".*/\1/p')
            context=$(echo "$line" | sed -n 's/.*"context" *: *"\([^"]*\)".*/\1/p')
            [[ -z "$priority" ]] && priority="medium"
            [[ -z "$source" ]] && source="import"
        fi

        if [[ -z "$title" ]]; then
            skipped=$((skipped + 1))
            continue
        fi

        # Generate ID from title
        local id
        id=$(echo "$title" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr -cd 'a-z0-9-' | head -c 30)

        # Skip duplicates
        if grep -qF "id: ${id}" "$BACKLOG_FILE" 2>/dev/null; then
            skipped=$((skipped + 1))
            continue
        fi

        cat >> "$BACKLOG_FILE" << EOF

  - id: ${id}
    title: "${title}"
    priority: ${priority}
    feature: "${feature}"
    status: backlog
    context: "${context}"
    source: "${source}"
    created_at: ${today}
EOF
        count=$((count + 1))
    done

    release_lock

    echo -e "  ${GREEN}+${NC} imported ${count} item(s)"
    if [[ "$skipped" -gt 0 ]]; then
        echo -e "  ${DIM}skipped ${skipped} (no title or duplicate)${NC}"
    fi
}

cmd_meta() {
    if ! todo_exists; then
        echo -e "  ${DIM}No todos.yml${NC}"
        return 0
    fi

    echo ""
    echo -e "  ${BOLD}Meta-tasks${NC}"
    echo ""

    local suggestions=0

    # 1. Stale items: >14 days untouched, status not done
    while IFS= read -r id; do
        [[ -z "$id" ]] && continue
        local status
        status=$(item_field "$id" "status")
        [[ "$status" == "done" ]] && continue

        local age
        age=$(item_age_days "$id")
        [[ -z "$age" ]] && continue

        if [[ "$age" -ge 14 ]]; then
            local title
            title=$(item_field "$id" "title")
            echo -e "  ${YELLOW}▸${NC} review or kill stale item: ${title}  ${DIM}[${id}] ${age}d${NC}"
            suggestions=$((suggestions + 1))
        fi
    done <<< "$(item_ids)"

    # 2. Graduation candidates: done_count >= 3
    while IFS= read -r id; do
        [[ -z "$id" ]] && continue
        local done_count
        done_count=$(item_field "$id" "done_count")
        done_count=${done_count:-0}
        [[ ! "$done_count" =~ ^[0-9]+$ ]] && continue

        if [[ "$done_count" -ge 3 ]]; then
            local title
            title=$(item_field "$id" "title")
            echo -e "  ${CYAN}▸${NC} graduate recurring item to assertion: ${title}  ${DIM}[${id}] done ${done_count}x${NC}"
            suggestions=$((suggestions + 1))
        fi
    done <<< "$(item_ids)"

    # 3. Features with 0 items
    local founder_yml="$PROJECT_DIR/config/founder.yml"
    [[ ! -f "$founder_yml" ]] && founder_yml="$FOUNDER_DIR/config/founder.yml"
    if [[ -f "$founder_yml" ]]; then
        while IFS= read -r feat_name; do
            [[ -z "$feat_name" ]] && continue
            local has_items=false
            while IFS= read -r id; do
                [[ -z "$id" ]] && continue
                local feat
                feat=$(item_field "$id" "feature")
                if [[ "$feat" == "$feat_name" ]]; then
                    has_items=true
                    break
                fi
            done <<< "$(item_ids)"
            if ! $has_items; then
                echo -e "  ${DIM}▸${NC} capture ideas for ${BOLD}${feat_name}${NC}"
                suggestions=$((suggestions + 1))
            fi
        done < <(awk '/^  features:/,/^[^ ]/' "$founder_yml" 2>/dev/null | grep -E '^\s+[a-z]' | sed 's/:.*//' | tr -d ' ')
    fi

    if [[ "$suggestions" -eq 0 ]]; then
        echo -e "  ${GREEN}✓${NC} no meta-tasks — backlog is healthy"
    else
        echo ""
        echo -e "  ${DIM}${suggestions} suggestion(s)${NC}"
    fi
    echo ""
}

# ── Main ────────────────────────────────────────────────

case "${1:-show}" in
    show|list|"") cmd_show ;;
    add)          shift; cmd_add "${1:-}" "${2:-medium}" ;;
    done|rm)      shift; cmd_done "${1:-}" ;;
    edit)         shift; cmd_edit "${1:-}" "${2:-}" "${3:-}" ;;
    tag)          shift; cmd_tag "${1:-}" "${2:-}" ;;
    promote)      shift; cmd_promote "${1:-}" ;;
    active)       cmd_active ;;
    feature)      shift; cmd_feature "${1:-}" ;;
    version)      shift; cmd_version "${1:-}" ;;
    all)          cmd_all ;;
    decay)        cmd_decay ;;
    health)       cmd_health ;;
    sources)      cmd_sources ;;
    import)       cmd_import ;;
    meta)         cmd_meta ;;
    *)
        echo "Usage: founder todo [show|add|done|edit|tag|promote|active|feature|version|all|decay|health|sources|import|meta]"
        echo ""
        echo "  show              Show todos (default)"
        echo "  add \"title\" [pri] Add a todo (auto-tags feature from title)"
        echo "  done <id>         Mark done + graduation check"
        echo "  edit <id> <f> <v> Update a field"
        echo "  tag <id> <feat>   Tag with feature"
        echo "  promote           Smart promote — suggest from bottleneck feature"
        echo "  promote <id>      Set active, add to plan"
        echo "  active            Show active only"
        echo "  feature [name]    Filter by feature"
        echo "  version [tag]     Filter by version tag"
        echo "  all               All sections"
        echo "  decay             Check stale items, auto-tag 30d+ as stale"
        echo "  health            Backlog health stats"
        echo "  sources           Where todos came from — /eval, /taste, /ideate, manual"
        echo "  import            Bulk-add from stdin (JSON lines)"
        echo "  meta              Suggest meta-tasks — stale items, graduation, empty features"
        exit 1
        ;;
esac
