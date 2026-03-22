#!/usr/bin/env bash
set -uo pipefail
# NOTE: set -e intentionally omitted. Scoring uses [[ ]] && pattern
# where false conditions return 1 — that's normal, not an error.

# score.sh — The number. Measures value, not health.
#
# ┌─────────────────────────────────────────────────────────────┐
# │                     SCORING FORMULA                         │
# │                                                             │
# │  1. BUILD GATE (pass/fail)                                  │
# │     Build health < 70 → score = 0. Nothing else runs.      │
# │                                                             │
# │  2. HEALTH GATE (pass/fail)                                 │
# │     min(structure, hygiene) < 20 → score = 0.               │
# │     Structure: large files, deep nesting, tests, dead ends  │
# │     Hygiene: TODOs, console.log density, syntax errors      │
# │     Health is a GATE, not a component of the score.         │
# │                                                             │
# │  3. VALUE SCORE (the actual number, 0-100)                  │
# │     Three modes, checked in order:                          │
# │                                                             │
# │     a) ASSERTIONS MODE (beliefs.yml has entries)            │
# │        score = (PASS*100 + WARN*50) / TOTAL assertions      │
# │        This is the north star. eval.sh runs all assertions  │
# │        and returns a pass rate.                             │
# │                                                             │
# │     b) ONBOARDING MODE (founder.yml has value hypothesis)     │
# │        score = completion ratchet (0-50, capped):           │
# │          +10 value.hypothesis defined                       │
# │          +5  value.signals defined                          │
# │          +5  tests exist                                    │
# │          +10 beliefs.yml exists                             │
# │          +10 beliefs.yml has 1+ entries                     │
# │          +10 at least 1 assertion passes                    │
# │        Guides new projects toward full assertion scoring.   │
# │                                                             │
# │     c) EMPTY MODE (nothing defined)                         │
# │        score = 10. Baseline for unconfigured projects.      │
# │                                                             │
# │  Output: single integer 0-100.                              │
# │  Cache: .claude/cache/score-cache.json (5min TTL,            │
# │         auto-invalidated when source files change).          │
# │  History: .claude/scores/history.tsv (append-only).         │
# └─────────────────────────────────────────────────────────────┘
#
# Usage:
#   score.sh [project-dir]              # visual output (default)
#   score.sh [project-dir] --json       # machine-readable
#   score.sh [project-dir] --quiet      # single number for scripts
#   score.sh [project-dir] --force      # bypass 5min cache

PROJECT_DIR="."
OUTPUT_MODE="score"
FORCE=false
INTEGRITY_WARNINGS=""

for arg in "$@"; do
    case $arg in
        --json) OUTPUT_MODE="json" ;;
        --quiet|-q) OUTPUT_MODE="quiet" ;;
        --trend) OUTPUT_MODE="trend" ;;
        --force) FORCE=true ;;
        --help|-h)
            echo "Usage: score.sh [project-dir] [--json] [--quiet] [--trend] [--force]"
            exit 0
            ;;
        -*) ;;
        *) PROJECT_DIR="$arg" ;;
    esac
done

# Resolve script dir before cd (so relative $0 still works)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Validate target directory exists before cd
if [[ ! -d "$PROJECT_DIR" ]]; then
    echo "  error: directory not found: $PROJECT_DIR" >&2
    exit 1
fi

cd "$PROJECT_DIR"

# --- Cross-platform file mtime (epoch seconds) ---
file_mtime() {
    local file="$1"
    [[ ! -f "$file" && ! -d "$file" ]] && echo "0" && return
    stat -f %m "$file" 2>/dev/null || stat -c %Y "$file" 2>/dev/null || echo "0"
}

# --- Config ---
source "$SCRIPT_DIR/lib/config.sh"

