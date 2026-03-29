#!/usr/bin/env bash
# eval.sh — Generative eval runner
# Primary: reads features from founder.yml, Claude judges gap between claim and code.
# Fallback: beliefs.yml mechanical checks (supplementary).

set -euo pipefail

# --- Recursion guard ---
FOUNDER_EVAL_DEPTH="${FOUNDER_EVAL_DEPTH:-0}"
if [[ "$FOUNDER_EVAL_DEPTH" -ge 2 ]]; then
    echo ""  # safe fallback — empty = no assertions
    exit 0
fi
export FOUNDER_EVAL_DEPTH=$((FOUNDER_EVAL_DEPTH + 1))

# --- Parse args ---
SCORE_MODE=false
BY_FEATURE=false
JSON_OUTPUT=false
FRESH_MODE=false
NO_GENERATIVE=false
NO_LLM=false
EXECUTE_MODE=false
EVAL_SAMPLES=3
FEATURE_FILTER=""
POSITIONAL=""
for arg in "$@"; do
    case "$arg" in
        --score) SCORE_MODE=true ;;
        --by-feature) BY_FEATURE=true ;;
        --json) JSON_OUTPUT=true ;;
        --fresh) FRESH_MODE=true ;;
        --no-generative) NO_GENERATIVE=true ;;
        --no-llm) NO_LLM=true; NO_GENERATIVE=true ;;
        --execute) EXECUTE_MODE=true ;;
        --samples=*) EVAL_SAMPLES="${arg#--samples=}" ;;
        --samples) ;; # next arg is the count, handled below
        --feature=*) FEATURE_FILTER="${arg#--feature=}" ;;
        --feature) ;; # next arg is the feature name, handled below
        *)
            if [[ "${prev_arg:-}" == "--feature" ]]; then
                FEATURE_FILTER="$arg"
            elif [[ "${prev_arg:-}" == "--samples" ]]; then
                EVAL_SAMPLES="$arg"
            else
                POSITIONAL="$arg"
            fi
            ;;
    esac
    prev_arg="$arg"
done

# Resolve FOUNDER_DIR before cd (BASH_SOURCE is relative, breaks after cd)
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    FOUNDER_DIR="$CLAUDE_PLUGIN_ROOT"
else
    _EVAL_SOURCE="${BASH_SOURCE[0]}"
    while [[ -L "$_EVAL_SOURCE" ]]; do
        _EVAL_SOURCE="$(readlink "$_EVAL_SOURCE")"
    done
    FOUNDER_DIR="$(cd "$(dirname "$_EVAL_SOURCE")/.." && pwd)"
fi

PROJECT_ROOT="${POSITIONAL:-.}"
cd "$PROJECT_ROOT"

PROJECT_NAME=$(basename "$(pwd)")
TIMESTAMP=$(date '+%Y-%m-%d %H:%M')

PASS=0
WARN=0
FAIL=0
SCORE_PENALTY=0

# Per-feature tracking (feature_name:pass:warn:fail accumulated as lines)
FEATURE_RESULTS=""

# Per-quality tracking (quality_dim:pass:warn:fail accumulated as lines)
QUALITY_RESULTS=""

# Assertion history (date\tfeature\tid\ttype\tstatus\tseverity — written to .claude/evals/assertion-history.tsv)
ASSERTION_HISTORY=""

# Per-layer tracking (feature~layer:pass:warn:fail accumulated as lines)
LAYER_RESULTS=""

# Generative eval numeric scores (feature_name:score accumulated as lines)
# These contribute directly to the final score as numbers, not pass/warn/fail buckets.
GENERATIVE_SCORES=""
GENERATIVE_COUNT=0
GENERATIVE_SUM=0

# --- Dependency checks ---
# jq is required for generative eval (cache read/write, JSON processing).
# Warn early rather than crash silently mid-eval.
if ! command -v jq &>/dev/null; then
    echo "warning: jq not found — generative eval and caching will be limited" >&2
    echo "  install: brew install jq (macOS) or apt install jq (Linux)" >&2
fi

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'
SEP="  ${DIM}⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯${NC}"

print_score_bar() {
    local score=${1:-0}
    local filled=$(( (score + 2) / 5 ))
    [[ $filled -gt 20 ]] && filled=20
    local empty=$((20 - filled))
    local color="$RED"
    [[ $score -ge 50 ]] && color="$YELLOW"
    [[ $score -ge 80 ]] && color="$GREEN"
    local bar=""
    for ((i=0; i<filled; i++)); do bar="${bar}█"; done
    local trail=""
    for ((i=0; i<empty; i++)); do trail="${trail}░"; done
    printf "${color}${bar}${DIM}${trail}${NC}"
}

# Cross-platform file mtime in epoch seconds
# Returns empty string (not 0) on failure so callers can detect errors
file_mtime() {
    local file="$1"
    [[ ! -f "$file" ]] && echo "" && return
    # macOS: stat -f %m, GNU/Linux: stat -c %Y
    stat -f %m "$file" 2>/dev/null || stat -c %Y "$file" 2>/dev/null || echo ""
}

# Result accumulation arrays
BELIEF_PASSES=()
BELIEF_WARNS=()
BELIEF_FAILS=()
GENERATIVE_DISPLAY=()

# --- Check functions ---

check_pass() {
    local name="$1"
    local desc="$2"
    PASS=$((PASS + 1))
    BELIEF_PASSES+=("${name}|${desc}")
}

check_warn() {
    local name="$1"
    local desc="$2"
    WARN=$((WARN + 1))
    BELIEF_WARNS+=("${name}|${desc}")
}

check_fail() {
    local name="$1"
    local desc="$2"
    local severity="${3:-warn}"
    local penalty="${4:-0}"
    FAIL=$((FAIL + 1))
    SCORE_PENALTY=$((SCORE_PENALTY + penalty))
    if [[ "$severity" == "block" ]]; then
        BELIEF_FAILS+=("${name}|${desc}|block")
    else
        BELIEF_FAILS+=("${name}|${desc}|warn")
    fi
}

# Early feature detection
HAS_FEATURES=false
if [[ -f "config/founder.yml" ]] && grep -q '^features:' "config/founder.yml" 2>/dev/null; then
    HAS_FEATURES=true
fi

# Detect source directories (needed by both default checks and beliefs.yml)
SRC_DIRS=""
for d in src app pages source; do
    [[ -d "$d" ]] && SRC_DIRS="$SRC_DIRS $d"
done

# === Default checks (skip in --score mode — score only counts beliefs.yml assertions) ===
if [[ "$SCORE_MODE" != "true" ]]; then

# 1. Build check — project identity
if [[ -f "package.json" ]]; then
    check_pass "project-id" "package.json exists"
elif [[ -f "pyproject.toml" ]]; then
    check_pass "project-id" "pyproject.toml exists"
elif [[ -f "Cargo.toml" ]]; then
    check_pass "project-id" "Cargo.toml exists"
elif [[ -f "go.mod" ]]; then
    check_pass "project-id" "go.mod exists"
else
    check_warn "project-id" "no standard project file found"
fi

if [[ -n "$SRC_DIRS" ]]; then
    # 2. Hygiene — console.log count
    CONSOLE_COUNT=$(grep -r 'console\.log' $SRC_DIRS 2>/dev/null | grep -v node_modules | grep -v '.test.' | grep -v '.spec.' | wc -l | tr -d ' ' || true)
    if [[ "$CONSOLE_COUNT" -eq 0 ]]; then
        check_pass "no-console-log" "0 console.log in source dirs"
    elif [[ "$CONSOLE_COUNT" -le 5 ]]; then
        check_warn "console-log" "$CONSOLE_COUNT console.log found"
    else
        check_fail "console-log" "$CONSOLE_COUNT console.log found" "warn" 3
    fi

    # 3. Hygiene — TODO count
    TODO_COUNT=$(grep -r 'TODO\|FIXME\|HACK\|XXX' $SRC_DIRS 2>/dev/null | grep -v node_modules | wc -l | tr -d ' ' || true)
    if [[ "$TODO_COUNT" -eq 0 ]]; then
        check_pass "no-todos" "0 TODO/FIXME in source dirs"
    elif [[ "$TODO_COUNT" -le 5 ]]; then
        check_warn "todos" "$TODO_COUNT TODO/FIXME found"
    else
        check_fail "todos" "$TODO_COUNT TODO/FIXME found" "warn" 2
    fi

    # 4. Hygiene — any types (TypeScript)
    ANY_COUNT=$(grep -r ': any\b\|as any\b' $SRC_DIRS 2>/dev/null | grep -v node_modules | grep -v '.test.' | grep -v '.spec.' | grep -v '.d.ts' | wc -l | tr -d ' ' || true)
    if [[ "$ANY_COUNT" -eq 0 ]]; then
        check_pass "no-any-types" "0 'any' types in source dirs"
    elif [[ "$ANY_COUNT" -le 3 ]]; then
        check_warn "any-types" "$ANY_COUNT 'any' types found"
    else
        check_fail "any-types" "$ANY_COUNT 'any' types found" "warn" 3
    fi

    # 5. Structure — file complexity
    LONG_FILES=$(find $SRC_DIRS -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.jsx' -o -name '*.py' -o -name '*.rs' 2>/dev/null | while read -r f; do
        lines=$(wc -l < "$f" 2>/dev/null | tr -d ' ')
        if [[ "$lines" -gt 500 ]]; then
            echo "$f ($lines lines)"
        fi
    done)
    if [[ -z "$LONG_FILES" ]]; then
        check_pass "file-size" "no files over 500 lines"
    else
        FILE_COUNT=$(echo "$LONG_FILES" | wc -l | tr -d ' ')
        check_warn "file-size" "$FILE_COUNT files over 500 lines (complexity warning)"
    fi
