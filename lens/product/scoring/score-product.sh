#!/usr/bin/env bash
# score-product.sh — Product lens scoring extensions for score.sh.
# Sourced by score.sh when present. Adds web-specific structure and hygiene checks.
#
# Provides:
#   score_structure_product $current_score $SRC_DIR $PROJECT_TYPE $COMP_EXT
#   score_hygiene_product $current_score $SRC_DIR $PROJECT_TYPE $COMP_EXT $density_mult

# ============================================================
# Product structure checks — web dead ends, empty states, IA audit
# ============================================================
score_structure_product() {
    local score=$1
    local src_dir="$2"
    local project_type="$3"
    local comp_ext="$4"

    [[ -z "$src_dir" ]] && echo "$score" && return

    # Only apply to web project types
    case "$project_type" in
        nextjs|react|vue|svelte) ;;
        *) echo "$score" && return ;;
    esac

    # Read weights from config (these are divisors: dead_pct / weight)
    local dead_end_div=2    # default: dead_pct / 2
    local empty_div=3       # default: missing_pct / 3
    local de_cfg=$(cfg scoring.structure.dead_end_weight "")
    local es_cfg=$(cfg scoring.structure.empty_state_weight "")
    [[ "$de_cfg" == "0.5" ]] && dead_end_div=2
    [[ "$de_cfg" == "0.25" ]] && dead_end_div=4
    [[ "$de_cfg" == "1" ]] && dead_end_div=1
    [[ "$es_cfg" == "0.33" ]] && empty_div=3
    [[ "$es_cfg" == "0.5" ]] && empty_div=2
    [[ "$es_cfg" == "0.25" ]] && empty_div=4

    # Pages with no outbound navigation = dead ends
    local total_pages
    total_pages=$(find "$src_dir" -name "page.$comp_ext" -o -name "index.$comp_ext" 2>/dev/null | wc -l | tr -d ' ')
    [[ "$total_pages" -eq 0 ]] && total_pages=1

    local dead_ends=0
    dead_ends=$(find "$src_dir" -name "page.$comp_ext" 2>/dev/null | while read -r f; do
        if ! grep -ql "Link\|href\|router\|navigate\|onClick" "$f" 2>/dev/null; then
            echo "$f"
        fi
    done | wc -l | tr -d ' ')

    if [[ "$dead_ends" -gt 0 ]]; then
        local dead_pct=$((dead_ends * 100 / total_pages))
        local dead_penalty=$((dead_pct / dead_end_div))
        score=$((score - dead_penalty))
        [[ "$dead_penalty" -gt 0 ]] && add_reason STRUCTURE_REASONS "$dead_ends dead-end pages, no outbound links (-$dead_penalty)"
    fi

    # Empty states without guidance
    local empty_states
    empty_states=$(grep -rn "empty\|no.*yet\|nothing.*here\|get started" --include="*.$comp_ext" "$src_dir" -l 2>/dev/null | wc -l | tr -d ' ')
    local empty_with_cta
    empty_with_cta=$(grep -rn "empty\|no.*yet\|nothing.*here\|get started" --include="*.$comp_ext" "$src_dir" -l 2>/dev/null | xargs grep -l "Link\|button\|onClick\|href" 2>/dev/null | wc -l | tr -d ' ')

    if [[ "$empty_states" -gt 0 ]]; then
        local cta_pct=$((empty_with_cta * 100 / empty_states))
        local missing_pct=$((100 - cta_pct))
        local empty_penalty=$((missing_pct / empty_div))
        score=$((score - empty_penalty))
        [[ "$empty_penalty" -gt 0 ]] && add_reason STRUCTURE_REASONS "$((empty_states - empty_with_cta)) empty states without CTAs (-$empty_penalty)"
    fi

    [[ "$score" -lt 0 ]] && score=0
    echo "$score"
}