# --- Lens extensions ---
FOUNDER_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
# Source all lens scoring extensions
for _lens_score in "$FOUNDER_ROOT"/lens/*/scoring/score-*.sh; do
    [[ -f "$_lens_score" ]] && source "$_lens_score"
done

# --- Reasons (why the score is what it is) ---
# Uses temp files because scoring functions run in subshells via $()
REASONS_DIR=$(mktemp -d)
: > "$REASONS_DIR/build"
: > "$REASONS_DIR/structure"
: > "$REASONS_DIR/hygiene"

add_reason() {
    local category="$1" msg="$2"
    case "$category" in
        BUILD_REASONS)   echo "$msg" >> "$REASONS_DIR/build" ;;
        STRUCTURE_REASONS) echo "$msg" >> "$REASONS_DIR/structure" ;;
        HYGIENE_REASONS) echo "$msg" >> "$REASONS_DIR/hygiene" ;;
    esac
}

cleanup_reasons() {
    rm -rf "$REASONS_DIR" 2>/dev/null
}

# --- Spinner ---
SPINNER_PID=""
spin() {
    local msg="$1"
    local chars='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    printf '\033[2m' >&2
    while true; do
        for (( i=0; i<${#chars}; i++ )); do
            printf "\r  %s %s" "${chars:$i:1}" "$msg" >&2
            sleep 0.1
        done
    done
}

start_spinner() {
    [[ "$OUTPUT_MODE" == "quiet" || "$OUTPUT_MODE" == "json" ]] && return
    { spin "$1" & } 2>/dev/null
    SPINNER_PID=$!
}

stop_spinner() {
    local result="${1:-done}"
    if [[ -n "$SPINNER_PID" ]]; then
        kill "$SPINNER_PID" 2>/dev/null
        wait "$SPINNER_PID" 2>/dev/null || true
        SPINNER_PID=""
    fi
    if [[ "$OUTPUT_MODE" != "quiet" && "$OUTPUT_MODE" != "json" ]]; then printf "\r  ✓ %s\033[0m\n" "$result" >&2; fi
}

cleanup_spinner() {
    if [[ -n "$SPINNER_PID" ]]; then
        kill "$SPINNER_PID" 2>/dev/null
        wait "$SPINNER_PID" 2>/dev/null || true
        printf "\033[0m\n" >&2
    fi
}
trap 'cleanup_spinner; cleanup_reasons' EXIT

# --- Cache ---
CACHE_DIR=".claude/cache"
CACHE_FILE="$CACHE_DIR/score-cache.json"
CACHE_MAX_AGE=$(cfg scoring.cache_ttl 300)

if [[ "$FORCE" != true && -f "$CACHE_FILE" ]]; then
    cache_mtime=$(file_mtime "$CACHE_FILE")
    cache_age=$(( $(date +%s) - cache_mtime ))

    # Invalidate cache if any project file changed since the cache was written.
    # Uses find to check for files newer than the cache in likely source dirs.
    cache_stale=false
    for _dir in bin src app commands config mind lens lib utils types server pages skills hooks; do
        if [[ -d "$_dir" ]]; then
            if find "$_dir" -type f -newer "$CACHE_FILE" -print -quit 2>/dev/null | grep -q .; then
                cache_stale=true
                break
            fi
        fi
    done
    # Also check top-level config files
    if [[ "$cache_stale" != true ]]; then
        for _f in founder.yml config/founder.yml package.json tsconfig.json; do
            if [[ -f "$_f" ]] && [[ $(file_mtime "$_f") -gt "$cache_mtime" ]]; then
                cache_stale=true
                break
            fi
        done
    fi

    if [[ "$cache_stale" != true && "$cache_age" -lt "$CACHE_MAX_AGE" ]]; then
        case "$OUTPUT_MODE" in
            quiet)
                if command -v jq &>/dev/null; then
                    cached_score=$(jq -r '.score // empty' "$CACHE_FILE" 2>/dev/null)
                else
                    # Fallback: extract score from JSON without jq
                    cached_score=$(grep -o '"score":[0-9]*' "$CACHE_FILE" 2>/dev/null | head -1 | grep -o '[0-9]*$')
                fi
                if [[ -n "$cached_score" && "$cached_score" != "null" ]]; then
                    echo "$cached_score"
                    exit 0
                fi
                ;;
            json) cat "$CACHE_FILE" 2>/dev/null && exit 0 ;;
            score)
                printf '\033[2m  (cached %ds ago, use --force to refresh)\033[0m\n' "$cache_age" >&2
                ;;
        esac
    fi
fi

# --- Detect project ---
PROJECT_TYPE="unknown"
SRC_DIR=""

if [[ -f "package.json" ]]; then
    if grep -q '"next"' package.json 2>/dev/null; then PROJECT_TYPE="nextjs"
    elif grep -q '"react"' package.json 2>/dev/null; then PROJECT_TYPE="react"
    elif grep -q '"vue"' package.json 2>/dev/null; then PROJECT_TYPE="vue"
    elif grep -q '"svelte"' package.json 2>/dev/null; then PROJECT_TYPE="svelte"
    else PROJECT_TYPE="node"
    fi
fi

# Detect CLI/shell projects (like founder-os itself)
if [[ "$PROJECT_TYPE" == "unknown" ]]; then
    if [[ -d "bin" ]] && find bin -maxdepth 1 \( -name "*.sh" -o -name "*.mjs" \) -print -quit 2>/dev/null | grep -q .; then
        PROJECT_TYPE="cli"
    fi
fi

if [[ -d "apps/web/src" ]]; then SRC_DIR="apps/web/src"
elif [[ -d "src" ]]; then SRC_DIR="src"
elif [[ -d "app" ]]; then SRC_DIR="app"
elif [[ "$PROJECT_TYPE" == "cli" ]]; then SRC_DIR="bin"
fi

COMP_EXT="tsx"
[[ "$PROJECT_TYPE" == "vue" ]] && COMP_EXT="vue"
[[ "$PROJECT_TYPE" == "svelte" ]] && COMP_EXT="svelte"

# ============================================================
# 1. BUILD HEALTH (gate: pass/fail)
# ============================================================
score_build_health() {
    local score=100
    local ts_penalty=$(cfg scoring.build.ts_error_penalty -30)
    local stale_penalty=$(cfg scoring.build.stale_build_penalty -10)
    local fail_penalty=$(cfg scoring.build.build_fail_penalty -50)

    if [[ -f "tsconfig.json" ]] || [[ -f "apps/web/tsconfig.json" ]]; then
        if [[ "$FORCE" == true ]] && [[ -d "node_modules" ]]; then
            local ts_errors
            ts_errors=$(npx tsc --noEmit 2>&1 | grep -c "error TS" || true)
            if [[ "$ts_errors" -gt 0 ]]; then
                score=$((score + ts_penalty))
                add_reason BUILD_REASONS "$ts_errors TypeScript errors ($ts_penalty)"
            fi
        else
            local has_build=false
            local build_age=999999
            if [[ -d ".next" ]]; then
                has_build=true
                build_age=$(( $(date +%s) - $(file_mtime ".next") ))
            elif [[ -d "dist" ]]; then
                has_build=true
                build_age=$(( $(date +%s) - $(file_mtime "dist") ))
            elif [[ -d "apps/web/.next" ]]; then
                has_build=true
                build_age=$(( $(date +%s) - $(file_mtime "apps/web/.next") ))
            fi
            if ! $has_build && [[ -d "node_modules" ]]; then
                score=$((score + ts_penalty))
                add_reason BUILD_REASONS "no build output found ($ts_penalty)"
            elif ! $has_build; then
                # No node_modules = deps not installed, don't penalize for missing build
                true
            elif [[ "$build_age" -gt 86400 ]]; then
                score=$((score + stale_penalty))
                add_reason BUILD_REASONS "build >24h old ($stale_penalty)"
            fi
        fi
    fi

    if grep -q '"build"' package.json 2>/dev/null; then
        if [[ "$FORCE" == true ]] && [[ -d "node_modules" ]]; then
            if ! npm run build > /dev/null 2>&1; then
                score=$((score + fail_penalty))
                add_reason BUILD_REASONS "build command failed ($fail_penalty)"
            fi
        fi
    fi

    echo "$score"
}

# ============================================================
# 2. STRUCTURE (0-100, subtractive)
#    Dead ends, empty states without CTAs, navigation gaps.
#    Things grep can measure: "does this page link anywhere?"
# ============================================================
score_structure() {
    [[ -z "$SRC_DIR" ]] && echo "50" && return

    local score=100

    # --- Universal structure checks (all project types) ---

    # Large files: >500 lines suggests missing decomposition
    # Scale thresholds by project size — a monorepo with 500 files tolerates more large files
    local large_files=0
    local total_files=0
    while IFS= read -r f; do
        [[ ! -f "$f" ]] && continue
        total_files=$((total_files + 1))
        local lines
        lines=$(wc -l < "$f" 2>/dev/null | tr -d ' ')
        [[ "$lines" -gt 500 ]] && large_files=$((large_files + 1))
    done < <(find "$SRC_DIR" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.mjs" -o -name "*.sh" -o -name "*.py" \) ! -path "*/node_modules/*" ! -path "*/.next/*" ! -name "*.d.ts" ! -name "*.min.*" 2>/dev/null)
    # Use ratio for large projects (100+ files), absolute count for small projects
    if [[ "$total_files" -gt 100 ]]; then
        local large_pct=$(( large_files * 100 / total_files ))
        if [[ "$large_pct" -gt 50 ]]; then score=$((score - 15)); add_reason STRUCTURE_REASONS "${large_pct}% large files ($large_files/$total_files >500 lines) (-15)"
        elif [[ "$large_pct" -gt 30 ]]; then score=$((score - 10)); add_reason STRUCTURE_REASONS "${large_pct}% large files ($large_files/$total_files >500 lines) (-10)"
        elif [[ "$large_pct" -gt 15 ]]; then score=$((score - 5)); add_reason STRUCTURE_REASONS "${large_pct}% large files ($large_files/$total_files >500 lines) (-5)"
        fi
    else
        if [[ "$large_files" -gt 10 ]]; then score=$((score - 15)); add_reason STRUCTURE_REASONS "$large_files large files >500 lines (-15)"
        elif [[ "$large_files" -gt 5 ]]; then score=$((score - 10)); add_reason STRUCTURE_REASONS "$large_files large files >500 lines (-10)"
        elif [[ "$large_files" -gt 2 ]]; then score=$((score - 5)); add_reason STRUCTURE_REASONS "$large_files large files >500 lines (-5)"
        fi
    fi

    # Deep nesting: files nested >5 levels deep suggest poor organization
    local deep_files=0
    deep_files=$(find "$SRC_DIR" -mindepth 6 -type f ! -path "*/node_modules/*" ! -path "*/.next/*" 2>/dev/null | wc -l | tr -d ' ')
    if [[ "$deep_files" -gt 20 ]]; then score=$((score - 10)); add_reason STRUCTURE_REASONS "$deep_files deeply nested files (-10)"
    elif [[ "$deep_files" -gt 5 ]]; then score=$((score - 5)); add_reason STRUCTURE_REASONS "$deep_files deeply nested files (-5)"
    fi

    # Test presence: no tests at all is a structural gap
    local has_tests=0
    if [[ -d "tests" ]] || [[ -d "test" ]] || [[ -d "__tests__" ]]; then
        has_tests=1
    elif find . -maxdepth 5 -type f \( -name "*.test.*" -o -name "*.spec.*" -o -name "*_test.*" -o -name "*.test.sh" \) ! -path "*/node_modules/*" -print -quit 2>/dev/null | grep -q .; then
        has_tests=1
    fi
    if [[ "$has_tests" -eq 0 ]]; then
        score=$((score - 10))
        add_reason STRUCTURE_REASONS "no test files found (-10)"
    fi

    # CLI projects: score structure differently than web projects
    if [[ "$PROJECT_TYPE" == "cli" ]]; then
        # Broken references: agent/program files referencing non-existent paths
        local broken_refs=0
        for f in agents/*.md programs/*.md; do
            [[ ! -f "$f" ]] && continue
            # Check for file path references that don't exist
            while IFS= read -r ref; do
                ref=$(echo "$ref" | sed 's/`//g' | xargs 2>/dev/null)
                [[ -z "$ref" ]] && continue
                # Skip glob patterns (*, ?) — these are templates, not literal paths
                [[ "$ref" == *'*'* || "$ref" == *'?'* ]] && continue
                # Skip refs containing newlines or spaces (multi-line false positives)
                [[ "$ref" == *$'\n'* || "$ref" == *" "* ]] && continue
                # Skip refs that are clearly not file paths (contain brackets, etc.)
                [[ "$ref" == *'['* || "$ref" == *'('* || "$ref" == *'{'* ]] && continue
                # Skip slash commands (e.g. /taste, /plan, /go)
                [[ "$ref" =~ ^/[a-z]+$ ]] && continue
                # Only check refs that look like file paths (contain / or end with known extensions)
                if [[ "$ref" == */* || "$ref" == *.sh || "$ref" == *.md || "$ref" == *.yml || "$ref" == *.json || "$ref" == *.mjs ]]; then
                    # Expand ~ to $HOME
                    local expanded="${ref/#\~/$HOME}"
                    if [[ ! -e "$expanded" && ! -e "$ref" ]]; then
                        broken_refs=$((broken_refs + 1))
                    fi
                fi
            done < <(grep -oE '`[~./][^`]+`' "$f" 2>/dev/null | sed 's/`//g')
        done
        if [[ "$broken_refs" -gt 10 ]]; then score=$((score - 30)); add_reason STRUCTURE_REASONS "$broken_refs broken file references (-30)"
        elif [[ "$broken_refs" -gt 5 ]]; then score=$((score - 20)); add_reason STRUCTURE_REASONS "$broken_refs broken file references (-20)"
        elif [[ "$broken_refs" -gt 0 ]]; then score=$((score - 10)); add_reason STRUCTURE_REASONS "$broken_refs broken file references (-10)"
        fi

        # Dead commands: functions/commands defined in bin/founder but unreachable
        local total_commands=0 documented_commands=0
        if [[ -f "bin/founder" ]]; then
            total_commands=$(grep -cE '^\s+[a-z_-]+\)' bin/founder 2>/dev/null) || total_commands=0
            # Check if help text documents them
            documented_commands=$(grep -cE '^\s+[a-z_-]+\s' bin/founder 2>/dev/null | head -1) || documented_commands=0
        fi

        # Config coherence: does founder.yml reference things that exist in code?
        if [[ -f "config/founder.yml" ]]; then
            # Check if dimensions listed in config (base or lens) match what taste.mjs scores
            local config_dims
            config_dims=$(grep -h -A20 'dimensions:' config/founder.yml lens/*/config/founder-*.yml 2>/dev/null | grep '^ *-' | wc -l | tr -d ' ')
            if [[ "$config_dims" -eq 0 ]]; then
                score=$((score - 10))
                add_reason STRUCTURE_REASONS "no config dimensions defined (-10)"
            fi
        fi

        [[ "$score" -lt 0 ]] && score=0
        echo "$score"
        return
    fi

    # Lens structure checks (dynamic discovery)
    for _fn in $(compgen -A function | grep '^score_structure_'); do
        score=$("$_fn" "$score" "$SRC_DIR" "$PROJECT_TYPE" "$COMP_EXT")
    done

    [[ "$score" -lt 0 ]] && score=0
    echo "$score"
}

# ============================================================
# 3. HYGIENE (0-100, subtractive)
#    Code debt that grep can count. Not opinions about UX.
#    Starts at 100, deducts for measurable problems.
# ============================================================
score_hygiene() {
    [[ -z "$SRC_DIR" ]] && echo "50" && return

    local score=100

    # Measure codebase size for density-based scoring
    # Small projects (<500 lines) get stricter thresholds via a multiplier
    local total_src_lines=0
    total_src_lines=$(find "$SRC_DIR" -type f \( -name "*.ts" -o -name "*.tsx" -o -name "*.js" -o -name "*.mjs" -o -name "*.sh" -o -name "*.py" \) ! -path "*/node_modules/*" ! -path "*/.next/*" 2>/dev/null -exec cat {} + 2>/dev/null | wc -l | tr -d ' ')
    [[ "$total_src_lines" -eq 0 ]] && total_src_lines=1

    # Density multiplier: penalties are more severe for smaller codebases
    # CLI projects opt out — console output and TODOs in scripts are structurally different
    # <200 lines → 3x penalty, <1000 → 2x, <5000 → 1.5x, ≥5000 → 1x
    local density_mult=100  # stored as percentage to avoid floats
    if [[ "$PROJECT_TYPE" != "cli" ]]; then
        if [[ "$total_src_lines" -lt 200 ]]; then density_mult=300
        elif [[ "$total_src_lines" -lt 1000 ]]; then density_mult=200
        elif [[ "$total_src_lines" -lt 5000 ]]; then density_mult=150
        fi
    fi

    # Helper: tiered penalty from config. Usage: tiered_penalty count "50:-30 20:-20 5:-10" "label"
    # Thresholds checked from highest to lowest. Penalty scaled by density_mult.
    tiered_penalty() {
        local count=$1 defaults="$2" label="${3:-}"
        local pair threshold penalty
        for pair in $defaults; do
            threshold="${pair%%:*}"
            penalty="${pair#*:}"
            if [[ "$count" -gt "$threshold" ]]; then
                # Scale penalty by density multiplier (negative * positive / 100 stays negative)
                local scaled=$(( penalty * density_mult / 100 ))
                # Cap: never deduct more than 3x the base penalty
                local cap=$(( penalty * 3 ))
                [[ "$scaled" -lt "$cap" ]] && scaled="$cap"
                score=$((score + scaled))
                [[ -n "$label" ]] && add_reason HYGIENE_REASONS "$count $label ($scaled)"
                return
            fi
        done
    }

    if [[ "$PROJECT_TYPE" == "cli" ]]; then
        # CLI hygiene: check shell scripts and JS files in bin/

        # Check for unfinished work markers (comment-style only, not variable names)
        # Uses # TODO / // TODO / /* TODO patterns to avoid matching PLAN_TODO, READY_TODOS, etc.
        # Exclude: todo.sh (manages TODOs), eval.sh (checks for TODOs), test files, grade.sh (reads predictions)
        local todo_count
        todo_count=$(grep -rn '#[[:space:]]*\(TODO\|FIXME\|HACK\|XXX\)\|//[[:space:]]*\(TODO\|FIXME\|HACK\|XXX\)\|/\*[[:space:]]*\(TODO\|FIXME\|HACK\|XXX\)' --include="*.sh" --include="*.mjs" "$SRC_DIR" 2>/dev/null | grep -v "node_modules" | grep -v "todo\.sh\|todo\.test\|eval\.sh\|grade\.sh\|tests/" | wc -l | tr -d ' ')
        tiered_penalty "$todo_count" "20:-20 10:-10 3:-5" "TODO/FIXME markers"

        # console.log/console.error in JS files (CLI tools should use structured output)
        local console_count
        console_count=$(grep -rn "console\.\(log\|warn\|error\)" --include="*.mjs" --include="*.js" "$SRC_DIR" 2>/dev/null | grep -v "// ok\|logger\|debug\|node_modules" | wc -l | tr -d ' ')
        # CLI tools legitimately use console — higher thresholds than web
        tiered_penalty "$console_count" "50:-20 30:-10 15:-5" "console.log statements"

        # Syntax errors in shell scripts
        local syntax_errors=0
        for f in "$SRC_DIR"/*.sh "$SCRIPT_DIR/lib"/*.sh; do
            [[ ! -f "$f" ]] && continue
            if ! bash -n "$f" 2>/dev/null; then
                syntax_errors=$((syntax_errors + 1))
            fi
        done
        tiered_penalty "$syntax_errors" "3:-30 1:-15" "shell syntax errors"

        # Syntax errors in JS/MJS files
        for f in "$SRC_DIR"/*.mjs; do
            [[ ! -f "$f" ]] && continue
            if ! node --check "$f" 2>/dev/null; then
                syntax_errors=$((syntax_errors + 1))
            fi
        done
        tiered_penalty "$syntax_errors" "3:-30 1:-15" "JS syntax errors"

        # Hardcoded paths (should use config or variables)
        local hardcoded_paths
        hardcoded_paths=$(grep -rn "/Users/\|/home/" --include="*.sh" --include="*.mjs" "$SRC_DIR" 2>/dev/null | grep -v "# ok\|example\|template\|node_modules" | wc -l | tr -d ' ')
        tiered_penalty "$hardcoded_paths" "10:-20 5:-10 1:-5" "hardcoded paths"

        # Unreachable code after return/exit (only count if next non-blank line is actual code, not control flow)
        local dead_code
        dead_code=$(grep -rn -A1 "^\s*return\b\|^\s*exit\b" --include="*.sh" "$SRC_DIR" 2>/dev/null | grep -v "return\|exit\|}\|esac\|fi\|done\|else\|elif\|#\|^\s*$\|node_modules\|local\|;;\|^--" | wc -l | tr -d ' ')
        tiered_penalty "$dead_code" "10:-15 5:-10 2:-5" "unreachable code blocks"

        [[ "$score" -lt 0 ]] && score=0
        echo "$score"
        return
    fi

    # Lens hygiene checks (dynamic discovery)
    for _fn in $(compgen -A function | grep '^score_hygiene_'); do
        score=$("$_fn" "$score" "$SRC_DIR" "$PROJECT_TYPE" "$COMP_EXT" "$density_mult")
    done

    [[ "$score" -lt 0 ]] && score=0
    echo "$score"
}

# ============================================================
# 4. ASSERTIONS & COMPLETION (the actual score)
#    assertions exist → assertion pass rate (0-100)
#    value hypothesis → completion ratchet (0-50, capped)
#    else → 10
# ============================================================
SCORING_MODE="empty"  # empty | onboarding | assertions

# Completion ratchet: 0-50, for projects without assertions yet
score_completion() {
    local points=0
    local cap=$(cfg scoring.onboarding_cap 50)

    # value.hypothesis defined in founder.yml (10 pts)
    if [[ -f "config/founder.yml" ]] && grep -q 'hypothesis:' "config/founder.yml" 2>/dev/null; then
        points=$((points + 10))
    fi

    # value.signals has entries (5 pts)
    if [[ -f "config/founder.yml" ]] && grep -q 'signals:' "config/founder.yml" 2>/dev/null; then
        local signal_count
        signal_count=$(grep -A100 'signals:' "config/founder.yml" 2>/dev/null | grep -c '^ *- name:' || true)
        [[ "$signal_count" -gt 0 ]] && points=$((points + 5))
    fi

    # Tests exist (5 pts)
    local has_tests=0
    if find . -maxdepth 4 -type f \( -name "*.test.*" -o -name "*.spec.*" -o -name "*_test.*" \) ! -path "*/node_modules/*" 2>/dev/null | head -1 | grep -q .; then
        has_tests=1
    elif [[ -d "tests" ]] || [[ -d "test" ]] || [[ -d "__tests__" ]]; then
        if find tests test __tests__ -type f 2>/dev/null | head -1 | grep -q .; then
            has_tests=1
        fi
    fi
    [[ "$has_tests" -eq 1 ]] && points=$((points + 5))

    # beliefs.yml exists (10 pts)
    local beliefs_file=""
    for bf in lens/*/eval/beliefs.yml "config/evals/beliefs.yml"; do
        [[ -f "$bf" ]] && beliefs_file="$bf" && break
    done
    [[ -n "$beliefs_file" ]] && points=$((points + 10))

    # beliefs.yml has 1+ assertions (10 pts)
    local assertion_count=0
    if [[ -n "$beliefs_file" ]]; then
        assertion_count=$(grep -c '^\s*- id:' "$beliefs_file" 2>/dev/null || true)
        [[ "$assertion_count" -gt 0 ]] && points=$((points + 10))
    fi

    # At least 1 assertion passes (10 pts) — run eval to check
    if [[ "$assertion_count" -gt 0 ]]; then
        local eval_score
        eval_score=$("$SCRIPT_DIR/eval.sh" . --score 2>/dev/null) || eval_score=""
        if [[ -n "$eval_score" && "$eval_score" =~ ^[0-9]+$ && "$eval_score" -gt 0 ]]; then
            points=$((points + 10))
        fi
    fi

    # Cap
    [[ "$points" -gt "$cap" ]] && points="$cap"
    echo "$points"
}