fi

fi  # end SCORE_MODE != true (default checks)

# FOUNDER_DIR already resolved before cd (see top of file)

source "$FOUNDER_DIR/bin/lib/config.sh"

# === Infrastructure checks (founder-os only) ===
# These check host state (symlinks, hooks, knowledge model) which only
# makes sense when running inside the founder-os repo itself.
# Sentinel: mind/identity.md exists only in founder-os.

if [[ "$SCORE_MODE" != "true" && -f "mind/identity.md" ]]; then

# value-hypothesis-exists
if [[ -f "config/founder.yml" ]] && grep -q '^value:' "config/founder.yml" 2>/dev/null; then
    check_pass "value-hypothesis-exists" "founder.yml has value: section"
else
    check_fail "value-hypothesis-exists" "founder.yml missing value: section" "block" 5
fi

# knowledge-model-exists
LEARNINGS="$HOME/.claude/knowledge/experiment-learnings.md"
if [[ -f "$LEARNINGS" ]] && [[ -s "$LEARNINGS" ]]; then
    check_pass "knowledge-model-exists" "experiment-learnings.md exists with content"
else
    check_fail "knowledge-model-exists" "experiment-learnings.md missing or empty" "block" 5
fi

# no-dead-skills
SKILLS_MISSING_RECOVERY=0
_SKILL_DIR="$FOUNDER_DIR/skills"
for skill in "$_SKILL_DIR"/*/SKILL.md; do
    [[ ! -f "$skill" ]] && continue
    if ! grep -q 'If something breaks\|Errors' "$skill" 2>/dev/null; then
        SKILLS_MISSING_RECOVERY=$((SKILLS_MISSING_RECOVERY + 1))
    fi
done
if [[ "$SKILLS_MISSING_RECOVERY" -eq 0 ]]; then
    check_pass "no-dead-skills" "all skills have recovery blocks"
else
    check_fail "no-dead-skills" "$SKILLS_MISSING_RECOVERY skill(s) missing 'If something breaks'" "warn" 2
fi

# hooks-resolve
HOOKS_BROKEN=0
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    # Plugin mode: validate hooks.json references
    _HOOKS_JSON="$FOUNDER_DIR/hooks/hooks.json"
    if [[ -f "$_HOOKS_JSON" ]] && command -v jq &>/dev/null; then
        while IFS= read -r _hcmd; do
            [[ -z "$_hcmd" ]] && continue
            # Expand ${CLAUDE_PLUGIN_ROOT} template variable and strip quotes
            _hcmd="${_hcmd//\$\{CLAUDE_PLUGIN_ROOT\}/$FOUNDER_DIR}"
            _hcmd="${_hcmd//\"/}"
            _hcmd="${_hcmd%% *}"
            [[ ! -f "$_hcmd" ]] && HOOKS_BROKEN=$((HOOKS_BROKEN + 1))
        done < <(jq -r '.. | .command? // empty' "$_HOOKS_JSON" 2>/dev/null)
    elif [[ ! -f "$_HOOKS_JSON" ]]; then
        HOOKS_BROKEN=1
    fi
    if [[ "$HOOKS_BROKEN" -eq 0 ]]; then
        check_pass "hooks-resolve" "hooks.json references resolve"
    else
        check_fail "hooks-resolve" "$HOOKS_BROKEN broken hook reference(s) in hooks.json" "warn" 3
    fi
else
    for hook in "$HOME/.claude/hooks/"*.sh; do
        [[ ! -L "$hook" ]] && continue
        target=$(readlink "$hook" 2>/dev/null)
        if [[ ! -f "$target" ]]; then
            HOOKS_BROKEN=$((HOOKS_BROKEN + 1))
        fi
    done
    if [[ "$HOOKS_BROKEN" -eq 0 ]]; then
        check_pass "hooks-resolve" "all hook symlinks resolve"
    else
        check_fail "hooks-resolve" "$HOOKS_BROKEN broken hook symlink(s)" "warn" 3
    fi
fi

# mind-files-loaded
MIND_MISSING=0
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    # Plugin mode: mind delivered via SKILL.md
    if [[ ! -f "$FOUNDER_DIR/skills/founder-mind/SKILL.md" ]]; then
        MIND_MISSING=1
    fi
    if [[ "$MIND_MISSING" -eq 0 ]]; then
        check_pass "mind-files-loaded" "mind delivered via skills/founder-mind/SKILL.md"
    else
        check_fail "mind-files-loaded" "skills/founder-mind/SKILL.md missing" "block" 5
    fi
else
    for mf in identity.md thinking.md standards.md self.md; do
        if [[ ! -L "$HOME/.claude/rules/$mf" ]] || [[ ! -f "$HOME/.claude/rules/$mf" ]]; then
            MIND_MISSING=$((MIND_MISSING + 1))
        fi
    done
    if [[ "$MIND_MISSING" -eq 0 ]]; then
        check_pass "mind-files-loaded" "all mind files symlinked in ~/.claude/rules/"
    else
        check_fail "mind-files-loaded" "$MIND_MISSING mind file(s) not in ~/.claude/rules/" "block" 5
    fi
fi

fi  # end SCORE_MODE != true

# === URL detection for DOM/copy/playwright checks ===
# Skip port scanning in --score mode (not needed for score computation)

EVAL_URL="${EVAL_URL:-}"
if [[ -z "$EVAL_URL" && "$SCORE_MODE" != "true" ]]; then
    for port in 3000 3001 5173 8080 4321 4000; do
        if curl -s --connect-timeout 1 -o /dev/null -w "%{http_code}" "http://localhost:$port" 2>/dev/null | grep -qE "^(200|301|302|304)"; then
            EVAL_URL="http://localhost:$port"
            break
        fi
    done
fi

# FOUNDER_DIR already resolved above (before infrastructure checks)

# Cached eval results (lazy-loaded)
DOM_RESULTS=""
DOM_RAN=false
COPY_RESULTS=""
COPY_RAN=false
SELF_RESULTS=""
SELF_RAN=false

run_dom_eval() {
    if [[ "$DOM_RAN" != "true" ]]; then
        DOM_RAN=true
        if [[ -n "$EVAL_URL" ]]; then
            local dom_script=""
            for _ds in "$FOUNDER_DIR"/lens/*/eval/dom-eval.mjs; do
                [[ -f "$_ds" ]] && dom_script="$_ds" && break
            done
            [[ -z "$dom_script" ]] && dom_script="$FOUNDER_DIR/bin/dom-eval.mjs"
            if [[ -f "$dom_script" ]]; then
                local _dom_err
                _dom_err=$(mktemp)
                DOM_RESULTS=$(node "$dom_script" --url "$EVAL_URL" --eval 2>"$_dom_err") || {
                    local _dom_stderr
                    _dom_stderr=$(cat "$_dom_err")
                    [[ -n "$_dom_stderr" ]] && echo "  [dom-eval] error: $(echo "$_dom_stderr" | head -1)" >&2
                    DOM_RESULTS=""
                }
                rm -f "$_dom_err"
            fi
        fi
    fi
}