# ============================================================
# Product hygiene checks — :any types, console.log in TSX,
# unused imports, lint overrides
# ============================================================
score_hygiene_product() {
    local score=$1
    local src_dir="$2"
    local project_type="$3"
    local comp_ext="$4"
    local density_mult="${5:-100}"

    [[ -z "$src_dir" ]] && echo "$score" && return

    # Only apply to web project types
    case "$project_type" in
        nextjs|react|vue|svelte|node) ;;
        *) echo "$score" && return ;;
    esac

    # Count total source files for monorepo scaling
    local _total_src_files
    _total_src_files=$(find "$src_dir" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.mjs" \) ! -path "*/node_modules/*" 2>/dev/null | wc -l | tr -d ' ')

    # Monorepo dampener: scale thresholds up for large codebases
    # 100+ files → 3x thresholds, 500+ → 5x, 1000+ → 10x
    local _threshold_mult=1
    if [[ "$_total_src_files" -gt 1000 ]]; then _threshold_mult=10
    elif [[ "$_total_src_files" -gt 500 ]]; then _threshold_mult=5
    elif [[ "$_total_src_files" -gt 100 ]]; then _threshold_mult=3
    fi

    _product_tiered_penalty() {
        local count=$1 defaults="$2" label="${3:-}"
        local pair threshold penalty
        for pair in $defaults; do
            threshold="${pair%%:*}"
            penalty="${pair#*:}"
            # Scale threshold by monorepo size
            local adj_threshold=$(( threshold * _threshold_mult ))
            if [[ "$count" -gt "$adj_threshold" ]]; then
                local scaled=$(( penalty * density_mult / 100 ))
                local cap=$(( penalty * 3 ))
                [[ "$scaled" -lt "$cap" ]] && scaled="$cap"
                score=$((score + scaled))
                [[ -n "$label" ]] && add_reason HYGIENE_REASONS "$count $label ($scaled)"
                return
            fi
        done
    }

    # `any` types — real type safety gap
    local any_count
    any_count=$(grep -rn ": any\b" --include="*.ts" --include="*.tsx" "$src_dir" 2>/dev/null | grep -v "node_modules\|\.d\.ts" | wc -l | tr -d ' ')
    _product_tiered_penalty "$any_count" "50:-30 20:-20 5:-10 1:-3" ":any types"

    # console.log in production code
    local console_count
    console_count=$(grep -rn "console\.\(log\|warn\|error\)" --include="*.ts" --include="*.$comp_ext" "$src_dir" 2>/dev/null | grep -v "node_modules\|test\|spec\|__test__\|logger" | wc -l | tr -d ' ')
    _product_tiered_penalty "$console_count" "30:-25 15:-15 5:-5 1:-3" "console.log in prod code"

    # Unfinished work markers (comment-style only, not variable names)
    local todo_count
    todo_count=$(grep -rn '//[[:space:]]*\(TODO\|FIXME\|HACK\|XXX\)\|/\*[[:space:]]*\(TODO\|FIXME\|HACK\|XXX\)\|#[[:space:]]*\(TODO\|FIXME\|HACK\|XXX\)' --include="*.ts" --include="*.$comp_ext" "$src_dir" 2>/dev/null | grep -v "node_modules" | wc -l | tr -d ' ')
    _product_tiered_penalty "$todo_count" "30:-20 15:-10 5:-5 1:-3" "TODO/FIXME markers"

    # Unused imports (rough signal — files with 10+ imports are suspicious)
    local large_import_files
    large_import_files=$(grep -rn "^import " --include="*.ts" --include="*.$comp_ext" "$src_dir" 2>/dev/null | \
        awk -F: '{print $1}' | sort | uniq -c | sort -rn | awk '$1 > 15 {count++} END {print count+0}')
    _product_tiered_penalty "$large_import_files" "10:-15 5:-10" "files with 15+ imports"

    # Disabled lint rules — eslint-disable, @ts-ignore, @ts-expect-error
    local lint_overrides
    lint_overrides=$(grep -rn "eslint-disable\|@ts-ignore\|@ts-expect-error\|@ts-nocheck" --include="*.ts" --include="*.$comp_ext" "$src_dir" 2>/dev/null | grep -v "node_modules" | wc -l | tr -d ' ')
    _product_tiered_penalty "$lint_overrides" "20:-15 10:-10 3:-5 1:-3" "lint overrides"

    [[ "$score" -lt 0 ]] && score=0
    echo "$score"
}