# Assertion pass rate: wraps eval.sh --score
score_assertions() {
    local eval_score _sa_err
    _sa_err=$(mktemp /tmp/founder-sa-err.XXXXXX)
    eval_score=$("$SCRIPT_DIR/eval.sh" . --score 2>"$_sa_err") || eval_score=""
    if [[ -z "$eval_score" && -s "$_sa_err" ]]; then
        echo "score: assertion eval failed — $(head -1 "$_sa_err"). Run /eval to debug." >&2
    fi
    rm -f "$_sa_err"
    if [[ -n "$eval_score" && "$eval_score" =~ ^[0-9]+$ ]]; then
        echo "$eval_score"
    else
        echo ""
    fi
}

# ============================================================
# Run all checks
# ============================================================
[[ "$OUTPUT_MODE" != "quiet" && "$OUTPUT_MODE" != "json" ]] && echo -e "\033[1m=== founder score ===\033[0m" >&2

start_spinner "checking build..."
BUILD=$(score_build_health)
stop_spinner "build: $BUILD/100"

start_spinner "analyzing structure..."
STRUCTURE=$(score_structure)
stop_spinner "structure: $STRUCTURE/100"

start_spinner "checking hygiene..."
HYGIENE=$(score_hygiene)
stop_spinner "hygiene: $HYGIENE/100"