run_copy_eval() {
    if [[ "$COPY_RAN" != "true" ]]; then
        COPY_RAN=true
        if [[ -n "$EVAL_URL" ]]; then
            local copy_script=""
            for _cs in "$FOUNDER_DIR"/lens/*/eval/copy-eval.mjs; do
                [[ -f "$_cs" ]] && copy_script="$_cs" && break
            done
            [[ -z "$copy_script" ]] && copy_script="$FOUNDER_DIR/bin/copy-eval.mjs"
            if [[ -f "$copy_script" ]]; then
                local _copy_err
                _copy_err=$(mktemp)
                COPY_RESULTS=$(node "$copy_script" --url "$EVAL_URL" --eval 2>"$_copy_err") || {
                    local _copy_stderr
                    _copy_stderr=$(cat "$_copy_err")
                    [[ -n "$_copy_stderr" ]] && echo "  [copy-eval] error: $(echo "$_copy_stderr" | head -1)" >&2
                    COPY_RESULTS=""
                }
                rm -f "$_copy_err"
            fi
        fi
    fi
}

run_self_eval() {
    if [[ "$SELF_RAN" != "true" ]]; then
        SELF_RAN=true
        local _self_err
        _self_err=$(mktemp)
        SELF_RESULTS=$(bash "$FOUNDER_DIR/bin/self.sh" --eval 2>"$_self_err") || {
            local _self_stderr
            _self_stderr=$(cat "$_self_err")
            [[ -n "$_self_stderr" ]] && echo "  [self-eval] error: $(echo "$_self_stderr" | head -1)" >&2
            SELF_RESULTS=""
        }
        rm -f "$_self_err"
    fi
}

# ============================================================
# GENERATIVE EVAL — features from founder.yml
# ============================================================

EVAL_CACHE_DIR=".claude/cache"
EVAL_CACHE_FILE="$EVAL_CACHE_DIR/eval-cache.json"
BELIEFS_CACHE_FILE="$EVAL_CACHE_DIR/beliefs-cache.json"

# Shared score formula: gen_avg - belief_penalty, or beliefs-only fallback
# Args: $1=gen_count $2=gen_sum $3=pass $4=warn $5=fail $6=has_block_fail (true/false)
# Outputs: score integer (or empty if no data)
compute_eval_score() {
    local _gen_count="$1" _gen_sum="$2" _pass="$3" _warn="$4" _fail="$5" _has_block="${6:-false}"
    local _total=$((_pass + _warn + _fail))

    if [[ "$_has_block" == "true" ]]; then
        echo 0
    elif [[ "$_gen_count" -gt 0 ]]; then
        local _gen_avg=$((_gen_sum / _gen_count))
        local _penalty=$((_warn * 3 + _fail * 5))
        local _score=$((_gen_avg - _penalty))
        [[ "$_score" -lt 0 ]] && _score=0
        echo "$_score"
    elif [[ "$_total" -gt 0 ]]; then
        echo $(( (_pass * 100 + _warn * 50) / _total ))
    fi
}

# Read features from founder.yml using simple YAML parsing
# Outputs lines: feature_name|delivers|for|code_path1,code_path2|cmd1,cmd2
# Filters: skips features with status: killed or status: archived
parse_features() {
    local config_file="config/founder.yml"
    [[ ! -f "$config_file" ]] && return

    local in_features=false
    local current_feat="" current_delivers="" current_for="" current_code="" current_commands="" current_status=""
    local in_code=false in_commands=false

    while IFS= read -r line; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue

        # Detect features: section
        if echo "$line" | grep -q '^features:'; then
            in_features=true
            continue
        fi

        # Detect end of features section (new top-level key)
        if [[ "$in_features" == true ]] && echo "$line" | grep -qE '^[a-z]'; then
            if [[ -n "$current_feat" && "$current_status" != "killed" && "$current_status" != "archived" ]]; then
                echo "${current_feat}|${current_delivers}|${current_for}|${current_code}|${current_commands}"
            fi
            current_feat=""
            in_features=false
            continue
        fi

        [[ "$in_features" != true ]] && continue

        # New feature (2-space indent, key with colon, no value)
        if echo "$line" | grep -qE '^  [a-z][a-z0-9_-]*:$'; then
            # Emit previous feature
            if [[ -n "$current_feat" && "$current_status" != "killed" && "$current_status" != "archived" ]]; then
                echo "${current_feat}|${current_delivers}|${current_for}|${current_code}|${current_commands}"
            fi
            current_feat=$(echo "$line" | sed 's/^[[:space:]]*//;s/:[[:space:]]*$//')
            current_delivers=""
            current_for=""
            current_code=""
            current_commands=""
            current_status=""
            in_code=false
            in_commands=false
            continue
        fi

        # status:
        if echo "$line" | grep -q '^\s*status:'; then
            current_status=$(echo "$line" | sed 's/.*status: *//;s/^"//;s/"$//')
            in_code=false
            in_commands=false
            continue
        fi

        # delivers:
        if echo "$line" | grep -q '^\s*delivers:'; then
            current_delivers=$(echo "$line" | sed 's/.*delivers: *//;s/^"//;s/"$//')
            in_code=false
            continue
        fi

        # for:
        if echo "$line" | grep -q '^\s*for:'; then
            current_for=$(echo "$line" | sed 's/.*for: *//;s/^"//;s/"$//')
            in_code=false
            continue
        fi

        # code: (inline array)
        if echo "$line" | grep -q '^\s*code:'; then
            in_code=true
            in_commands=false
            # Parse inline array: ["a", "b"]
            local inline
            inline=$(echo "$line" | grep -o '\[.*\]' || true)
            if [[ -n "$inline" ]]; then
                current_code=$(echo "$inline" | tr -d '[]"' | sed 's/, */,/g')
                in_code=false
            fi
            continue
        fi

        # internal: or commands: (inline array — CLI commands for UX eval)
        if echo "$line" | grep -q '^\s*\(internal\|commands\):'; then
            in_commands=true
            in_code=false
            local inline
            inline=$(echo "$line" | grep -o '\[.*\]' || true)
            if [[ -n "$inline" ]]; then
                current_commands=$(echo "$inline" | tr -d '[]"' | sed 's/, */,/g')
                in_commands=false
            fi
            continue
        fi

        # skills: (inline array — slash command references, verified by skill existence)
        if echo "$line" | grep -q '^\s*skills:'; then
            local inline
            inline=$(echo "$line" | grep -o '\[.*\]' || true)
            if [[ -n "$inline" ]]; then
                local skill_cmds
                skill_cmds=$(echo "$inline" | tr -d '[]"' | sed 's/, */,/g')
                if [[ -n "$current_commands" && -n "$skill_cmds" ]]; then
                    current_commands="${current_commands},${skill_cmds}"
                elif [[ -n "$skill_cmds" ]]; then
                    current_commands="$skill_cmds"
                fi
            fi
            continue
        fi

        # code array items
        if [[ "$in_code" == true ]]; then
            if echo "$line" | grep -q '^\s*-'; then
                local item
                item=$(echo "$line" | sed 's/^[[:space:]]*- *//;s/^"//;s/"$//')
                if [[ -n "$current_code" ]]; then
                    current_code="${current_code},${item}"
                else
                    current_code="$item"
                fi
            else
                in_code=false
            fi
        fi

        # commands array items
        if [[ "$in_commands" == true ]]; then
            if echo "$line" | grep -q '^\s*-'; then
                local item
                item=$(echo "$line" | sed 's/^[[:space:]]*- *//;s/^"//;s/"$//')
                if [[ -n "$current_commands" ]]; then
                    current_commands="${current_commands},${item}"
                else
                    current_commands="$item"
                fi
            else
                in_commands=false
            fi
        fi
    done < "$config_file"

    # Emit last feature
    if [[ -n "$current_feat" && "$current_status" != "killed" && "$current_status" != "archived" ]]; then
        echo "${current_feat}|${current_delivers}|${current_for}|${current_code}|${current_commands}"
    fi
}

# === Generative eval engine (extracted to bin/lib/generative-eval.sh) ===
# Provides: gather_code_context(), generate_feature_rubric(), run_logic_research(),
#           _validate_and_emit(), _apply_logic_antisycophancy()
source "$FOUNDER_DIR/bin/lib/generative-eval.sh"

# === Execution eval engine (runtime checks) ===
# Provides: run_execution_eval(), format_execution_context()
PROJECT_DIR="${PROJECT_DIR:-$(pwd)}"
source "$FOUNDER_DIR/bin/lib/execution-eval.sh"

# Check eval cache for a feature
# Returns cached verdict if fresh, empty string if stale/missing
check_eval_cache() {
    local feat_name="$1"
    if [[ "$FRESH_MODE" == true ]]; then
        echo ""
        return
    fi
    if [[ -f "$EVAL_CACHE_FILE" ]] && command -v jq &>/dev/null; then
        local cached_at
        cached_at=$(jq -r ".\"$feat_name\".cached_at // empty" "$EVAL_CACHE_FILE" 2>/dev/null)
        if [[ -n "$cached_at" ]]; then
            # Check if code files have changed since cache
            local cache_mtime
            cache_mtime=$(file_mtime "$EVAL_CACHE_FILE")
            cache_mtime="${cache_mtime:-0}"
            local now
            now=$(date +%s)
            local age=$(( now - cache_mtime ))
            # Cache valid for configured TTL (default 1 hour) AND no code files changed
            local cache_ttl
            cache_ttl=$(cfg scoring.cache_ttl 3600)
            if [[ "$age" -lt "$cache_ttl" ]]; then
                # Check if any code file for this feature changed since cache
                local code_changed=false
                local code_paths
                code_paths=$(grep -A20 "^  ${feat_name}:" "$PROJECT_DIR/config/founder.yml" 2>/dev/null | \
                    awk '/^  [a-z]/ && NR>1 {exit} /code:/{found=1;next} found && /^\s*-/{gsub(/^[[:space:]]*- *"?|"?$/,""); print}')
                for _cp in $code_paths; do
                    # Expand ~ and check if file/dir is newer than cache
                    _cp="${_cp/#\~/$HOME}"
                    if [[ -e "$PROJECT_DIR/$_cp" ]]; then
                        if find "$PROJECT_DIR/$_cp" -type f -newer "$EVAL_CACHE_FILE" -print -quit 2>/dev/null | grep -q .; then
                            code_changed=true
                            break
                        fi
                    fi
                done
                if [[ "$code_changed" == false ]]; then
                    jq -c ".\"$feat_name\"" "$EVAL_CACHE_FILE" 2>/dev/null
                    return
                fi
            fi
        fi
    fi
    echo ""
}