# --- Health gate (replaces health-as-score) ---
HEALTH_MIN=$STRUCTURE
[[ "$HYGIENE" -lt "$HEALTH_MIN" ]] && HEALTH_MIN=$HYGIENE
HEALTH_GATE_THRESHOLD=$(cfg scoring.health_gate_threshold 20)
HEALTH_WARN_THRESHOLD=$(cfg scoring.health_warn_threshold 40)

# Build gate
BUILD_GATE_THRESHOLD=$(cfg scoring.build.gate_threshold 70)
if [[ "$BUILD" -lt "$BUILD_GATE_THRESHOLD" ]]; then
    BUILD_GATE="FAIL"
else
    BUILD_GATE="PASS"
fi

# --- Determine scoring mode and compute score ---
ASSERTION_COUNT=0
ASSERTION_PASS_COUNT=0
COMPLETION_SCORE=0
PRODUCT=""
FEATURES_JSON="{}"

start_spinner "checking value..."

# Check for features in founder.yml (generative eval) OR beliefs/assertions
local_beliefs_file=""
for bf in "lens/product/eval/beliefs.yml" "config/evals/beliefs.yml"; do
    [[ -f "$bf" ]] && local_beliefs_file="$bf" && break
done

local_has_features=false
if [[ -f "config/founder.yml" ]] && grep -q '^features:' "config/founder.yml" 2>/dev/null; then
    local_has_features=true
fi

if [[ -n "$local_beliefs_file" ]]; then
    ASSERTION_COUNT=$(grep -c '^\s*- id:' "$local_beliefs_file" 2>/dev/null || true)
fi

# Generative features count as assertions for scoring mode detection
if [[ "$local_has_features" == true && "$ASSERTION_COUNT" -eq 0 ]]; then
    # Count features under the features: section only
    ASSERTION_COUNT=$(awk '/^features:/{found=1; next} found && /^[a-z]/{exit} found && /^  [a-z][a-z0-9_-]*:/{c++} END{print c+0}' "config/founder.yml" 2>/dev/null || echo "0")
fi

if [[ "$ASSERTION_COUNT" -gt 0 ]]; then
    # Assertions exist → score = assertion pass rate
    # Single eval.sh call with --json for score + features + pass count
    _eval_err=$(mktemp /tmp/founder-eval-err.XXXXXX)
    eval_json=$("$SCRIPT_DIR/eval.sh" . --score --json --no-generative 2>"$_eval_err") || eval_json=""
    if [[ -z "$eval_json" && -s "$_eval_err" ]]; then
        _err_lines=$(tail -3 "$_eval_err" | tr '\n' ' ')
        if grep -q "jq" "$_eval_err" 2>/dev/null; then
            echo "score: eval failed — jq not found. Install: brew install jq" >&2
        elif grep -q "permission" "$_eval_err" 2>/dev/null; then
            echo "score: eval failed — permission error. Run: chmod +x bin/eval.sh" >&2
        else
            echo "score: eval failed — ${_err_lines}Run /eval for full output." >&2
        fi
    fi
    rm -f "$_eval_err"
    if [[ -n "$eval_json" ]] && command -v jq &>/dev/null; then
        eval_score=$(echo "$eval_json" | jq -r '.score // empty' 2>/dev/null) || eval_score=""
        if [[ -z "$eval_score" ]]; then
            echo "score: eval output parse error — eval returned JSON but score field missing. Run /eval to rebuild." >&2
        fi
        ASSERTION_PASS_COUNT=$(echo "$eval_json" | jq -r '.pass // 0' 2>/dev/null) || ASSERTION_PASS_COUNT=0
        ASSERTION_COUNT=$(echo "$eval_json" | jq -r '.beliefs_total // 0' 2>/dev/null) || ASSERTION_COUNT=0
        FEATURES_JSON=$(echo "$eval_json" | jq -c '.features // {}' 2>/dev/null) || FEATURES_JSON="{}"
    else
        eval_score=""
        ASSERTION_PASS_COUNT=0
        FEATURES_JSON="{}"
    fi
    [[ -z "$FEATURES_JSON" || "$FEATURES_JSON" == "" ]] && FEATURES_JSON="{}"

    if [[ -n "$eval_score" && "$eval_score" =~ ^[0-9]+$ ]]; then
        SCORING_MODE="assertions"
        PRODUCT="$eval_score"
    else
        SCORING_MODE="assertions"
        PRODUCT="0"
        ASSERTION_PASS_COUNT=0
    fi
elif [[ -f "config/founder.yml" ]] && grep -q 'hypothesis:' "config/founder.yml" 2>/dev/null; then
    # Has value hypothesis → completion ratchet (capped at 50)
    SCORING_MODE="onboarding"
    COMPLETION_SCORE=$(score_completion)
    PRODUCT="$COMPLETION_SCORE"
else
    # Nothing defined
    SCORING_MODE="empty"
    PRODUCT="10"
fi

# --- Apply the formula ---
if [[ "$BUILD_GATE" == "FAIL" ]]; then
    local_min=0
elif [[ "$HEALTH_MIN" -lt "$HEALTH_GATE_THRESHOLD" ]]; then
    local_min=0
else
    local_min="$PRODUCT"
fi

if [[ "$SCORING_MODE" == "assertions" ]]; then
    stop_spinner "value: $PRODUCT/100 ($ASSERTION_PASS_COUNT/$ASSERTION_COUNT beliefs)"
elif [[ "$SCORING_MODE" == "onboarding" ]]; then
    stop_spinner "value: $PRODUCT/$(cfg scoring.onboarding_cap 50) (onboarding)"
else
    stop_spinner "value: 10/100 (no value hypothesis)"
fi