# Run generative eval for all features (or filtered)
run_generative_eval() {
    local features_data
    features_data=$(parse_features)

    [[ -z "$features_data" ]] && return

    mkdir -p "$EVAL_CACHE_DIR"

    # Build cache JSON incrementally
    local cache_json="{"
    local cache_first=true

    while IFS='|' read -r feat_name delivers for_whom code_paths feat_commands; do
        [[ -z "$feat_name" ]] && continue

        # Feature filter
        if [[ -n "$FEATURE_FILTER" && "$feat_name" != "$FEATURE_FILTER" ]]; then
            continue
        fi

        # Check cache first
        local cached
        cached=$(check_eval_cache "$feat_name")

        local verdict="" gaps="" evidence="" feat_score=""
        local delivery_score="" craft_score=""
        local _confidence_interval=""

        if [[ -n "$cached" && "$cached" != "" ]]; then
            verdict=$(echo "$cached" | jq -r '.verdict // "PARTIAL"' 2>/dev/null)
            gaps=$(echo "$cached" | jq -r '.gaps // [] | join("; ")' 2>/dev/null)
            evidence=$(echo "$cached" | jq -r '.evidence // ""' 2>/dev/null)
            feat_score=$(echo "$cached" | jq -r '.score // 50' 2>/dev/null)
            delivery_score=$(echo "$cached" | jq -r '.delivery_score // empty' 2>/dev/null)
            craft_score=$(echo "$cached" | jq -r '.craft_score // empty' 2>/dev/null)
            _confidence_interval=$(echo "$cached" | jq -r '.confidence_interval // empty' 2>/dev/null)
        else
            # Gather code and call Claude
            local code_context
            code_context=$(gather_code_context "$code_paths" "$feat_name")

            # Append execution eval results when --execute is active
            if [[ "$EXECUTE_MODE" == true ]]; then
                local exec_results
                local _exec_err
                _exec_err=$(mktemp)
                exec_results=$(run_execution_eval "$feat_name" 2>"$_exec_err") || {
                    local _exec_stderr
                    _exec_stderr=$(cat "$_exec_err")
                    [[ -n "$_exec_stderr" ]] && echo "  [exec-eval:$feat_name] error: $(echo "$_exec_stderr" | head -1)" >&2
                    exec_results=""
                }
                rm -f "$_exec_err"
                if [[ -n "$exec_results" ]]; then
                    code_context+="
$(format_execution_context "$exec_results")"
                fi
            fi

            if [[ -n "$code_context" ]]; then
                # Generate per-feature rubric (async, cached 24h) — runs in background for next eval
                generate_feature_rubric "$feat_name" "$delivers" "$for_whom" "$code_context" &
                local judge_result best_result
                # Multi-sample median: run N times, take median of delivery and craft independently
                local n_samples="${EVAL_SAMPLES:-3}"
                local _confidence_interval=""
                if [[ "$n_samples" -le 1 ]]; then
                    judge_result=$(run_logic_research "$feat_name" "$delivers" "$for_whom" "$code_context")
                else
                    local sample_delivery=() sample_craft=() sample_results=()
                    for ((si=0; si<n_samples; si++)); do
                        local sample
                        sample=$(run_logic_research "$feat_name" "$delivers" "$for_whom" "$code_context")
                        local s_del s_cra
                        s_del=$(echo "$sample" | jq -r '.delivery_score // 50' 2>/dev/null)
                        s_cra=$(echo "$sample" | jq -r '.craft_score // 50' 2>/dev/null)
                        [[ -z "$s_del" || ! "$s_del" =~ ^[0-9]+$ ]] && s_del=50
                        [[ -z "$s_cra" || ! "$s_cra" =~ ^[0-9]+$ ]] && s_cra=50
                        sample_delivery+=("$s_del")
                        sample_craft+=("$s_cra")
                        sample_results+=("$sample")
                    done

                    # Compute median delivery_score
                    local sorted_del
                    sorted_del=$(printf '%s\n' "${sample_delivery[@]}" | sort -n)
                    local median_del
                    median_del=$(echo "$sorted_del" | sed -n "$((n_samples / 2 + 1))p")

                    # Compute median craft_score
                    local sorted_cra
                    sorted_cra=$(printf '%s\n' "${sample_craft[@]}" | sort -n)
                    local median_cra
                    median_cra=$(echo "$sorted_cra" | sed -n "$((n_samples / 2 + 1))p")

                    # Compute confidence interval: (max - min) / 2 of the overall scores
                    local sample_totals=()
                    for ((si=0; si<n_samples; si++)); do
                        sample_totals+=("$(( sample_delivery[si] * 60 / 100 + sample_craft[si] * 40 / 100 ))")
                    done
                    local sorted_totals
                    sorted_totals=$(printf '%s\n' "${sample_totals[@]}" | sort -n)
                    local _ci_min _ci_max
                    _ci_min=$(echo "$sorted_totals" | head -1)
                    _ci_max=$(echo "$sorted_totals" | tail -1)
                    _confidence_interval="$(( (_ci_max - _ci_min + 1) / 2 ))"

                    # Pick the result closest to the median delivery score for gaps/evidence
                    local best_idx=0 best_diff=999
                    for ((si=0; si<n_samples; si++)); do
                        local diff=$(( sample_delivery[si] - median_del ))
                        [[ "$diff" -lt 0 ]] && diff=$(( -diff ))
                        if [[ "$diff" -lt "$best_diff" ]]; then
                            best_diff="$diff"
                            best_idx="$si"
                        fi
                    done

                    # Build judge_result from median scores + best-match qualitative data
                    judge_result=$(echo "${sample_results[$best_idx]}" | jq -c \
                        --argjson d "$median_del" --argjson c "$median_cra" \
                        --argjson s "$(( median_del * 60 / 100 + median_cra * 40 / 100 ))" \
                        '.delivery_score = $d | .craft_score = $c | .score = $s')
                fi
                verdict=$(echo "$judge_result" | jq -r '.verdict // "PARTIAL"' 2>/dev/null)
                gaps=$(echo "$judge_result" | jq -r '.gaps // [] | join("; ")' 2>/dev/null)
                evidence=$(echo "$judge_result" | jq -r '.evidence // ""' 2>/dev/null)
                feat_score=$(echo "$judge_result" | jq -r '.score // 50' 2>/dev/null)
                delivery_score=$(echo "$judge_result" | jq -r '.delivery_score // empty' 2>/dev/null)
                craft_score=$(echo "$judge_result" | jq -r '.craft_score // empty' 2>/dev/null)
            else
                verdict="MISSING"
                gaps="no code files found"
                evidence=""
                feat_score=0
                delivery_score=0
                craft_score=0
            fi
        fi

        # Pairwise delta tracking: compare against previous eval
        local delta="" delta_vs="" delta_num=""
        if [[ -f "$EVAL_CACHE_FILE" ]] && command -v jq &>/dev/null; then
            local prev_score
            prev_score=$(jq -r ".\"$feat_name\".score // empty" "$EVAL_CACHE_FILE" 2>/dev/null)
            if [[ -n "$prev_score" && "$prev_score" =~ ^[0-9]+$ && -n "$feat_score" && "$feat_score" =~ ^[0-9]+$ ]]; then
                delta_vs="$prev_score"
                local diff=$(( feat_score - prev_score ))
                delta_num="$diff"
                if [[ "$diff" -gt 0 ]]; then
                    delta="better"
                elif [[ "$diff" -lt 0 ]]; then
                    delta="worse"
                else
                    delta="same"
                fi
            fi
        fi

        # Claim-verify integration: cap delivery_score if mechanical checks fail
        if [[ -n "$delivery_score" && "$delivery_score" != "null" && "$delivery_score" -gt 60 ]]; then
            local claim_verify_script="$PROJECT_DIR/skills/shared/claim-verify.sh"
            if [[ -f "$claim_verify_script" ]]; then
                local cv_result
                cv_result=$(bash "$claim_verify_script" "$PROJECT_DIR" "$feat_name" 2>/dev/null) || cv_result=""
                if [[ -n "$cv_result" ]]; then
                    local cv_verdict
                    cv_verdict=$(echo "$cv_result" | jq -r ".features.\"$feat_name\".verdict // \"unknown\"" 2>/dev/null)
                    if [[ "$cv_verdict" == "broken" || "$cv_verdict" == "gap" ]]; then
                        local cv_rate
                        cv_rate=$(echo "$cv_result" | jq -r ".features.\"$feat_name\".pass_rate // 0" 2>/dev/null)
                        delivery_score=60
                        gaps="${gaps:+${gaps}; }claim-verify: ${cv_verdict} (${cv_rate}% checks pass)"
                    fi
                fi
            fi
        fi

        # Track as numeric score (0-100)
        # -1 signals eval failure — don't mask with a plausible number
        if [[ -z "$feat_score" || "$feat_score" == "null" ]]; then
            feat_score=-1
            GENERATIVE_DISPLAY+=("${feat_name}|-1|${delivers}|eval failed: no score returned|")
            continue
        fi
        # Normalize: if score came back on 1-5 scale, convert to 0-100
        # Heuristic: only scores <= 3 are treated as 1-5 scale, because
        # a genuinely low score of 4 or 5 out of 100 would be inflated
        # to 80-100 by the old threshold of <= 5. Scores of 1-3 are
        # almost never valid on a 0-100 scale (they'd mean <3% quality).
        if [[ "$feat_score" -le 3 ]]; then
            feat_score=$((feat_score * 20))
        fi
        GENERATIVE_SCORES="${GENERATIVE_SCORES}${feat_name}:${feat_score}
"
        GENERATIVE_COUNT=$((GENERATIVE_COUNT + 1))
        GENERATIVE_SUM=$((GENERATIVE_SUM + feat_score))

        # Accumulate for display (include sub-scores and confidence interval)
        if [[ "$SCORE_MODE" != "true" ]]; then
            local _sub_scores=""
            [[ -n "$delivery_score" && "$delivery_score" != "null" ]] && _sub_scores="d:${delivery_score}"
            [[ -n "$craft_score" && "$craft_score" != "null" ]] && _sub_scores="${_sub_scores:+${_sub_scores} }c:${craft_score}"
            [[ -n "${_confidence_interval:-}" && "${_confidence_interval:-0}" -gt 0 ]] && _sub_scores="${_sub_scores:+${_sub_scores} }±${_confidence_interval}"
            GENERATIVE_DISPLAY+=("${feat_name}|${feat_score}|${delivers}|${gaps}|${_sub_scores}|${delta_num:-}")
        fi

        # Build cache entry with sub-scores and delta
        $cache_first || cache_json+=","
        local cache_extras=""
        [[ -n "$delivery_score" ]] && cache_extras+=",\"delivery_score\":${delivery_score}"
        [[ -n "$craft_score" ]] && cache_extras+=",\"craft_score\":${craft_score}"
        [[ -n "${_confidence_interval:-}" && "${_confidence_interval:-0}" -gt 0 ]] && cache_extras+=",\"confidence_interval\":${_confidence_interval}"
        [[ -n "$delta" ]] && cache_extras+=",\"delta\":\"${delta}\""
        [[ -n "$delta_vs" ]] && cache_extras+=",\"delta_vs\":${delta_vs}"
        [[ -n "$delta_num" ]] && cache_extras+=",\"delta_num\":${delta_num}"
        # Use printf %s to avoid trailing newline that contaminates jq -Rs output
        cache_json+="\"$feat_name\":{\"verdict\":$(printf '%s' "$verdict" | jq -Rs .),\"gaps\":$(if [[ -n "$gaps" ]]; then printf '%s' "$gaps" | jq -Rs 'split("; ") | map(select(length > 0))'; else echo '[]'; fi),\"evidence\":$(printf '%s' "$evidence" | jq -Rs .),\"score\":${feat_score:-50}${cache_extras},\"cached_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}"
        cache_first=false
    done <<< "$features_data"

    cache_json+="}"

    # Wait for background rubric generation to finish
    wait 2>/dev/null || true

    # Write cache
    echo "$cache_json" > "$EVAL_CACHE_FILE" 2>/dev/null || true

    # Write delta history
    local delta_file="$EVAL_CACHE_DIR/eval-deltas.json"
    if command -v jq &>/dev/null; then
        local delta_entry
        delta_entry=$(date -u +%Y-%m-%dT%H:%M:%SZ)
        # Build delta JSON using jq directly (avoids subshell variable mutation bug)
        local delta_features_json
        delta_features_json=$(echo "$cache_json" | jq -c '[to_entries[] | {key: .key, value: {score: (.value.score // 0), delta: (.value.delta // "unknown"), vs: (.value.delta_vs // null)}}] | from_entries' 2>/dev/null) || delta_features_json="{}"
        local delta_json
        delta_json=$(jq -nc --arg ts "$delta_entry" --argjson feats "$delta_features_json" '{timestamp: $ts, features: $feats}')

        # Append to delta history (keep last 50 entries)
        if [[ -f "$delta_file" ]]; then
            jq -c --argjson new "$delta_json" '. + [$new] | .[-50:]' "$delta_file" > "${delta_file}.tmp" 2>/dev/null && mv "${delta_file}.tmp" "$delta_file" 2>/dev/null || echo "[$delta_json]" > "$delta_file" 2>/dev/null || true
        else
            echo "[$delta_json]" > "$delta_file" 2>/dev/null || true
        fi
    fi
}

# === Run generative eval ===
# HAS_FEATURES already detected earlier (before header)
# ONLY run on explicit eval calls (not --score mode).
# Score mode uses cached results if available, skips otherwise.
# This keeps `founder score .` fast and free (no LLM calls).
if [[ "$HAS_FEATURES" == true && "$SCORE_MODE" != "true" && "$NO_GENERATIVE" != "true" ]]; then
    run_generative_eval
elif [[ "$HAS_FEATURES" == true && "$SCORE_MODE" == "true" && "$NO_GENERATIVE" != "true" ]]; then
    # In --score mode: read cached generative scores as numbers, don't call Claude
    if [[ -f "$EVAL_CACHE_FILE" ]] && command -v jq &>/dev/null; then
        while IFS= read -r feat_name; do
            [[ -z "$feat_name" ]] && continue
            # Feature filter
            if [[ -n "$FEATURE_FILTER" && "$feat_name" != "$FEATURE_FILTER" ]]; then
                continue
            fi
            feat_score=$(jq -r ".\"$feat_name\".score // empty" "$EVAL_CACHE_FILE" 2>/dev/null)
            if [[ -n "$feat_score" && "$feat_score" =~ ^[0-9]+$ ]]; then
                GENERATIVE_SCORES="${GENERATIVE_SCORES}${feat_name}:${feat_score}
"
                GENERATIVE_COUNT=$((GENERATIVE_COUNT + 1))
                GENERATIVE_SUM=$((GENERATIVE_SUM + feat_score))
            fi
        done < <(jq -r 'keys[]' "$EVAL_CACHE_FILE" 2>/dev/null)
    fi
    # If no cache exists, generative features simply don't contribute to score.
    # Run `founder eval .` first to populate the cache.
fi

# Process a belief based on its type
# === Belief processor (extracted to bin/lib/belief-processor.sh) ===
# Provides: process_belief()
source "$FOUNDER_DIR/bin/lib/belief-processor.sh"

_BELIEF_PROCESSOR_SOURCED=true  # marker to prevent re-extraction confusion

# Below: beliefs.yml checks and remaining eval logic
# === beliefs.yml checks (parser extracted to bin/lib/beliefs-parser.sh) ===

source "$FOUNDER_DIR/bin/lib/beliefs-parser.sh"