# --- Unified score synthesis (5-tier) ---
# Call synthesize.sh to compute the unified score from all available tier caches.
# If synthesize returns a valid product_score > 0, use it as the authoritative score.
# Falls back to assertion-based scoring if synthesis has no data.
SYNTHESIZED_JSON=""
SYNTHESIZED_SCORE=""
SYNTHESIZED_CONFIDENCE=""
SYNTHESIZED_TIERS=""
_synth_script="$SCRIPT_DIR/../skills/score/scripts/synthesize.sh"
if [[ -x "$_synth_script" || -f "$_synth_script" ]] && [[ "$SCORING_MODE" == "assertions" ]] && [[ "$BUILD_GATE" != "FAIL" ]] && [[ "$HEALTH_MIN" -ge "$HEALTH_GATE_THRESHOLD" ]]; then
    start_spinner "synthesizing unified score..."
    _synth_err=$(mktemp /tmp/founder-synth-err.XXXXXX)
    # Export guard so synthesize.sh skips its first-run score.sh fallback (prevents recursion)
    SYNTHESIZED_JSON=$(FOUNDER_SCORE_DEPTH=1 bash "$_synth_script" "$PROJECT_DIR" --json 2>"$_synth_err") || SYNTHESIZED_JSON=""
    if [[ -n "$SYNTHESIZED_JSON" ]] && command -v jq &>/dev/null; then
        SYNTHESIZED_SCORE=$(echo "$SYNTHESIZED_JSON" | jq -r '.product_score // 0' 2>/dev/null) || SYNTHESIZED_SCORE=""
        SYNTHESIZED_CONFIDENCE=$(echo "$SYNTHESIZED_JSON" | jq -r '.confidence // "none"' 2>/dev/null) || SYNTHESIZED_CONFIDENCE=""
        SYNTHESIZED_TIERS=$(echo "$SYNTHESIZED_JSON" | jq -r '.tiers_filled // 0' 2>/dev/null) || SYNTHESIZED_TIERS=""
        # Only use synthesized score if it's valid and there's actual eval data
        if [[ -n "$SYNTHESIZED_SCORE" && "$SYNTHESIZED_SCORE" =~ ^[0-9]+$ && "$SYNTHESIZED_SCORE" -gt 0 && "$SYNTHESIZED_CONFIDENCE" != "none" && "$SYNTHESIZED_CONFIDENCE" != "blocked" ]]; then
            local_min="$SYNTHESIZED_SCORE"
            stop_spinner "unified: $SYNTHESIZED_SCORE/100 (${SYNTHESIZED_CONFIDENCE} confidence, ${SYNTHESIZED_TIERS}/5 tiers)"
        else
            stop_spinner "synthesis: no tier data — using assertions"
            SYNTHESIZED_SCORE=""
        fi
    else
        if [[ -s "$_synth_err" ]]; then
            _serr=$(head -1 "$_synth_err")
            stop_spinner "synthesis skipped — ${_serr}"
        else
            stop_spinner "synthesis skipped — no data"
        fi
    fi
    rm -f "$_synth_err"
fi

# --- History ---
HISTORY_DIR=".claude/scores"
HISTORY_FILE="$HISTORY_DIR/history.tsv"
mkdir -p "$HISTORY_DIR"

if [[ ! -f "$HISTORY_FILE" ]]; then
    printf "timestamp\tbuild\tstructure\thygiene\tproduct\tproject_type\n" > "$HISTORY_FILE"
fi

# --- Integrity checks (run BEFORE writing current entry to history) ---
# Compare the last two EXISTING history entries against each other.
# This is more reliable than current-vs-previous because both entries were
# computed by score.sh (no mismatch between fresh computation and seeded/stale data).
HIST_LINES=$(wc -l < "$HISTORY_FILE" | tr -d ' ')

# COSMETIC-ONLY + INFLATION: compare last two history entries
if [[ "$HIST_LINES" -ge 3 ]]; then
    hist_last_structure=$(tail -1 "$HISTORY_FILE" | cut -f3)
    hist_last_hygiene=$(tail -1 "$HISTORY_FILE" | cut -f4)
    hist_prev_structure=$(tail -2 "$HISTORY_FILE" | head -1 | cut -f3)
    hist_prev_hygiene=$(tail -2 "$HISTORY_FILE" | head -1 | cut -f4)
    if [[ -n "$hist_prev_structure" && "$hist_prev_structure" =~ ^[0-9]+$ && -n "$hist_prev_hygiene" && "$hist_prev_hygiene" =~ ^[0-9]+$ \
       && -n "$hist_last_structure" && "$hist_last_structure" =~ ^[0-9]+$ && -n "$hist_last_hygiene" && "$hist_last_hygiene" =~ ^[0-9]+$ ]]; then
        h_struct_delta=$((hist_last_structure - hist_prev_structure))
        h_hygiene_delta=$((hist_last_hygiene - hist_prev_hygiene))
        # Cosmetic-only: hygiene improved but structure didn't
        if [[ "$h_hygiene_delta" -gt 5 && "$h_struct_delta" -le 0 ]]; then
            INTEGRITY_WARNINGS="${INTEGRITY_WARNINGS}COSMETIC-ONLY: hygiene +${h_hygiene_delta} but structure ${h_struct_delta}. Cleanup without structural improvement.\n"
        fi
        # Inflation: single commit jumped too much
        # Skip if previous score was below onboarding cap (likely first real eval after init)
        max_delta=$(cfg integrity.max_single_commit_delta 15)
        h_total_delta=$(( h_struct_delta + h_hygiene_delta ))
        hist_prev_product=$(tail -2 "$HISTORY_FILE" | head -1 | cut -f5)
        onboarding_cap_check=$(cfg scoring.onboarding_cap 50)
        if [[ "$h_total_delta" -gt "$max_delta" ]]; then
            if [[ -n "$hist_prev_product" && "$hist_prev_product" =~ ^[0-9]+$ && "$hist_prev_product" -lt "$onboarding_cap_check" ]]; then
                : # Skip — this is a first-eval jump from init, not inflation
            else
                INTEGRITY_WARNINGS="${INTEGRITY_WARNINGS}INFLATION: score jumped +${h_total_delta} in one run (max: ${max_delta}). Verify changes are real.\n"
            fi
        fi
    fi
fi

# PLATEAU: score unchanged across N runs (checked before writing current entry)
plateau_runs=$(cfg integrity.plateau_tasks 3)
if [[ "$HIST_LINES" -gt "$plateau_runs" ]]; then
    unique_scores=$(tail -"$plateau_runs" "$HISTORY_FILE" | cut -f3 | sort -u | wc -l | tr -d ' ')
    if [[ "$unique_scores" -eq 1 ]]; then
        INTEGRITY_WARNINGS="${INTEGRITY_WARNINGS}PLATEAU: structure score unchanged across last ${plateau_runs} runs. Might be stuck.\n"
    fi
fi

# --- Write current entry to history (after integrity checks) ---
printf "%s\t%s\t%s\t%s\t%s\t%s\n" \
    "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
    "$BUILD" "$STRUCTURE" "$HYGIENE" \
    "${PRODUCT:-}" "$PROJECT_TYPE" >> "$HISTORY_FILE"

# STAGE CEILING: flag scores exceeding ceiling for current stage
if [[ -f ".claude/plans/active-plan.md" ]] || [[ -f "config/founder.yml" ]]; then
    # Detect stage from founder.yml or default to mvp
    local_stage=$(cfg project.stage "mvp")
    ceiling_max=""
    case "$local_stage" in
        mvp)    ceiling_max=65 ;;
        early)  ceiling_max=80 ;;
        growth) ceiling_max=90 ;;
        mature) ceiling_max=95 ;;
    esac
    if [[ -n "$ceiling_max" && "$local_min" -gt "$ceiling_max" ]]; then
        INTEGRITY_WARNINGS="${INTEGRITY_WARNINGS}CEILING: score ${local_min} exceeds ${local_stage} stage ceiling (${ceiling_max}). Verify this isn't inflated.\n"
    fi
fi

# (Experiment discipline checks removed — build discipline uses commit-level
# keep/revert, not per-experiment TSV tracking. Crash rate check below still applies.)

# CRASH RATE: check results.tsv for high crash rate
RESULTS_TSV=".claude/experiments/results.tsv"
if [[ -f "$RESULTS_TSV" ]]; then
    results_total=$(tail -n +2 "$RESULTS_TSV" | wc -l | tr -d ' ')
    if [[ "$results_total" -ge 10 ]]; then
        results_crashed=$(tail -n +2 "$RESULTS_TSV" | awk -F'\t' '$7 == "crashed"' | wc -l | tr -d ' ')
        crash_pct=$((results_crashed * 100 / results_total))
        if [[ "$crash_pct" -gt 30 ]]; then
            INTEGRITY_WARNINGS="${INTEGRITY_WARNINGS}HIGH_CRASH_RATE: ${results_crashed}/${results_total} experiments crashed (${crash_pct}%). Something systemic may be wrong.\n"
        fi
    fi
fi

# --- Taste eval (product quality from last visual eval) ---
TASTE_SCORE=""
TASTE_FILE=""
TASTE_AGE_DAYS=""
if [[ -d ".claude/evals/reports" ]]; then
    TASTE_FILE=$(ls -t .claude/evals/reports/taste-*.json 2>/dev/null | head -1)
    if [[ -n "$TASTE_FILE" ]] && command -v jq &> /dev/null; then
        TASTE_SCORE=$(jq -r '.score_100 // empty' "$TASTE_FILE" 2>/dev/null)
        taste_mtime=$(file_mtime "$TASTE_FILE")
        TASTE_AGE_DAYS=$(( ($(date +%s) - taste_mtime) / 86400 ))
    fi
fi

# Taste is informational — does NOT affect the score number

# --- Build integrity JSON array ---
INTEGRITY_JSON="[]"
if [[ -n "$INTEGRITY_WARNINGS" ]]; then
    INTEGRITY_JSON="["
    first=true
    while IFS= read -r warn; do
        [[ -z "$warn" ]] && continue
        $first || INTEGRITY_JSON+=","
        INTEGRITY_JSON+="\"$warn\""
        first=false
    done < <(printf '%b' "$INTEGRITY_WARNINGS")
    INTEGRITY_JSON+="]"
fi

# --- Cache (AFTER taste read so taste score is included) ---
mkdir -p "$CACHE_DIR"

# Save previous cache for change detection before overwriting
PREV_FEATURES_JSON="{}"
PREV_SCORE=""
if [[ -f "$CACHE_FILE" ]] && command -v jq &>/dev/null; then
    PREV_FEATURES_JSON=$(jq -c '.features // {}' "$CACHE_FILE" 2>/dev/null) || PREV_FEATURES_JSON="{}"
    PREV_SCORE=$(jq -r '.score // empty' "$CACHE_FILE" 2>/dev/null) || PREV_SCORE=""
fi

# Compute readiness
READY_STRATEGY=false
READY_TODOS=false
if [[ "$SCORING_MODE" == "assertions" && -n "$PRODUCT" && "$PRODUCT" =~ ^[0-9]+$ ]]; then
    [[ "$PRODUCT" -ge 60 ]] && READY_STRATEGY=true
    [[ "$PRODUCT" -ge 80 ]] && READY_TODOS=true
fi

# Build reasons JSON array from file
_reasons_file_to_json() {
    local file="$1"
    if [[ ! -s "$file" ]]; then
        echo "[]"
        return
    fi
    local json="["
    local first=true
    while IFS= read -r r; do
        [[ -z "$r" ]] && continue
        r="${r//\"/\\\"}"
        $first || json+=","
        json+="\"$r\""
        first=false
    done < "$file"
    json+="]"
    echo "$json"
}

BUILD_REASONS_JSON=$(_reasons_file_to_json "$REASONS_DIR/build")
STRUCTURE_REASONS_JSON=$(_reasons_file_to_json "$REASONS_DIR/structure")
HYGIENE_REASONS_JSON=$(_reasons_file_to_json "$REASONS_DIR/hygiene")

# Build synthesized fields for cache
_synth_cache_score="${SYNTHESIZED_SCORE:-null}"
_synth_cache_confidence="${SYNTHESIZED_CONFIDENCE:-null}"
_synth_cache_tiers="${SYNTHESIZED_TIERS:-null}"
[[ "$_synth_cache_score" == "null" ]] || true  # keep as-is if numeric
[[ "$_synth_cache_confidence" != "null" ]] && _synth_cache_confidence="\"$_synth_cache_confidence\""

cat > "$CACHE_FILE" <<CEOF
{"score":$local_min,"build":$BUILD,"build_gate":"$BUILD_GATE","structure":$STRUCTURE,"hygiene":$HYGIENE,"health_min":$HEALTH_MIN,"health_gate":"$([ "$HEALTH_MIN" -lt "$HEALTH_GATE_THRESHOLD" ] && echo "FAIL" || echo "PASS")","product":${PRODUCT:-null},"taste":${TASTE_SCORE:-null},"scoring_mode":"$SCORING_MODE","assertion_count":$ASSERTION_COUNT,"assertion_pass_count":$ASSERTION_PASS_COUNT,"features":$FEATURES_JSON,"synthesized_score":${_synth_cache_score},"synthesized_confidence":${_synth_cache_confidence},"synthesized_tiers":${_synth_cache_tiers},"ready_strategy":$READY_STRATEGY,"ready_todos":$READY_TODOS,"project_type":"$PROJECT_TYPE","src_dir":"$SRC_DIR","integrity_warnings":$INTEGRITY_JSON,"reasons":{"build":$BUILD_REASONS_JSON,"structure":$STRUCTURE_REASONS_JSON,"hygiene":$HYGIENE_REASONS_JSON},"cached_at":"$(date -u +%Y-%m-%dT%H:%M:%SZ)"}
CEOF

# --- Trends ---
trend_for() {
    local dim="$1" current="$2" col="$3"
    if [[ $(wc -l < "$HISTORY_FILE" | tr -d ' ') -ge 3 ]]; then
        local prev
        prev=$(tail -2 "$HISTORY_FILE" | head -1 | cut -f"$col")
        if [[ -n "$prev" && "$prev" =~ ^[0-9]+$ ]]; then
            local delta=$((current - prev))
            if [[ "$delta" -gt 0 ]]; then echo "↑$delta"
            elif [[ "$delta" -lt 0 ]]; then echo "↓$((delta * -1))"
            else echo "—"
            fi
            return
        fi
    fi
    echo "·"
}

# --- Output ---
make_bar() {
    local val=$1 width=20
    local filled=$((val * width / 100))
    local empty=$((width - filled))
    local bar=""
    for ((b=0; b<filled; b++)); do bar+="█"; done
    for ((b=0; b<empty; b++)); do bar+="░"; done
    echo "$bar"
}

dim_color() {
    local val=$1
    if [[ "$val" -ge 70 ]]; then echo "\033[0;32m"
    elif [[ "$val" -ge 40 ]]; then echo "\033[1;33m"
    else echo "\033[0;31m"
    fi
}