BELIEFS_FILE=""
for bf in lens/*/eval/beliefs.yml "config/evals/beliefs.yml"; do
    [[ -f "$bf" ]] && BELIEFS_FILE="$bf" && break
done
if [[ -f "$BELIEFS_FILE" ]]; then
    parse_beliefs_file "$BELIEFS_FILE"
fi

# === Write assertion history (for /eval trend) ===
if [[ -n "$ASSERTION_HISTORY" && "$SCORE_MODE" != "true" ]]; then
    ASSERTION_HISTORY_FILE=".claude/evals/assertion-history.tsv"
    mkdir -p "$(dirname "$ASSERTION_HISTORY_FILE")"
    if [[ ! -f "$ASSERTION_HISTORY_FILE" ]]; then
        printf 'date\tfeature\tassertion_id\ttype\tstatus\tseverity\n' > "$ASSERTION_HISTORY_FILE"
    fi
    printf '%b' "$ASSERTION_HISTORY" >> "$ASSERTION_HISTORY_FILE"
fi

# === --score mode: output single integer, per-feature JSON, or combined JSON ===
if [[ "$SCORE_MODE" == "true" ]]; then
    BELIEFS_TOTAL=$((PASS + WARN + FAIL))

    # Aggregate per-feature results from beliefs (always needed for --json and --by-feature)
    _bf_tmpdir=$(mktemp -d)
    while IFS=: read -r _bf_name _bf_p _bf_w _bf_f; do
        [[ -z "$_bf_name" ]] && continue
        _bf_pp=0; _bf_pw=0; _bf_pf=0
        if [[ -f "$_bf_tmpdir/$_bf_name" ]]; then
            IFS=: read -r _bf_pp _bf_pw _bf_pf < "$_bf_tmpdir/$_bf_name"
        fi
        echo "$((_bf_pp + _bf_p)):$((_bf_pw + _bf_w)):$((_bf_pf + _bf_f))" > "$_bf_tmpdir/$_bf_name"
    done <<< "$FEATURE_RESULTS"

    # Aggregate per-feature~quality results
    _fq_tmpdir=$(mktemp -d)
    while IFS=: read -r _fq_key _fq_p _fq_w _fq_f; do
        [[ -z "$_fq_key" ]] && continue
        # _fq_key is "feature~quality"
        _fq_feat="${_fq_key%%~*}"
        _fq_qual="${_fq_key##*~}"
        [[ "$_fq_qual" == "unscoped" ]] && continue
        mkdir -p "$_fq_tmpdir/$_fq_feat"
        _fq_pp=0; _fq_pw=0; _fq_pf=0
        if [[ -f "$_fq_tmpdir/$_fq_feat/$_fq_qual" ]]; then
            IFS=: read -r _fq_pp _fq_pw _fq_pf < "$_fq_tmpdir/$_fq_feat/$_fq_qual"
        fi
        echo "$((_fq_pp + _fq_p)):$((_fq_pw + _fq_w)):$((_fq_pf + _fq_f))" > "$_fq_tmpdir/$_fq_feat/$_fq_qual"
    done <<< "$QUALITY_RESULTS"

    # Aggregate per-feature~layer results
    _fl_tmpdir=$(mktemp -d)
    while IFS=: read -r _fl_key _fl_p _fl_w _fl_f; do
        [[ -z "$_fl_key" ]] && continue
        _fl_feat="${_fl_key%%~*}"
        _fl_layer="${_fl_key##*~}"
        [[ "$_fl_layer" == "unscoped" ]] && continue
        mkdir -p "$_fl_tmpdir/$_fl_feat"
        _fl_pp=0; _fl_pw=0; _fl_pf=0
        if [[ -f "$_fl_tmpdir/$_fl_feat/$_fl_layer" ]]; then
            IFS=: read -r _fl_pp _fl_pw _fl_pf < "$_fl_tmpdir/$_fl_feat/$_fl_layer"
        fi
        echo "$((_fl_pp + _fl_p)):$((_fl_pw + _fl_w)):$((_fl_pf + _fl_f))" > "$_fl_tmpdir/$_fl_feat/$_fl_layer"
    done <<< "$LAYER_RESULTS"

    # Add generative scores to feature JSON
    while IFS=: read -r _gf_name _gf_score; do
        [[ -z "$_gf_name" ]] && continue
        echo "gen:${_gf_score}" > "$_bf_tmpdir/$_gf_name.gen"
    done <<< "$GENERATIVE_SCORES"

    # Build features JSON with nested quality
    # Collect unique feature names (beliefs + generative merged)
    _bf_names=""
    for _bf_file in "$_bf_tmpdir"/*; do
        [[ ! -f "$_bf_file" ]] && continue
        _bf_n=$(basename "$_bf_file")
        _bf_n="${_bf_n%.gen}"  # strip .gen suffix
        echo "$_bf_n"
    done | sort -u > "$_bf_tmpdir/.names"

    _bf_json="{"
    _bf_first=true
    while IFS= read -r _bf_fname; do
        [[ -z "$_bf_fname" ]] && continue
        $_bf_first || _bf_json+=","
        _bf_first=false

        _has_gen=false; _has_beliefs=false
        _gf_s=0
        _bf_p=0; _bf_w=0; _bf_f=0; _bf_t=0

        # Check for generative score
        if [[ -f "$_bf_tmpdir/$_bf_fname.gen" ]]; then
            _has_gen=true
            _gf_s=$(cut -d: -f2 < "$_bf_tmpdir/$_bf_fname.gen")
        fi

        # Check for beliefs data
        if [[ -f "$_bf_tmpdir/$_bf_fname" ]]; then
            _has_beliefs=true
            IFS=: read -r _bf_p _bf_w _bf_f < "$_bf_tmpdir/$_bf_fname"
            _bf_t=$((_bf_p + _bf_w + _bf_f))
        fi

        # Build quality JSON fragment
        _qual_frag=""
        if [[ -d "$_fq_tmpdir/$_bf_fname" ]]; then
            _qual_frag=",\"quality\":{"
            _bfq_first=true
            for _qdim in correctness craft completeness; do
                if [[ -f "$_fq_tmpdir/$_bf_fname/$_qdim" ]]; then
                    IFS=: read -r _qp _qw _qf < "$_fq_tmpdir/$_bf_fname/$_qdim"
                    _qt=$((_qp + _qw + _qf))
                    [[ "$_qt" -eq 0 ]] && continue
                    $_bfq_first || _qual_frag+=","
                    _qual_frag+="\"$_qdim\":{\"pass\":$_qp,\"total\":$_qt}"
                    _bfq_first=false
                fi
            done
            _qual_frag+="}"
        fi

        # Build layer JSON fragment — compute 1-5 score per layer from pass rates
        _layer_frag=""
        if [[ -d "$_fl_tmpdir/$_bf_fname" ]]; then
            _layer_frag=",\"layers\":{"
            _bfl_first=true
            for _ldim in infrastructure logic ux; do
                if [[ -f "$_fl_tmpdir/$_bf_fname/$_ldim" ]]; then
                    IFS=: read -r _lp _lw _lf < "$_fl_tmpdir/$_bf_fname/$_ldim"
                    _lt=$((_lp + _lw + _lf))
                    [[ "$_lt" -eq 0 ]] && continue
                    # Compute 1-5 from pass rate: 100%=5, 80-99%=4, 60-79%=3, 40-59%=2, <40%=1
                    _lpct=0
                    [[ "$_lt" -gt 0 ]] && _lpct=$((_lp * 100 / _lt))
                    if [[ "$_lpct" -ge 100 ]]; then _lscore=5
                    elif [[ "$_lpct" -ge 80 ]]; then _lscore=4
                    elif [[ "$_lpct" -ge 60 ]]; then _lscore=3
                    elif [[ "$_lpct" -ge 40 ]]; then _lscore=2
                    else _lscore=1
                    fi
                    $_bfl_first || _layer_frag+=","
                    _layer_frag+="\"$_ldim\":{\"score\":$_lscore,\"pass\":$_lp,\"total\":$_lt}"
                    _bfl_first=false
                fi
            done
            _layer_frag+="}"
        fi

        # Infrastructure gates: if infra < 3, cap logic and ux at 2
        if [[ -f "$_fl_tmpdir/$_bf_fname/infrastructure" ]]; then
            IFS=: read -r _gi_p _gi_w _gi_f < "$_fl_tmpdir/$_bf_fname/infrastructure"
            _gi_t=$((_gi_p + _gi_w + _gi_f))
            _gi_pct=0
            [[ "$_gi_t" -gt 0 ]] && _gi_pct=$((_gi_p * 100 / _gi_t))
            if [[ "$_gi_pct" -ge 100 ]]; then _gi_score=5
            elif [[ "$_gi_pct" -ge 80 ]]; then _gi_score=4
            elif [[ "$_gi_pct" -ge 60 ]]; then _gi_score=3
            elif [[ "$_gi_pct" -ge 40 ]]; then _gi_score=2
            else _gi_score=1
            fi
            if [[ "$_gi_score" -lt 3 ]]; then
                # Cap logic and ux layer scores at 2
                for _gated_layer in logic ux; do
                    if echo "$_layer_frag" | grep -q "\"$_gated_layer\""; then
                        _layer_frag=$(echo "$_layer_frag" | sed "s/\"$_gated_layer\":{\"score\":[0-9]*/\"$_gated_layer\":{\"score\":2/")
                    fi
                done
            fi
        fi

        # Use generative score as logic layer score if present and no belief-based logic layer
        if [[ "$_has_gen" == true ]]; then
            if ! echo "$_layer_frag" | grep -q '"logic"'; then
                if [[ -z "$_layer_frag" ]]; then
                    _layer_frag=",\"layers\":{\"logic\":{\"score\":$_gf_s,\"pass\":0,\"total\":0}}"
                else
                    _layer_frag="${_layer_frag%\}},\"logic\":{\"score\":$_gf_s,\"pass\":0,\"total\":0}}"
                fi
            fi
        fi

        if [[ "$_has_gen" == true && "$_has_beliefs" == true ]]; then
            _bf_json+="\"$_bf_fname\":{\"score\":$_gf_s,\"type\":\"generative\",\"pass\":$_bf_p,\"warn\":$_bf_w,\"fail\":$_bf_f,\"total\":$_bf_t${_qual_frag}${_layer_frag}}"
        elif [[ "$_has_gen" == true ]]; then
            _bf_json+="\"$_bf_fname\":{\"score\":$_gf_s,\"type\":\"generative\"${_layer_frag}}"
        else
            _bf_json+="\"$_bf_fname\":{\"pass\":$_bf_p,\"warn\":$_bf_w,\"fail\":$_bf_f,\"total\":$_bf_t${_qual_frag}${_layer_frag}}"
        fi
    done < "$_bf_tmpdir/.names"
    _bf_json+="}"
    rm -rf "$_bf_tmpdir" "$_fq_tmpdir" "$_fl_tmpdir"

    # Merge cached belief quality data (from last full eval run)
    # This fills in craft/completeness dimensions that --score mode skips
    if [[ -f "$BELIEFS_CACHE_FILE" ]] && command -v jq &>/dev/null; then
        _bc_mtime=$(file_mtime "$BELIEFS_CACHE_FILE")
        _bc_age=$(( $(date +%s) - ${_bc_mtime:-0} ))
        if [[ "$_bc_age" -lt 3600 ]]; then
            # Use temp file to avoid shell escaping issues with JSON in --argjson
            _merge_tmp=$(mktemp)
            echo "$_bf_json" > "$_merge_tmp"
            _merged=$(jq -c --slurpfile cache "$BELIEFS_CACHE_FILE" '
                . | to_entries | map(
                    .key as $k |
                    ($cache[0].features[$k].quality // null) as $cached_q |
                    (.value.quality // {}) as $current_q |
                    if $cached_q != null then
                        .value.quality = (
                            ($cached_q | keys) as $all_dims |
                            (($current_q | keys) + $all_dims) | unique | map(
                                . as $dim |
                                ($current_q[$dim] // null) as $cv |
                                ($cached_q[$dim] // null) as $kv |
                                if $cv != null and ($cv.total // 0) > 0 then {($dim): $cv}
                                elif $kv != null then {($dim): $kv}
                                else empty
                                end
                            ) | add // {}
                        ) | .
                    else .
                    end
                ) | from_entries
            ' "$_merge_tmp" 2>/dev/null) || _merged=""
            rm -f "$_merge_tmp"
            [[ -n "$_merged" ]] && _bf_json="$_merged"
        fi
    fi

    # ── Score formula (uses shared compute_eval_score) ──
    _has_block_fail=false
    for _entry in "${BELIEF_FAILS[@]+"${BELIEF_FAILS[@]}"}"; do
        if echo "$_entry" | grep -q '|block$'; then
            _has_block_fail=true
            break
        fi
    done
    _eval_score=$(compute_eval_score "$GENERATIVE_COUNT" "$GENERATIVE_SUM" "$PASS" "$WARN" "$FAIL" "$_has_block_fail")

    # Aggregate per-quality results (global, across all features)
    _bq_tmpdir=$(mktemp -d)
    while IFS=: read -r _bq_key _bq_p _bq_w _bq_f; do
        [[ -z "$_bq_key" ]] && continue
        # _bq_key is "feature~quality" — extract quality part
        _bq_name="${_bq_key##*~}"
        [[ "$_bq_name" == "unscoped" ]] && continue
        _bq_pp=0; _bq_pw=0; _bq_pf=0
        if [[ -f "$_bq_tmpdir/$_bq_name" ]]; then
            IFS=: read -r _bq_pp _bq_pw _bq_pf < "$_bq_tmpdir/$_bq_name"
        fi
        echo "$((_bq_pp + _bq_p)):$((_bq_pw + _bq_w)):$((_bq_pf + _bq_f))" > "$_bq_tmpdir/$_bq_name"
    done <<< "$QUALITY_RESULTS"

    _bq_json="{"
    _bq_first=true
    for _bq_file in "$_bq_tmpdir"/*; do
        [[ ! -f "$_bq_file" ]] && continue
        _bq_fname=$(basename "$_bq_file")
        IFS=: read -r _bq_p _bq_w _bq_f < "$_bq_file"
        _bq_t=$((_bq_p + _bq_w + _bq_f))
        $_bq_first || _bq_json+=","
        _bq_json+="\"$_bq_fname\":{\"pass\":$_bq_p,\"warn\":$_bq_w,\"fail\":$_bq_f,\"total\":$_bq_t}"
        _bq_first=false
    done
    _bq_json+="}"
    rm -rf "$_bq_tmpdir"

    if [[ "$JSON_OUTPUT" == "true" ]]; then
        echo "{\"score\":${_eval_score:-null},\"pass\":$PASS,\"warn\":$WARN,\"fail\":$FAIL,\"beliefs_total\":$BELIEFS_TOTAL,\"generative_count\":$GENERATIVE_COUNT,\"generative_sum\":$GENERATIVE_SUM,\"layer_count\":${_layer_count:-0},\"layer_sum\":${_layer_sum:-0},\"features\":$_bf_json,\"quality\":$_bq_json}"
    elif [[ "$BY_FEATURE" == "true" ]]; then
        echo "$_bf_json"
    else
        echo "$_eval_score"
    fi
    exit 0
fi

# === Display (voice.md format) ===
if [[ "$SCORE_MODE" != "true" ]]; then
    # Compute display score (shared formula)
    BELIEFS_TOTAL=$((PASS + WARN + FAIL))
    _display_score=$(compute_eval_score "$GENERATIVE_COUNT" "$GENERATIVE_SUM" "$PASS" "$WARN" "$FAIL" "false")

    # Aggregate layer results for display
    _display_layer_tmpdir=$(mktemp -d)
    while IFS=: read -r _dl_key _dl_p _dl_w _dl_f; do
        [[ -z "$_dl_key" ]] && continue
        _dl_feat="${_dl_key%%~*}"
        _dl_layer="${_dl_key##*~}"
        [[ "$_dl_layer" == "unscoped" ]] && continue
        mkdir -p "$_display_layer_tmpdir/$_dl_feat"
        _dl_pp=0; _dl_pw=0; _dl_pf=0
        if [[ -f "$_display_layer_tmpdir/$_dl_feat/$_dl_layer" ]]; then
            IFS=: read -r _dl_pp _dl_pw _dl_pf < "$_display_layer_tmpdir/$_dl_feat/$_dl_layer"
        fi
        echo "$((_dl_pp + _dl_p)):$((_dl_pw + _dl_w)):$((_dl_pf + _dl_f))" > "$_display_layer_tmpdir/$_dl_feat/$_dl_layer"
    done <<< "$LAYER_RESULTS"

    echo ""
    echo -e "$SEP"

    # Score bar at top
    if [[ -n "$_display_score" ]]; then
        SCORE_BAR=$(print_score_bar "$_display_score")
        echo -e "  ${DIM}eval${NC}  ${BOLD}${_display_score}/100${NC}  ${SCORE_BAR}"
        # Sub-line: feature count + belief count
        _sub_parts=""
        if [[ "$GENERATIVE_COUNT" -gt 0 ]]; then
            _gen_avg=$((GENERATIVE_SUM / GENERATIVE_COUNT))
            _sub_parts="${GENERATIVE_COUNT} features (avg ${_gen_avg})"
        else
            _sub_parts="beliefs-only"
        fi
        if [[ "$BELIEFS_TOTAL" -gt 0 ]]; then
            [[ -n "$_sub_parts" ]] && _sub_parts="${_sub_parts}  ${DIM}·${NC}  "
            _sub_parts="${_sub_parts}${PASS}/${BELIEFS_TOTAL} beliefs"
        fi
        [[ -n "$_sub_parts" ]] && echo -e "        $_sub_parts"
    fi

    echo -e "$SEP"
    echo ""

    # Features section — score, sub-scores, gap, trend
    # Pre-load feature trend data from eval-deltas.json (last 50 evals)
    _DELTA_FILE="$EVAL_CACHE_DIR/eval-deltas.json"

    if [[ ${#GENERATIVE_DISPLAY[@]} -gt 0 ]]; then
        echo -e "  ${BOLD}features${NC}"
        printf '%s\n' "${GENERATIVE_DISPLAY[@]}" | sort -t'|' -k2 -n | while IFS='|' read -r _fname _fscore _fdelivers _fgaps _fsub _fdelta; do
            # Color by score band
            if [[ "$_fscore" -ge 70 ]]; then
                _score_color="${GREEN}"
            elif [[ "$_fscore" -ge 50 ]]; then
                _score_color="${YELLOW}"
            else
                _score_color="${RED}"
            fi
            # Score bar (20-char)
            _filled=$(( (_fscore + 2) / 5 ))
            [[ $_filled -gt 20 ]] && _filled=20
            _empty=$((20 - _filled))
            _fbar=""
            for ((i=0; i<_filled; i++)); do _fbar+="█"; done
            for ((i=0; i<_empty; i++)); do _fbar+="░"; done

            # Build per-feature trend from eval-deltas.json
            # e.g. "86 ← 78 ← 68 ← 52 (↑34)"
            _ftrend=""
            if [[ -f "$_DELTA_FILE" ]] && command -v jq &>/dev/null; then
                # Use jq to get last 6 distinct scores for this feature (newest first), space-separated
                _fhist_line=$(jq -r --arg f "$_fname" '
                    [.[] | .features[$f].score // empty]
                    | reverse
                    | reduce .[] as $s ([]; if length == 0 or .[-1] != $s then . + [$s] else . end)
                    | .[0:6]
                    | map(tostring)
                    | join(" ")
                ' "$_DELTA_FILE" 2>/dev/null)

                # Parse space-separated scores
                set -- $_fhist_line
                if [[ $# -ge 2 ]]; then
                    _fnewest=$1
                    _ftrend_str="$1"
                    _foldest=$1
                    shift
                    for _fhv in "$@"; do
                        _ftrend_str="${_ftrend_str} ← ${_fhv}"
                        _foldest=$_fhv
                    done
                    _fnet=$((_fnewest - _foldest))
                    if [[ $_fnet -gt 0 ]]; then
                        _ftrend="  ${DIM}${_ftrend_str}${NC} ${GREEN}(↑${_fnet})${NC}"
                    elif [[ $_fnet -lt 0 ]]; then
                        _fabs_net=$(( -_fnet ))
                        _ftrend="  ${DIM}${_ftrend_str}${NC} ${RED}(↓${_fabs_net})${NC}"
                    else
                        _ftrend="  ${DIM}${_ftrend_str}${NC}"
                    fi
                fi
            fi

            # Delta indicator (absolute point change — always shown when previous exists)
            _delta_str=""
            if [[ -n "$_fdelta" ]]; then
                if [[ "$_fdelta" -gt 0 ]]; then
                    _delta_str=" ${GREEN}↑${_fdelta}${NC}"
                elif [[ "$_fdelta" -lt 0 ]]; then
                    _fdelta_abs=$(( -_fdelta ))
                    _delta_str=" ${RED}↓${_fdelta_abs}${NC}"
                else
                    _delta_str=" ${DIM}—${NC}"
                fi
            fi

            # Score line with sub-scores
            if [[ -n "$_fsub" ]]; then
                printf "  %-16s %b%s%b  %b%-3s%b%b  ${DIM}%s${NC}\n" "$_fname" "$_score_color" "$_fbar" "$NC" "$_score_color" "$_fscore" "$NC" "$_delta_str" "$_fsub"
            else
                printf "  %-16s %b%s%b  %b%-3s%b%b\n" "$_fname" "$_score_color" "$_fbar" "$NC" "$_score_color" "$_fscore" "$NC" "$_delta_str"
            fi

            # Show trend trajectory (if history exists)
            [[ -n "$_ftrend" ]] && echo -e "    ${_ftrend}"

            # Show gap
            if [[ -n "$_fgaps" && "$_fgaps" != "null" ]]; then
                _desc="$_fgaps"
                [[ ${#_desc} -gt 60 ]] && _desc="${_desc:0:57}..."
                echo -e "    ${DIM}${_desc}${NC}"
            fi
        done
        echo ""
    fi

    # Beliefs section — per-feature with quality breakdown
    if [[ "$BELIEFS_TOTAL" -gt 0 ]]; then
        echo -e "  ${BOLD}beliefs${NC}  ${PASS} ${GREEN}✓${NC}  ${DIM}·${NC}  ${WARN} ${YELLOW}⚠${NC}  ${DIM}·${NC}  ${FAIL} ${RED}✗${NC}"
        echo ""

        # Build per-feature quality breakdown
        _fqd_tmpdir=$(mktemp -d)
        while IFS=: read -r _fqd_key _fqd_p _fqd_w _fqd_f; do
            [[ -z "$_fqd_key" ]] && continue
            _fqd_feat="${_fqd_key%%~*}"
            _fqd_qual="${_fqd_key##*~}"
            [[ "$_fqd_qual" == "unscoped" || "$_fqd_feat" == "unscoped" ]] && continue
            mkdir -p "$_fqd_tmpdir/$_fqd_feat"
            _fqd_pp=0; _fqd_pw=0; _fqd_pf=0
            if [[ -f "$_fqd_tmpdir/$_fqd_feat/$_fqd_qual" ]]; then
                IFS=: read -r _fqd_pp _fqd_pw _fqd_pf < "$_fqd_tmpdir/$_fqd_feat/$_fqd_qual"
            fi
            echo "$((_fqd_pp + _fqd_p)):$((_fqd_pw + _fqd_w)):$((_fqd_pf + _fqd_f))" > "$_fqd_tmpdir/$_fqd_feat/$_fqd_qual"
        done <<< "$QUALITY_RESULTS"

        # Also aggregate per-feature totals
        _ftd_tmpdir=$(mktemp -d)
        while IFS=: read -r _ftd_name _ftd_p _ftd_w _ftd_f; do
            [[ -z "$_ftd_name" || "$_ftd_name" == "unscoped" ]] && continue
            _ftd_pp=0; _ftd_pw=0; _ftd_pf=0
            if [[ -f "$_ftd_tmpdir/$_ftd_name" ]]; then
                IFS=: read -r _ftd_pp _ftd_pw _ftd_pf < "$_ftd_tmpdir/$_ftd_name"
            fi
            echo "$((_ftd_pp + _ftd_p)):$((_ftd_pw + _ftd_w)):$((_ftd_pf + _ftd_f))" > "$_ftd_tmpdir/$_ftd_name"
        done <<< "$FEATURE_RESULTS"

        # Display each feature with quality sub-lines
        for _feat_file in "$_ftd_tmpdir"/*; do
            [[ ! -f "$_feat_file" ]] && continue
            _feat_name=$(basename "$_feat_file")
            IFS=: read -r _fp _fw _ff < "$_feat_file"
            _ft=$((_fp + _fw + _ff))
            [[ "$_ft" -eq 0 ]] && continue
            _fpct=$((_fp * 100 / _ft))
            if [[ "$_fpct" -ge 80 ]]; then _fcolor="${GREEN}"
            elif [[ "$_fpct" -ge 50 ]]; then _fcolor="${YELLOW}"
            else _fcolor="${RED}"
            fi
            printf "  ${BOLD}%-16s${NC} ${_fcolor}%s/%s${NC}\n" "$_feat_name" "$_fp" "$_ft"
            # Quality sub-lines
            if [[ -d "$_fqd_tmpdir/$_feat_name" ]]; then
                _qual_line="    "
                for _qdim in correctness craft completeness; do
                    if [[ -f "$_fqd_tmpdir/$_feat_name/$_qdim" ]]; then
                        IFS=: read -r _qp _qw _qf < "$_fqd_tmpdir/$_feat_name/$_qdim"
                        _qt=$((_qp + _qw + _qf))
                        [[ "$_qt" -eq 0 ]] && continue
                        if [[ "$_qp" -eq "$_qt" ]]; then _qcolor="${GREEN}"
                        elif [[ $((_qp * 100 / _qt)) -ge 50 ]]; then _qcolor="${YELLOW}"
                        else _qcolor="${RED}"
                        fi
                        _qual_line+="${DIM}${_qdim}${NC} ${_qcolor}${_qp}/${_qt}${NC}  "
                    fi
                done
                echo -e "$_qual_line"
            fi
        done
        rm -rf "$_fqd_tmpdir" "$_ftd_tmpdir"
        echo ""

        # Show failures first
        for _entry in "${BELIEF_FAILS[@]+"${BELIEF_FAILS[@]}"}"; do
            IFS='|' read -r _bname _bdesc _bsev <<< "$_entry"
            if [[ "$_bsev" == "block" ]]; then
                echo -e "  ${RED}●${NC} ${_bname}  ${DIM}${_bdesc}${NC}"
            else
                echo -e "  ${RED}✗${NC} ${_bname}  ${DIM}${_bdesc}${NC}"
            fi
        done

        # Show warnings
        for _entry in "${BELIEF_WARNS[@]+"${BELIEF_WARNS[@]}"}"; do
            IFS='|' read -r _bname _bdesc <<< "$_entry"
            echo -e "  ${YELLOW}⚠${NC} ${_bname}  ${DIM}${_bdesc}${NC}"
        done

        # Passes: just a count, don't list them
        echo ""
    fi

    # Next action line
    if [[ "$FAIL" -gt 0 ]]; then
        echo -e "  ${DIM}next: /plan to fix the ${FAIL} failure(s)${NC}"
    elif [[ "$WARN" -gt 0 ]]; then
        echo -e "  ${DIM}next: /plan to address ${WARN} warning(s)${NC}"
    else
        echo -e "  ${DIM}next: /go${NC}"
    fi

    echo -e "$SEP"
    echo ""

    rm -rf "$_display_layer_tmpdir"

    # Cache per-feature quality results for --score mode to use later
    # This lets score.sh show craft/completeness without re-running LLM judges
    if [[ "$BELIEFS_TOTAL" -gt 0 ]]; then
        mkdir -p "$EVAL_CACHE_DIR"
        _cache_tmpdir=$(mktemp -d)

        # Aggregate feature results
        while IFS=: read -r _cf_name _cf_p _cf_w _cf_f; do
            [[ -z "$_cf_name" || "$_cf_name" == "unscoped" ]] && continue
            _cf_pp=0; _cf_pw=0; _cf_pf=0
            if [[ -f "$_cache_tmpdir/$_cf_name" ]]; then
                IFS=: read -r _cf_pp _cf_pw _cf_pf < "$_cache_tmpdir/$_cf_name"
            fi
            echo "$((_cf_pp + _cf_p)):$((_cf_pw + _cf_w)):$((_cf_pf + _cf_f))" > "$_cache_tmpdir/$_cf_name"
        done <<< "$FEATURE_RESULTS"

        # Aggregate quality per feature
        _cq_tmpdir=$(mktemp -d)
        while IFS=: read -r _cq_key _cq_p _cq_w _cq_f; do
            [[ -z "$_cq_key" ]] && continue
            _cq_feat="${_cq_key%%~*}"
            _cq_qual="${_cq_key##*~}"
            [[ "$_cq_qual" == "unscoped" || "$_cq_feat" == "unscoped" ]] && continue
            mkdir -p "$_cq_tmpdir/$_cq_feat"
            _cq_pp=0; _cq_pw=0; _cq_pf=0
            if [[ -f "$_cq_tmpdir/$_cq_feat/$_cq_qual" ]]; then
                IFS=: read -r _cq_pp _cq_pw _cq_pf < "$_cq_tmpdir/$_cq_feat/$_cq_qual"
            fi
            echo "$((_cq_pp + _cq_p)):$((_cq_pw + _cq_w)):$((_cq_pf + _cq_f))" > "$_cq_tmpdir/$_cq_feat/$_cq_qual"
        done <<< "$QUALITY_RESULTS"

        # Build JSON cache
        _bc_json="{"
        _bc_first=true
        for _bc_file in "$_cache_tmpdir"/*; do
            [[ ! -f "$_bc_file" ]] && continue
            _bc_fname=$(basename "$_bc_file")
            IFS=: read -r _bc_p _bc_w _bc_f < "$_bc_file"
            _bc_t=$((_bc_p + _bc_w + _bc_f))
            $_bc_first || _bc_json+=","
            _bc_json+="\"$_bc_fname\":{\"pass\":$_bc_p,\"warn\":$_bc_w,\"fail\":$_bc_f,\"total\":$_bc_t"
            if [[ -d "$_cq_tmpdir/$_bc_fname" ]]; then
                _bc_json+=",\"quality\":{"
                _bcq_first=true
                for _qdim in correctness craft completeness; do
                    if [[ -f "$_cq_tmpdir/$_bc_fname/$_qdim" ]]; then
                        IFS=: read -r _qp _qw _qf < "$_cq_tmpdir/$_bc_fname/$_qdim"
                        _qt=$((_qp + _qw + _qf))
                        [[ "$_qt" -eq 0 ]] && continue
                        $_bcq_first || _bc_json+=","
                        _bc_json+="\"$_qdim\":{\"pass\":$_qp,\"total\":$_qt}"
                        _bcq_first=false
                    fi
                done
                _bc_json+="}"
            fi
            _bc_json+="}"
            _bc_first=false
        done
        _bc_json+="}"
        echo "{\"cached_at\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\",\"features\":$_bc_json}" > "$BELIEFS_CACHE_FILE" 2>/dev/null || true
        rm -rf "$_cache_tmpdir" "$_cq_tmpdir"
    fi
fi

# Exit code — block severity failures return non-zero
BLOCK_FAILS=0
BELIEFS_FILE_CHECK=""
for bf in lens/*/eval/beliefs.yml "config/evals/beliefs.yml"; do
    [[ -f "$bf" ]] && BELIEFS_FILE_CHECK="$bf" && break
done
if [[ -f "$BELIEFS_FILE_CHECK" && "$FAIL" -gt 0 ]]; then
    BLOCK_ON=$(grep -c 'block_on_failure: true' config/founder.yml 2>/dev/null) || BLOCK_ON=0
    if [[ "$BLOCK_ON" -gt 0 ]]; then
        BLOCK_FAILS=$FAIL
    fi
fi

if [[ "$BLOCK_FAILS" -gt 0 ]]; then
    exit 1
fi
exit 0