case "$OUTPUT_MODE" in
    quiet)
        echo "$local_min"
        ;;
    trend)
        # Output sparkline from history.tsv — last 10 distinct scores
        if [[ -f "$HISTORY_FILE" ]]; then
            # Extract last 10 distinct product scores
            scores_line=$(tail -n +2 "$HISTORY_FILE" | awk -F'\t' '{print $5}' | awk '
                {a[NR]=$0}
                END {
                    n=0; prev=""
                    for(i=NR; i>=1 && n<10; i--) {
                        if(a[i] != prev && a[i]+0 == a[i] && a[i] != "") {
                            if(n>0) printf " "
                            printf "%s", a[i]
                            prev=a[i]; n++
                        }
                    }
                }')
            # Convert to sparkline (newest first from awk, reverse for display)
            # Guard: empty scores_line produces no args
            if [[ -z "$scores_line" ]]; then
                echo "$local_min"
            else
            set -- $scores_line
            if [[ $# -ge 2 ]]; then
                # Reverse for display (oldest→newest)
                reversed=""
                for v in "$@"; do
                    if [[ -n "$reversed" ]]; then
                        reversed="${v} ${reversed}"
                    else
                        reversed="$v"
                    fi
                done
                # Sparkline characters
                spark_chars="▁▂▃▄▅▆▇█"
                # Find min/max
                min=100 max=0
                for v in $reversed; do
                    [[ $v -lt $min ]] && min=$v
                    [[ $v -gt $max ]] && max=$v
                done
                range=$((max - min))
                [[ $range -eq 0 ]] && range=1
                spark=""
                for v in $reversed; do
                    idx=$(( (v - min) * 7 / range ))
                    spark="${spark}${spark_chars:$idx:1}"
                done
                # Current score and delta
                newest=$1
                oldest=${!#}
                delta=$((newest - oldest))
                if [[ $delta -gt 0 ]]; then
                    echo "${spark} ${newest} (+${delta})"
                elif [[ $delta -lt 0 ]]; then
                    echo "${spark} ${newest} (${delta})"
                else
                    echo "${spark} ${newest}"
                fi
            else
                echo "$local_min"
            fi
            fi  # end empty scores_line guard
        else
            echo "$local_min"
        fi
        ;;
    json)
        cat <<EOF
{"score":$local_min,"build":$BUILD,"build_gate":"$BUILD_GATE","structure":$STRUCTURE,"hygiene":$HYGIENE,"health_min":$HEALTH_MIN,"health_gate":"$([ "$HEALTH_MIN" -lt "$HEALTH_GATE_THRESHOLD" ] && echo "FAIL" || echo "PASS")","product":${PRODUCT:-null},"taste":${TASTE_SCORE:-null},"scoring_mode":"$SCORING_MODE","assertion_count":$ASSERTION_COUNT,"assertion_pass_count":$ASSERTION_PASS_COUNT,"features":$FEATURES_JSON,"synthesized_score":${_synth_cache_score},"synthesized_confidence":${_synth_cache_confidence},"synthesized_tiers":${_synth_cache_tiers},"ready_strategy":$READY_STRATEGY,"ready_todos":$READY_TODOS,"project_type":"$PROJECT_TYPE","src_dir":"$SRC_DIR","integrity_warnings":$INTEGRITY_JSON,"reasons":{"build":$BUILD_REASONS_JSON,"structure":$STRUCTURE_REASONS_JSON,"hygiene":$HYGIENE_REASONS_JSON}}
EOF
        ;;
    score)
        echo ""

        # Build gate
        if [[ "$BUILD_GATE" == "FAIL" ]]; then
            echo -e "  \033[0;31m✗ BUILD GATE: FAIL ($BUILD/100)\033[0m"
            if [[ -s "$REASONS_DIR/build" ]]; then
                while IFS= read -r reason; do
                    [[ -n "$reason" ]] && echo -e "    \033[2m· $reason\033[0m"
                done < "$REASONS_DIR/build"
            fi
        else
            echo -e "  \033[0;32m✓\033[0m build ($BUILD/100)"
        fi

        # Health gate
        struct_trend=$(trend_for structure "$STRUCTURE" 3)
        hygiene_trend=$(trend_for hygiene "$HYGIENE" 4)
        if [[ "$HEALTH_MIN" -lt "$HEALTH_GATE_THRESHOLD" ]]; then
            echo -e "  \033[0;31m✗ HEALTH GATE: FAIL\033[0m (health=$HEALTH_MIN < threshold $HEALTH_GATE_THRESHOLD)"
            echo -e "    \033[2mstruct: $STRUCTURE  hygiene: $HYGIENE  — fix the lower one first\033[0m"
        elif [[ "$HEALTH_MIN" -lt "$HEALTH_WARN_THRESHOLD" ]]; then
            echo -e "  \033[1;33m⚠\033[0m health: $HEALTH_MIN \033[2m(struct:$STRUCTURE $struct_trend · hygiene:$HYGIENE $hygiene_trend — below warning threshold $HEALTH_WARN_THRESHOLD)\033[0m"
        else
            echo -e "  \033[0;32m✓\033[0m health: $HEALTH_MIN \033[2m(struct:$STRUCTURE $struct_trend · hygiene:$HYGIENE $hygiene_trend)\033[0m"
        fi

        # Show reasons for health dimensions (only when penalties exist)
        if [[ -s "$REASONS_DIR/structure" || -s "$REASONS_DIR/hygiene" ]]; then
            if [[ -s "$REASONS_DIR/structure" ]]; then
                while IFS= read -r reason; do
                    [[ -n "$reason" ]] && echo -e "    \033[2m· struct: $reason\033[0m"
                done < "$REASONS_DIR/structure"
            fi
            if [[ -s "$REASONS_DIR/hygiene" ]]; then
                while IFS= read -r reason; do
                    [[ -n "$reason" ]] && echo -e "    \033[2m· hygiene: $reason\033[0m"
                done < "$REASONS_DIR/hygiene"
            fi
        fi
        echo ""

        # Score display — depends on scoring mode
        overall_color=$(dim_color "$local_min")

        # Build score trend: last 5 distinct product scores as compact trajectory
        # e.g. "86 ← 78 ← 68 ← 52 ← 30 (↑56)"
        score_delta_display=""
        if [[ -f "$HISTORY_FILE" ]]; then
            # Use awk to extract last 5 distinct product scores, most recent first
            # Output: "93 85 84 80 75" (space-separated, newest first)
            _trend_line=$(tail -n +2 "$HISTORY_FILE" | awk -F'\t' '{print $5}' | awk '
                {a[NR]=$0}
                END {
                    n=0; prev=""
                    for(i=NR; i>=1 && n<5; i--) {
                        if(a[i] != prev && a[i]+0 == a[i] && a[i] != "") {
                            if(n>0) printf " "
                            printf "%s", a[i]
                            prev=a[i]; n++
                        }
                    }
                }')

            # Parse into positional args
            set -- $_trend_line
            if [[ $# -ge 2 ]]; then
                _newest=$1
                # Build "← prev ← prev2 ← ..." (skip $1, it's the current score shown in Score: line)
                _trend_str=""
                shift
                _oldest=$1
                for _tv in "$@"; do
                    [[ -n "$_trend_str" ]] && _trend_str="${_trend_str} ← "
                    _trend_str="${_trend_str}${_tv}"
                    _oldest=$_tv
                done

                if [[ -n "$_newest" && "$_newest" =~ ^[0-9]+$ && -n "$_oldest" && "$_oldest" =~ ^[0-9]+$ ]]; then
                    _net_change=$((_newest - _oldest))
                    _net_suffix=""
                    if [[ $_net_change -gt 0 ]]; then
                        _net_suffix=" \033[0;32m(↑${_net_change})\033[0m"
                    elif [[ $_net_change -lt 0 ]]; then
                        _abs_net=$(( -_net_change ))
                        _net_suffix=" \033[0;31m(↓${_abs_net})\033[0m"
                    fi
                fi

                score_delta_display=" \033[2m← ${_trend_str}${_net_suffix:-}\033[0m"
            fi
        fi

        # Show synthesis confidence when unified score is active
        if [[ -n "$SYNTHESIZED_SCORE" && "$SYNTHESIZED_SCORE" =~ ^[0-9]+$ && "$SYNTHESIZED_SCORE" -gt 0 ]]; then
            _tier_dots=""
            _st=${SYNTHESIZED_TIERS:-0}
            for ((_td=0; _td<_st; _td++)); do _tier_dots="${_tier_dots}●"; done
            for ((_td=_st; _td<5; _td++)); do _tier_dots="${_tier_dots}○"; done
            echo -e "  \033[2munified\033[0m  \033[1m${SYNTHESIZED_SCORE}/100\033[0m  \033[2m${SYNTHESIZED_CONFIDENCE} confidence · ${_tier_dots} (${SYNTHESIZED_TIERS}/5 tiers)\033[0m"
            echo -e "  \033[2mbeliefs\033[0m  ${ASSERTION_PASS_COUNT}/${ASSERTION_COUNT} passing (${PRODUCT}/100)"
            echo ""
        fi

        if [[ "$SCORING_MODE" == "assertions" ]]; then
            bar=$(make_bar "$local_min")
            _fail_ct=$((ASSERTION_COUNT - ASSERTION_PASS_COUNT))
            _pct_str=""
            if [[ "$ASSERTION_COUNT" -gt 0 ]]; then
                _pct=$((ASSERTION_PASS_COUNT * 100 / ASSERTION_COUNT))
                _pct_str="${_pct}% — "
                if [[ "$_pct" -lt 70 ]]; then
                    _pct_str="${_pct_str}${_fail_ct} failures block working"
                elif [[ "$_pct" -lt 90 ]]; then
                    _pct_str="${_pct_str}${_fail_ct} failures block polished"
                else
                    _pct_str="${_pct_str}near complete"
                fi
            fi
            echo -e "  \033[1mScore: ${overall_color}${local_min}/100\033[0m${score_delta_display}  ${overall_color}${bar}\033[0m  \033[2m(${ASSERTION_PASS_COUNT}/${ASSERTION_COUNT} beliefs · ${_pct_str})\033[0m"

            # Per-feature breakdown — score + top gap
            if [[ -n "$FEATURES_JSON" && "$FEATURES_JSON" != "{}" ]] && command -v jq &>/dev/null; then
                echo ""
                # Sort by score ascending (worst first)
                jq -r 'to_entries | sort_by(
                    if .value.type == "generative" then .value.score
                    else (.value.pass / (.value.total + 0.001)) * 100
                    end
                ) | .[] | .key' <<< "$FEATURES_JSON" 2>/dev/null | while read -r fname; do
                    [[ -z "$fname" ]] && continue
                    ftype=$(jq -r ".\"$fname\".type // \"beliefs\"" <<< "$FEATURES_JSON" 2>/dev/null)

                    if [[ "$ftype" == "generative" ]]; then
                        fscore=$(jq -r ".\"$fname\".score // 0" <<< "$FEATURES_JSON" 2>/dev/null)
                    else
                        fpass=$(jq -r ".\"$fname\".pass // 0" <<< "$FEATURES_JSON" 2>/dev/null)
                        ftotal=$(jq -r ".\"$fname\".total // 0" <<< "$FEATURES_JSON" 2>/dev/null)
                        fscore=0
                        [[ "$ftotal" -gt 0 ]] && fscore=$((fpass * 100 / ftotal))
                    fi

                    # Color from eval-cache score (actual quality) if available,
                    # otherwise fall back to assertion-based score
                    _eval_color_score=""
                    if [[ -f ".claude/cache/eval-cache.json" ]]; then
                        _cached_score=$(jq -r ".\"$fname\".score // empty" ".claude/cache/eval-cache.json" 2>/dev/null)
                        if [[ -n "$_cached_score" && "$_cached_score" =~ ^[0-9]+$ ]]; then
                            _eval_color_score="$_cached_score"
                        fi
                    fi
                    if [[ -n "$_eval_color_score" ]]; then
                        # Eval-aware color: green >= 70, yellow 50-69, red < 50
                        if [[ "$_eval_color_score" -ge 70 ]]; then fcolor="\033[0;32m"
                        elif [[ "$_eval_color_score" -ge 50 ]]; then fcolor="\033[1;33m"
                        else fcolor="\033[0;31m"
                        fi
                    else
                        fcolor=$(dim_color "$fscore")
                    fi
                    fbar=$(make_bar "$fscore")

                    # Delta from previous
                    fdelta=""
                    if [[ -n "$PREV_FEATURES_JSON" && "$PREV_FEATURES_JSON" != "{}" ]]; then
                        prev_score=$(echo "$PREV_FEATURES_JSON" | jq -r ".\"$fname\".score // empty" 2>/dev/null)
                        if [[ -n "$prev_score" && "$prev_score" =~ ^[0-9]+$ ]]; then
                            change=$((fscore - prev_score))
                            if [[ "$change" -gt 0 ]]; then
                                fdelta="  \033[0;32m↑${change}\033[0m"
                            elif [[ "$change" -lt 0 ]]; then
                                fdelta="  \033[0;31m↓$((change * -1))\033[0m"
                            fi
                        fi
                    fi

                    printf "  %-16s ${fcolor}${fbar}\033[0m  %s${fdelta}\n" "$fname" "$fscore"

                    # Show top gap from cached eval
                    if [[ -f ".claude/cache/eval-cache.json" ]]; then
                        _gap=$(jq -r ".\"$fname\".gaps[0] // empty" ".claude/cache/eval-cache.json" 2>/dev/null)
                        if [[ -n "$_gap" && "$_gap" != "null" ]]; then
                            [[ ${#_gap} -gt 60 ]] && _gap="${_gap:0:57}..."
                            echo -e "    \033[2m${_gap}\033[0m"
                        fi
                    fi
                done
            fi
        elif [[ "$SCORING_MODE" == "onboarding" ]]; then
            onboarding_cap=$(cfg scoring.onboarding_cap 50)
            bar=$(make_bar "$((local_min * 100 / onboarding_cap))")
            echo -e "  \033[1mScore: ${overall_color}${local_min}/${onboarding_cap}\033[0m${score_delta_display}  ${overall_color}${bar}\033[0m  \033[2m(define assertions to unlock full scoring)\033[0m"

            # Completion checklist
            echo ""
            echo -e "  \033[2mCompletion:\033[0m"
            has_hypothesis=false; [[ -f "config/founder.yml" ]] && grep -q 'hypothesis:' "config/founder.yml" 2>/dev/null && has_hypothesis=true
            has_signals=false; [[ -f "config/founder.yml" ]] && grep -q 'signals:' "config/founder.yml" 2>/dev/null && has_signals=true
            has_beliefs=false; [[ -n "$local_beliefs_file" ]] && has_beliefs=true
            has_belief_entries=false; [[ "$ASSERTION_COUNT" -gt 0 ]] && has_belief_entries=true

            [[ "$has_hypothesis" == true ]] && echo -e "    \033[0;32m✓\033[0m value hypothesis defined" || echo -e "    \033[2m·\033[0m value hypothesis — what does the user get? (one sentence in founder.yml)"
            [[ "$has_signals" == true ]] && echo -e "    \033[0;32m✓\033[0m value signals defined" || echo -e "    \033[2m·\033[0m value signals — how do you know it's working? (measurable proxies)"
            _ht=0; find . -maxdepth 4 -type f \( -name "*.test.*" -o -name "*.spec.*" \) ! -path "*/node_modules/*" 2>/dev/null | head -1 | grep -q . && _ht=1
            [[ "$_ht" -eq 1 ]] && echo -e "    \033[0;32m✓\033[0m tests exist" || echo -e "    \033[2m·\033[0m tests — any test file (*.test.*, *.spec.*)"
            [[ "$has_beliefs" == true ]] && echo -e "    \033[0;32m✓\033[0m beliefs.yml exists" || echo -e "    \033[2m·\033[0m beliefs.yml — assertions about what must be true"
            [[ "$has_belief_entries" == true ]] && echo -e "    \033[0;32m✓\033[0m assertions planted" || echo -e "    \033[2m·\033[0m assertions — add to config/evals/beliefs.yml"
            echo ""
            echo -e "  \033[2mScore is capped at ${onboarding_cap} until assertions are defined.\033[0m"
            echo -e "  \033[2mAdd assertions to config/evals/beliefs.yml, or run /assert in Claude Code.\033[0m"
        else
            # Empty mode — no value hypothesis at all
            echo -e "  \033[1mScore: ${overall_color}${local_min}/100\033[0m${score_delta_display}  \033[2m(unconfigured)\033[0m"
            echo ""
            echo -e "  \033[2mfounder-os doesn't know what this project does yet.\033[0m"
            echo -e "  \033[2mRun /init to set up scoring — it reads your code and generates config.\033[0m"
        fi

        # Stage ceiling reminder (inline, below features)
        local_stage=$(cfg project.stage "mvp")
        _ceiling=""
        case "$local_stage" in
            mvp)    _ceiling=65 ;;
            early)  _ceiling=80 ;;
            growth) _ceiling=90 ;;
            mature) _ceiling=95 ;;
        esac
        if [[ -n "$_ceiling" ]]; then
            echo ""
            if [[ "$local_min" -ge "$_ceiling" ]]; then
                echo -e "  \033[0;32m▲\033[0m \033[1mScore ${local_min} exceeds ${local_stage} ceiling (${_ceiling})\033[0m — ready to advance stage?"
                echo -e "    \033[2mUpdate project.stage in config/founder.yml if product has genuinely leveled up.\033[0m"
            else
                echo -e "  \033[2mstage: ${local_stage} · ceiling: ${_ceiling}\033[0m"
            fi
        fi

        # Taste — still shown if available
        echo ""
        if [[ -n "$TASTE_SCORE" && "$TASTE_SCORE" =~ ^[0-9]+$ ]]; then
            bar=$(make_bar "$TASTE_SCORE")
            color=$(dim_color "$TASTE_SCORE")
            stale_note=""
            if [[ -n "$TASTE_AGE_DAYS" && "$TASTE_AGE_DAYS" -gt 7 ]]; then
                stale_note=" \033[1;33m(${TASTE_AGE_DAYS}d old — rerun)\033[0m"
            fi
            echo -e "  Taste      ${color}${bar}\033[0m  ${TASTE_SCORE}/100  \033[2mUX, flows, delight (visual eval)\033[0m${stale_note}"
        else
            echo -e "  Taste      \033[2m░░░░░░░░░░░░░░░░░░░░\033[0m   —     \033[2mrun: /taste\033[0m"
        fi

        echo ""

        # Integrity warnings
        if [[ -n "$INTEGRITY_WARNINGS" ]]; then
            echo -e "  \033[1;33m⚠ Integrity Warnings:\033[0m"
            printf '%b' "$INTEGRITY_WARNINGS" | while IFS= read -r warn; do
                [[ -n "$warn" ]] && echo -e "    \033[1;33m· $warn\033[0m"
            done
            echo ""
        fi

        # Readiness signals
        if [[ "$SCORING_MODE" == "assertions" && -n "$PRODUCT" && "$PRODUCT" =~ ^[0-9]+$ ]]; then
            HAS_STRATEGY=false
            HAS_TODOS=false
            [[ -f ".claude/plans/strategy.yml" ]] && HAS_STRATEGY=true
            [[ -f ".claude/plans/todos.yml" ]] && HAS_TODOS=true

            if [[ "$PRODUCT" -ge 60 && "$HAS_STRATEGY" != "true" ]]; then
                echo -e "  \033[0;36m▸\033[0m assertions passing — ready for \033[1m/plan\033[0m"
            fi
            if [[ "$PRODUCT" -ge 80 && "$HAS_TODOS" != "true" ]]; then
                echo -e "  \033[0;36m▸\033[0m assertions strong — ready for \033[1m/plan\033[0m with todos"
            fi
            if [[ "$PRODUCT" -ge 60 && "$HAS_STRATEGY" == "true" && "$PRODUCT" -lt 80 ]]; then
                echo -e "  \033[2m▸ strategy active · pass more assertions to unlock todos\033[0m"
            fi
            if [[ "$PRODUCT" -ge 80 && "$HAS_STRATEGY" == "true" && "$HAS_TODOS" == "true" ]]; then
                echo -e "  \033[0;32m▸\033[0m full loop active — strategy + todos + assertions"
            fi
        fi

        echo ""
        echo -e "  \033[2m$PROJECT_TYPE ($SRC_DIR) · $(( $(wc -l < "$HISTORY_FILE" | tr -d ' ') - 1 )) runs\033[0m"
        ;;
esac
