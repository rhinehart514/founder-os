#!/usr/bin/env bash
# init.sh — Bootstrap founder-os into any repo
# One command, zero prompts. Detects project type, generates config + assertions.

set -euo pipefail

# --- Resolve FOUNDER_DIR ---
if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    FOUNDER_DIR="$CLAUDE_PLUGIN_ROOT"
else
    _INIT_SOURCE="${BASH_SOURCE[0]}"
    while [[ -L "$_INIT_SOURCE" ]]; do _INIT_SOURCE="$(readlink "$_INIT_SOURCE")"; done
    FOUNDER_DIR="$(cd "$(dirname "$_INIT_SOURCE")/.." && pwd)"
fi

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

# --- Args ---
FORCE=false
for arg in "$@"; do
    case "$arg" in
        --force) FORCE=true ;;
        --help|-h)
            echo "Usage: founder init [--force]"
            echo "  Bootstrap founder-os into any repo."
            echo "  --force    Regenerate even if already initialized"
            exit 0
            ;;
    esac
done

echo ""
echo -e "  ${CYAN}◆${NC} ${BOLD}founder init${NC}"
echo ""

# ============================================================
# Phase 0: Guards & Detection
# ============================================================

# Idempotency guard
if [[ -f "config/founder.yml" && "$FORCE" != true ]]; then
    echo -e "  ${DIM}already initialized (config/founder.yml exists)${NC}"
    echo -e "  ${DIM}use --force to regenerate${NC}"
    echo ""
    exit 0
fi

# --- Detect project type ---
PROJECT_TYPE="unknown"

if [[ -f "package.json" ]]; then
    if grep -q '"next"' package.json 2>/dev/null; then PROJECT_TYPE="nextjs"
    elif grep -q '"react"' package.json 2>/dev/null; then PROJECT_TYPE="react"
    elif grep -q '"vue"' package.json 2>/dev/null; then PROJECT_TYPE="vue"
    elif grep -q '"svelte"' package.json 2>/dev/null; then PROJECT_TYPE="svelte"
    else PROJECT_TYPE="node"
    fi
elif [[ -f "pyproject.toml" ]] || [[ -f "setup.py" ]] || [[ -f "requirements.txt" ]]; then
    PROJECT_TYPE="python"
elif [[ -f "go.mod" ]]; then
    PROJECT_TYPE="go"
fi

# Fallbacks for projects without standard config files
if [[ "$PROJECT_TYPE" == "unknown" ]]; then
    if [[ -d "bin" ]] && find bin -maxdepth 1 \( -name "*.sh" -o -name "*.mjs" \) -print -quit 2>/dev/null | grep -q .; then
        PROJECT_TYPE="cli"
    elif find . -maxdepth 2 -name "*.py" -not -path "*/venv/*" -not -path "*/.venv/*" -print -quit 2>/dev/null | grep -q .; then
        PROJECT_TYPE="python"
    elif find . -maxdepth 2 -name "*.go" -print -quit 2>/dev/null | grep -q .; then
        PROJECT_TYPE="go"
    fi
fi

# --- Detect SRC_DIR ---
SRC_DIR=""
if [[ -d "apps/web/src" ]]; then SRC_DIR="apps/web/src"
elif [[ -d "src" ]]; then SRC_DIR="src"
elif [[ -d "app" ]]; then SRC_DIR="app"
elif [[ -d "bin" ]]; then SRC_DIR="bin"
fi

# --- Detect project name ---
PROJECT_NAME=""
if [[ -f "package.json" ]] && command -v jq &>/dev/null; then
    PROJECT_NAME=$(jq -r '.name // empty' package.json 2>/dev/null)
fi
if [[ -z "$PROJECT_NAME" ]]; then
    PROJECT_NAME=$(basename "$(pwd)")
fi

echo -e "  ${GREEN}✓${NC} detected: ${BOLD}$PROJECT_TYPE${NC} ($SRC_DIR/)"

# --- Auto-detect features ---
FEATURES=()
FEATURE_PATHS=()

# Next.js route groups: app/(group)/
if [[ -d "app" ]]; then
    for d in app/\(*/; do
        [[ ! -d "$d" ]] && continue
        name=$(basename "$d" | tr -d '()')
        FEATURES+=("$name")
        FEATURE_PATHS+=("$d")
    done
fi

# Top-level src directories (skip common utility dirs)
if [[ -d "src" ]]; then
    for d in src/*/; do
        [[ ! -d "$d" ]] && continue
        name=$(basename "$d")
        [[ "$name" == "components" || "$name" == "lib" || "$name" == "utils" || "$name" == "styles" || "$name" == "types" || "$name" == "hooks" || "$name" == "assets" || "$name" == "config" ]] && continue
        FEATURES+=("$name")
        FEATURE_PATHS+=("$d")
    done
fi

# Package workspaces (npm workspaces, pnpm workspaces, turbo)
if [[ -f "package.json" ]] && { grep -q '"workspaces"' package.json 2>/dev/null || grep -q '"packageManager"' package.json 2>/dev/null; }; then
    for ws in packages/*/; do
        [[ ! -d "$ws" ]] && continue
        name=$(basename "$ws")
        FEATURES+=("$name")
        FEATURE_PATHS+=("$ws")
    done
fi

# Monorepo apps (apps/*/ is a common pattern)
if [[ -d "apps" ]]; then
    for app_dir in apps/*/; do
        [[ ! -d "$app_dir" ]] && continue
        name=$(basename "$app_dir")
        FEATURES+=("$name")
        FEATURE_PATHS+=("$app_dir")
    done
fi

# CLI scripts
if [[ -d "bin" ]]; then
    for f in bin/*.sh bin/*.mjs; do
        [[ ! -f "$f" ]] && continue
        name=$(basename "$f" | sed 's/\.[^.]*$//')
        FEATURES+=("$name")
        FEATURE_PATHS+=("$f")
    done
fi

# lib/ modules (common in Node libraries like commander.js, express, etc.)
if [[ -d "lib" ]] && [[ ${#FEATURES[@]} -eq 0 ]]; then
    for f in lib/*.js lib/*.ts lib/*.mjs; do
        [[ ! -f "$f" ]] && continue
        name=$(basename "$f" | sed 's/\.[^.]*$//')
        [[ "$name" == "index" || "$name" == "main" ]] && continue
        FEATURES+=("$name")
        FEATURE_PATHS+=("$f")
    done
fi

if [[ ${#FEATURES[@]} -gt 0 ]]; then
    echo -e "  ${GREEN}✓${NC} features: ${BOLD}${FEATURES[*]}${NC} (${#FEATURES[@]} detected)"
else
    echo -e "  ${DIM}·${NC} no features auto-detected"
fi

# ============================================================
# Phase 1: Build project profile via Claude
# ============================================================

CLAUDE_ANALYZED=false
DESCRIPTION=""
USER=""
HYPOTHESIS=""
# Per-feature Claude data (parallel arrays — bash 3 compatible)
FEAT_DELIVERS_KEYS=""
FEAT_DELIVERS_VALS=""
FEAT_FOR_KEYS=""
FEAT_FOR_VALS=""
FEAT_WEIGHT_KEYS=""
FEAT_WEIGHT_VALS=""

# Helper: set feature data (bash 3 compatible — no associative arrays)
_set_feat_delivers() { FEAT_DELIVERS_KEYS="${FEAT_DELIVERS_KEYS}${1}|"; FEAT_DELIVERS_VALS="${FEAT_DELIVERS_VALS}${2}|"; }
_set_feat_for() { FEAT_FOR_KEYS="${FEAT_FOR_KEYS}${1}|"; FEAT_FOR_VALS="${FEAT_FOR_VALS}${2}|"; }
_set_feat_weight() { FEAT_WEIGHT_KEYS="${FEAT_WEIGHT_KEYS}${1}|"; FEAT_WEIGHT_VALS="${FEAT_WEIGHT_VALS}${2}|"; }
_get_feat_delivers() {
    local key="$1" i=1
    echo "$FEAT_DELIVERS_KEYS" | tr '|' '\n' | while read -r k; do
        if [[ "$k" == "$key" ]]; then
            echo "$FEAT_DELIVERS_VALS" | cut -d'|' -f"$i"
            return
        fi
        i=$((i + 1))
    done
}
_get_feat_for() {
    local key="$1" i=1
    echo "$FEAT_FOR_KEYS" | tr '|' '\n' | while read -r k; do
        if [[ "$k" == "$key" ]]; then
            echo "$FEAT_FOR_VALS" | cut -d'|' -f"$i"
            return
        fi
        i=$((i + 1))
    done
}
_get_feat_weight() {
    local key="$1" i=1
    echo "$FEAT_WEIGHT_KEYS" | tr '|' '\n' | while read -r k; do
        if [[ "$k" == "$key" ]]; then
            echo "$FEAT_WEIGHT_VALS" | cut -d'|' -f"$i"
            return
        fi
        i=$((i + 1))
    done
}

# --- Gather context ---
CONTEXT=""

# README
if [[ -f "README.md" ]]; then
    CONTEXT+="=== README.md (first 200 lines) ===
$(head -200 README.md)

"
fi

# Package description
if [[ -f "package.json" ]] && command -v jq &>/dev/null; then
    PKG_DESC=$(jq -r '.description // empty' package.json 2>/dev/null)
    if [[ -n "$PKG_DESC" ]]; then
        CONTEXT+="=== package.json description ===
${PKG_DESC}

"
    fi
elif [[ -f "pyproject.toml" ]]; then
    PYPROJ_DESC=$(grep -m1 'description' pyproject.toml 2>/dev/null | sed 's/.*= *"//' | sed 's/".*//' || true)
    if [[ -n "$PYPROJ_DESC" ]]; then
        CONTEXT+="=== pyproject.toml description ===
${PYPROJ_DESC}

"
    fi
fi

# Directory listing
if [[ -n "$SRC_DIR" && -d "$SRC_DIR" ]]; then
    CONTEXT+="=== ${SRC_DIR}/ listing (first 30) ===
$(ls "$SRC_DIR" 2>/dev/null | head -30)

"
fi

# Key source files (first 5 that exist, first 100 lines each)
KEY_FILES_FOUND=0
for candidate in app/page.tsx src/App.tsx src/index.ts app/layout.tsx index.ts main.py main.go; do
    if [[ -f "$candidate" && "$KEY_FILES_FOUND" -lt 5 ]]; then
        CONTEXT+="=== ${candidate} (first 100 lines) ===
$(head -100 "$candidate")

"
        KEY_FILES_FOUND=$((KEY_FILES_FOUND + 1))
    fi
done

# --- Build feature names list ---
FEATURE_NAMES=""
if [[ ${#FEATURES[@]} -gt 0 ]]; then
    FEATURE_NAMES=$(printf '%s, ' "${FEATURES[@]}")
    FEATURE_NAMES="${FEATURE_NAMES%, }"
fi

# --- Call Claude if available ---
if command -v claude &>/dev/null; then
    PROMPT="Analyze this codebase and return ONLY a JSON object:
{\"description\":\"one-line project description\",\"user\":\"who specifically uses this\",\"hypothesis\":\"value hypothesis in format: Users can X faster/better than Y\",\"features\":{}}

For the features object, use these detected feature names as keys: [${FEATURE_NAMES}]
For each, add: {\"delivers\":\"specific value this delivers\",\"for\":\"who uses it\",\"weight\":N}
weight is 1-5 — how critical is this feature to the value hypothesis? Core features that the hypothesis depends on = 4-5. Supporting/utility features = 1-2.

Be specific. Not \"handles auth\" but \"user signup and login with OAuth\".
Not \"users\" but \"sales teams who share decks with prospects\".

Context:
${CONTEXT}"

    echo -e "  ${DIM}·${NC} analyzing project with Claude..."
    CLAUDE_RESULT=$(claude -p "$PROMPT" --model haiku 2>/dev/null) || CLAUDE_RESULT=""

    if [[ -n "$CLAUDE_RESULT" ]]; then
        # Strip markdown fences if present
        CLEANED=$(echo "$CLAUDE_RESULT" | sed '/^```/d')

        if echo "$CLEANED" | jq -c . &>/dev/null 2>&1; then
            DESCRIPTION=$(echo "$CLEANED" | jq -r '.description // empty' 2>/dev/null)
            USER=$(echo "$CLEANED" | jq -r '.user // empty' 2>/dev/null)
            HYPOTHESIS=$(echo "$CLEANED" | jq -r '.hypothesis // empty' 2>/dev/null)

            # Extract per-feature data
            for feat in "${FEATURES[@]+"${FEATURES[@]}"}"; do
                feat_delivers=$(echo "$CLEANED" | jq -r --arg f "$feat" '.features[$f].delivers // empty' 2>/dev/null)
                feat_for=$(echo "$CLEANED" | jq -r --arg f "$feat" '.features[$f].for // empty' 2>/dev/null)
                feat_weight=$(echo "$CLEANED" | jq -r --arg f "$feat" '.features[$f].weight // empty' 2>/dev/null)
                [[ -n "$feat_delivers" ]] && _set_feat_delivers "$feat" "$feat_delivers"
                [[ -n "$feat_for" ]] && _set_feat_for "$feat" "$feat_for"
                [[ -n "$feat_weight" && "$feat_weight" =~ ^[1-5]$ ]] && _set_feat_weight "$feat" "$feat_weight"
            done

            CLAUDE_ANALYZED=true
            echo -e "  ${GREEN}✓${NC} project profile built"
        fi
    fi
fi

if [[ "$CLAUDE_ANALYZED" != true ]]; then
    if ! command -v claude &>/dev/null && [[ -z "${ANTHROPIC_API_KEY:-}" ]]; then
        echo -e "  ${YELLOW}⚠${NC} Claude CLI not available — config will have placeholder values"
        echo -e "    ${DIM}Run${NC} ${BOLD}/init --force${NC} ${DIM}inside Claude Code for full project analysis${NC}"
    fi
fi

# ============================================================
# Phase 2: Generate config/founder.yml
# ============================================================
mkdir -p config

if [[ "$CLAUDE_ANALYZED" == true ]]; then
    # Use Claude's analysis — no placeholders
    :
else
    # Fallback placeholders by project type
    case "$PROJECT_TYPE" in
        nextjs|react|vue|svelte)
            HYPOTHESIS="Users can [do X] faster than alternatives" ;;
        node|cli)
            HYPOTHESIS="Developers can [do X] with this tool" ;;
        python)
            HYPOTHESIS="Users can [do X] with this library" ;;
        go)
            HYPOTHESIS="Users can [do X] with this tool" ;;
        *)
            HYPOTHESIS="Users get [specific value] from this project" ;;
    esac
    USER="[Who specifically uses this?]"
    DESCRIPTION=""
fi

# Build features section for founder.yml
FEATURES_YAML=""
FEATURE_COUNT=0

if [[ ${#FEATURES[@]} -gt 0 ]]; then
    FEATURES_YAML="
# ── Features ─────────────────────────────────────────
# Each feature declares what it delivers and for whom.
# founder eval reads these and has Claude judge the gap.
#
# Maturity computed from eval scores (not manual):
#   0-29=planned, 30-49=building, 50-69=working, 70-89=polished, 90+=proven
# weight: 1-5 (importance to value hypothesis)
# depends_on: [feature_name] (what must work first)
features:"

    for i in "${!FEATURES[@]}"; do
        feat="${FEATURES[$i]}"
        feat_path="${FEATURE_PATHS[$i]}"

        if [[ "$CLAUDE_ANALYZED" == true ]]; then
            delivers_text=$(_get_feat_delivers "$feat")
            [[ -z "$delivers_text" ]] && delivers_text="[what ${feat} delivers — edit this]"
            for_text=$(_get_feat_for "$feat")
            [[ -z "$for_text" ]] && for_text="[who uses ${feat}]"
        else
            # Fallback: infer from file/directory type
            delivers_text="[what ${feat} delivers — edit this]"
            for_text="[who uses ${feat}]"

            if [[ "$feat_path" == app/\(* ]]; then
                delivers_text="[what the ${feat} section of the app delivers]"
                for_text="end users"
            elif [[ -f "$feat_path" ]]; then
                # Script — read first comment line for description
                desc=$(grep '^#' "$feat_path" 2>/dev/null | grep -v '^#!' | head -1 | sed 's/^# *//')
                [[ -n "$desc" ]] && delivers_text="$desc"
                for_text="developers using the CLI"
            elif [[ -d "$feat_path" ]]; then
                delivers_text="[what ${feat} delivers]"
                for_text="[who uses ${feat}]"
            fi
        fi

        # --- Infer weight from Claude analysis or default ---
        feat_weight=$(_get_feat_weight "$feat")
        [[ -z "$feat_weight" || ! "$feat_weight" =~ ^[1-5]$ ]] && feat_weight=1

        FEATURES_YAML+="
  ${feat}:
    delivers: \"${delivers_text}\"
    for: \"${for_text}\"
    code: [\"${feat_path}\"]
    status: active
    weight: ${feat_weight}"
        FEATURE_COUNT=$((FEATURE_COUNT + 1))
    done

    # --- Auto-detect depends_on from import chains ---
    # For each feature, check if its code imports from another feature's code paths
    # Collect deps as "feat:dep1,dep2" entries, then patch the YAML
    DEPS_LIST=""
    for i in "${!FEATURES[@]}"; do
        feat="${FEATURES[$i]}"
        feat_path="${FEATURE_PATHS[$i]}"
        deps=""

        for j in "${!FEATURES[@]}"; do
            [[ "$i" == "$j" ]] && continue
            other="${FEATURES[$j]}"
            other_path="${FEATURE_PATHS[$j]}"

            # Normalize other_path for import matching (strip trailing slash, leading ./)
            other_import="${other_path%/}"
            other_import="${other_import#./}"

            # Search for imports/requires of the other feature's path in this feature's code
            found_dep=false
            if [[ -f "$feat_path" ]]; then
                if grep -qE "(import .+ from ['\"].*${other_import}|require\(['\"].*${other_import}|from ${other_import})" "$feat_path" 2>/dev/null; then
                    found_dep=true
                fi
            elif [[ -d "$feat_path" ]]; then
                if grep -rqE "(import .+ from ['\"].*${other_import}|require\(['\"].*${other_import}|from ${other_import})" "$feat_path" 2>/dev/null; then
                    found_dep=true
                fi
            fi

            if [[ "$found_dep" == true ]]; then
                if [[ -z "$deps" ]]; then
                    deps="$other"
                else
                    deps="${deps}, ${other}"
                fi
            fi
        done

        if [[ -n "$deps" ]]; then
            # Append depends_on line after the weight line for this feature
            FEATURES_YAML=$(printf '%s' "$FEATURES_YAML" | awk -v feat="  ${feat}:" -v depline="    depends_on: [${deps}]" '
                $0 == feat { in_feat=1 }
                in_feat && /^    weight:/ { print; print depline; in_feat=0; next }
                { print }
            ')
        fi
    done
fi

cat > config/founder.yml <<FOUNDER_YML
project:
  stage: mvp
  mode: build

value:
  hypothesis: "$HYPOTHESIS"
  user: "$USER"
  signals:
    - name: core_value
      description: "[What the product delivers]"
      target: "[How to measure it]"
      measurable: false
${FEATURES_YAML}

scoring:
  cache_ttl: 300
  health_gate_threshold: 20
  health_warn_threshold: 40
  onboarding_cap: 50

evals:
  generative: true
  beliefs_fallback: true
FOUNDER_YML

echo -e "  ${GREEN}✓${NC} config/founder.yml (${FEATURE_COUNT} features)"

# --- Basic YAML validation ---
YAML_OK=true
if [[ ! -s "config/founder.yml" ]]; then
    echo -e "  ${RED}✗${NC} config/founder.yml is empty — generation failed"
    YAML_OK=false
elif ! grep -q '^value:' config/founder.yml 2>/dev/null; then
    echo -e "  ${RED}✗${NC} config/founder.yml missing 'value:' section"
    YAML_OK=false
elif ! grep -q 'hypothesis:' config/founder.yml 2>/dev/null; then
    echo -e "  ${RED}✗${NC} config/founder.yml missing 'hypothesis:'"
    YAML_OK=false
fi
if [[ "$YAML_OK" != true ]]; then
    echo -e "  ${DIM}Try:${NC} ${BOLD}/init --force${NC} ${DIM}inside Claude Code to regenerate${NC}"
fi

# ============================================================
# Phase 2b: Generate config/evals/beliefs.yml
# ============================================================
mkdir -p config/evals

if [[ ! -f "config/evals/beliefs.yml" ]]; then
    # Build project-appropriate assertions
    cat > config/evals/beliefs.yml <<'BELIEFS_HEADER'
# beliefs.yml — What must be true about this project
#
# Types:
#   file_check     — file exists, contains string, min lines
#   command_check  — run a shell command, exit 0 = pass (runs in project dir)
#   llm_judge      — Claude evaluates code against a prompt (requires prompt: field)
#   feature_review — Claude evaluates feature completeness
#
# Fields:
#   id:        unique identifier
#   belief:    human-readable description
#   type:      one of the types above
#   severity:  block (score = 0 if failing) | warn (flags but continues)
#   path:      file or directory to check (file_check, llm_judge)
#   contains:  string that must appear in the file (file_check)
#   min_lines: minimum line count (file_check)
#   command:   shell command to run (command_check)
#   prompt:    evaluation question for Claude (llm_judge)
#   feature:   feature name to scope context (llm_judge, feature_review)

beliefs:
BELIEFS_HEADER

    # Always: project has a value hypothesis
    cat >> config/evals/beliefs.yml <<'BELIEFS_CORE'

  # ── Core — does the project know what it's for? ──

  - id: has-value-hypothesis
    belief: "Project has a defined value hypothesis"
    type: file_check
    path: "config/founder.yml"
    contains: "hypothesis:"
    severity: block

  - id: has-readme
    belief: "README exists and explains the project"
    type: file_check
    path: "README.md"
    min_lines: 5
    severity: warn
BELIEFS_CORE

    # Project-type-specific assertions
    case "$PROJECT_TYPE" in
        nextjs|react|vue|svelte)
            cat >> config/evals/beliefs.yml <<'BELIEFS_WEB'

  # ── Web — does the app build and render? ──

  - id: build-succeeds
    belief: "Project builds without errors"
    type: command_check
    command: npm run build 2>&1 | tail -1
    severity: block

  - id: no-console-log-in-components
    belief: "No console.log left in component files"
    type: command_check
    command: "! grep -r 'console.log' src/ --include='*.tsx' --include='*.jsx' --include='*.vue' --include='*.svelte' -l 2>/dev/null | head -1 | grep -q ."
    severity: warn

  - id: has-entry-point
    belief: "App has a main entry point"
    type: command_check
    command: test -f src/App.tsx -o -f src/App.jsx -o -f src/main.tsx -o -f src/main.ts -o -f app/page.tsx -o -f app/layout.tsx -o -f src/App.vue -o -f src/App.svelte
    severity: warn
BELIEFS_WEB
            ;;
        node|cli)
            cat >> config/evals/beliefs.yml <<'BELIEFS_CLI'

  # ── CLI/Node — does the tool run? ──

  - id: main-entry-exists
    belief: "Main entry point exists"
    type: command_check
    command: "test -f index.js -o -f index.mjs -o -f index.cjs -o -f lib/index.js -o -f src/index.ts -o -f src/index.js || node -e 'var m=require(\"./package.json\").main;if(!m)process.exit(1);require(\"fs\").accessSync(m)' 2>/dev/null"
    severity: warn

  - id: tests-pass
    belief: "Test suite passes"
    type: command_check
    command: npm test 2>&1 | tail -1
    severity: warn
BELIEFS_CLI
            ;;
        python)
            cat >> config/evals/beliefs.yml <<'BELIEFS_PY'

  # ── Python — does the code run? ──

  - id: no-syntax-errors
    belief: "No Python syntax errors"
    type: command_check
    command: python -m py_compile $(find . -name '*.py' -not -path '*/venv/*' -not -path '*/.venv/*' | head -5) 2>&1
    severity: block

  - id: tests-pass
    belief: "Test suite passes"
    type: command_check
    command: python -m pytest --tb=no -q 2>&1 | tail -1
    severity: warn
BELIEFS_PY
            ;;
        go)
            cat >> config/evals/beliefs.yml <<'BELIEFS_GO'

  # ── Go — does the code compile? ──

  - id: build-succeeds
    belief: "Go build succeeds"
    type: command_check
    command: go build ./... 2>&1
    severity: block

  - id: tests-pass
    belief: "Go tests pass"
    type: command_check
    command: go test ./... 2>&1 | tail -3
    severity: warn
BELIEFS_GO
            ;;
    esac

    # Feature-specific assertions (if features were detected)
    if [[ ${#FEATURES[@]} -gt 0 ]]; then
        echo "" >> config/evals/beliefs.yml
        echo "  # ── Features — do they exist and have substance? ──" >> config/evals/beliefs.yml
        for i in "${!FEATURES[@]}"; do
            feat="${FEATURES[$i]}"
            feat_path="${FEATURE_PATHS[$i]}"
            if [[ -f "$feat_path" ]]; then
                # File feature — check it has real content (not a stub)
                cat >> config/evals/beliefs.yml <<BELIEFS_FEAT

  - id: ${feat}-has-substance
    belief: "${feat} has real implementation (not a stub)"
    type: file_check
    path: "${feat_path}"
    min_lines: 10
    feature: ${feat}
    severity: warn
BELIEFS_FEAT
            elif [[ -d "$feat_path" ]]; then
                # Directory feature — check it has files
                cat >> config/evals/beliefs.yml <<BELIEFS_FEAT

  - id: ${feat}-has-substance
    belief: "${feat} has real implementation"
    type: command_check
    command: test \$(find ${feat_path} -type f \\( -name '*.ts' -o -name '*.tsx' -o -name '*.js' -o -name '*.py' -o -name '*.go' -o -name '*.sh' \\) 2>/dev/null | wc -l | tr -d ' ') -ge 1
    feature: ${feat}
    severity: warn
BELIEFS_FEAT
            fi
        done
    fi

    echo -e "  ${GREEN}✓${NC} config/evals/beliefs.yml"
else
    echo -e "  ${DIM}·${NC} config/evals/beliefs.yml (exists)"
fi

# ============================================================
# Phase 2c: Generate project CLAUDE.md
# ============================================================
if [[ ! -f "CLAUDE.md" || "$FORCE" == true ]]; then
    # Build feature list for CLAUDE.md
    CLAUDE_MD_FEATURES=""
    if [[ ${#FEATURES[@]} -gt 0 ]]; then
        for i in "${!FEATURES[@]}"; do
            feat="${FEATURES[$i]}"
            if [[ "$CLAUDE_ANALYZED" == true ]]; then
                feat_del=$(_get_feat_delivers "$feat")
                [[ -z "$feat_del" ]] && feat_del="see config/founder.yml"
            else
                feat_del="see config/founder.yml"
            fi
            CLAUDE_MD_FEATURES+="- **${feat}** — ${feat_del}
"
        done
    fi

    # Hypothesis display (strip bracket placeholders)
    CLAUDE_HYPO="$HYPOTHESIS"
    [[ "$CLAUDE_HYPO" == \[* ]] && CLAUDE_HYPO="(edit config/founder.yml to define)"

    cat > CLAUDE.md <<CLAUDE_MD
# ${PROJECT_NAME}

## Value Hypothesis
${CLAUDE_HYPO}

## Features
${CLAUDE_MD_FEATURES:-No features detected yet. Run \`/init --force\` after adding code.}
## Do NOT Build
<!-- Add things here that should never be built, to prevent drift -->

## Configuration
- Project config: \`config/founder.yml\`
- Assertions: \`config/evals/beliefs.yml\`
- Plans: \`.claude/plans/\`

## Notes
Global \`~/.claude/CLAUDE.md\` provides founder-os methodology (measurement, learning loop, commands).
This file is project-specific — value hypothesis, features, and constraints for this codebase.
CLAUDE_MD
    echo -e "  ${GREEN}✓${NC} CLAUDE.md (project-level)"
else
    echo -e "  ${DIM}·${NC} CLAUDE.md (exists)"
fi

# ============================================================
# Phase 3: Create .claude/ structure
# ============================================================
mkdir -p .claude/cache .claude/scores .claude/plans

# --- Scaffold planning files ---

# roadmap.yml — version theses
if [[ ! -f ".claude/plans/roadmap.yml" ]]; then
    cat > .claude/plans/roadmap.yml <<ROADMAP
# roadmap.yml — Theses, not releases
# Each version is a question we're testing.

current: v1.0

versions:
  v1.0:
    thesis: "${PROJECT_NAME} can be measured and improved"
    status: testing
    goal: "Bootstrap complete. Can the measurement loop find real improvements?"
    evidence_needed:
      - id: init-clean
        question: "Does init produce a useful config?"
        status: proven
        evidence: "config/founder.yml generated with ${FEATURE_COUNT} features"
      - id: first-eval
        question: "Does eval produce meaningful scores?"
        status: testing
      - id: first-improvement
        question: "Does /go produce a measurable improvement?"
        status: todo
ROADMAP
    echo -e "  ${GREEN}✓${NC} .claude/plans/roadmap.yml"
fi

# strategy.yml — current bottleneck
if [[ ! -f ".claude/plans/strategy.yml" ]]; then
    # Find worst feature for initial bottleneck
    INIT_BOTTLENECK="unknown"
    if [[ ${#FEATURES[@]} -gt 0 ]]; then
        INIT_BOTTLENECK="${FEATURES[0]}"
    fi
    cat > .claude/plans/strategy.yml <<STRATEGY
# strategy.yml — Current bottleneck and product model
stage: mvp
bottleneck: "${INIT_BOTTLENECK}"
bottleneck_reason: "First init — run /plan to diagnose the real bottleneck"
updated: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
STRATEGY
    echo -e "  ${GREEN}✓${NC} .claude/plans/strategy.yml"
fi

# todos.yml — persistent backlog
if [[ ! -f ".claude/plans/todos.yml" ]]; then
    cat > .claude/plans/todos.yml <<TODOS
# todos.yml — Persistent backlog
# /plan promotes items from here. /go works through them.
# Format: - id: short-id | title: text | feature: name | status: backlog|active|done

items:
TODOS
    echo -e "  ${GREEN}✓${NC} .claude/plans/todos.yml"
fi

# plan.yml — current session plan (empty until /plan runs)
if [[ ! -f ".claude/plans/plan.yml" ]]; then
    cat > .claude/plans/plan.yml <<PLAN
# plan.yml — Current session plan
# Run /plan to populate this with moves and predictions.

meta:
  name: "Initial setup"
  bottleneck: "Run /plan to diagnose"
  created: "$(date -u +%Y-%m-%dT%H:%M:%SZ)"

tasks: []
PLAN
    echo -e "  ${GREEN}✓${NC} .claude/plans/plan.yml"
fi

echo -e "  ${GREEN}✓${NC} .claude/ directories"

# ============================================================
# Phase 3b: Scaffold .claude/ for project-local Claude Code config
# ============================================================

if [[ -z "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    # 3b-i. Symlink mind files into .claude/rules/
    mkdir -p .claude/rules
    for mind_file in identity.md thinking.md standards.md; do
        src="$FOUNDER_DIR/mind/$mind_file"
        target=".claude/rules/$mind_file"
        if [[ -f "$src" ]]; then
            ln -sf "$src" "$target"
        fi
    done
    # Lens mind files
    for lens_dir in "$FOUNDER_DIR"/lens/*/mind; do
        [[ ! -d "$lens_dir" ]] && continue
        for lens_mind in "$lens_dir"/*.md; do
            [[ ! -f "$lens_mind" ]] && continue
            name="$(basename "$lens_mind")"
            ln -sf "$lens_mind" ".claude/rules/$name"
        done
    done

    # 3b-ii. Skills are commands — plugin system handles routing
    # No command symlinks needed. skills/*/SKILL.md are auto-discovered.

    # 3b-iii. Generate .claude/settings.json
    SETTINGS_TARGET=".claude/settings.json"
    FOUNDER_SETTINGS='{
      "hooks": {
        "SessionStart": [
          {
            "matcher": "",
            "hooks": [
              {
                "type": "command",
                "command": "'"$FOUNDER_DIR"'/hooks/session_start.sh"
              }
            ]
          }
        ],
        "PreCompact": [
          {
            "matcher": "",
            "hooks": [
              {
                "type": "command",
                "command": "'"$FOUNDER_DIR"'/hooks/pre_compact.sh"
              }
            ]
          }
        ],
        "PostToolUse": [
          {
            "matcher": "Edit|Write",
            "hooks": [
              {
                "type": "command",
                "command": "'"$FOUNDER_DIR"'/hooks/post_edit.sh"
              },
              {
                "type": "command",
                "command": "'"$FOUNDER_DIR"'/hooks/post_skill.sh"
              }
            ]
          }
        ]
      }
    }'

    if [[ -f "$SETTINGS_TARGET" ]]; then
        if command -v jq &>/dev/null; then
            # Merge: preserve existing settings, overlay hooks
            tmp="$(mktemp)"
            echo "$FOUNDER_SETTINGS" | jq -s '.[0] * {hooks: .[1].hooks}' "$SETTINGS_TARGET" - > "$tmp" && mv "$tmp" "$SETTINGS_TARGET"
        else
            echo -e "  ${YELLOW}⚠${NC} jq not found — .claude/settings.json not updated (has existing content)"
        fi
    else
        echo "$FOUNDER_SETTINGS" > "$SETTINGS_TARGET"
    fi
else
    echo -e "  ${DIM}plugin mode — rules, commands, hooks delivered via plugin system${NC}"
fi

# 3b-iv. Append to .gitignore
GITIGNORE_ENTRIES=(".claude/rules/" ".claude/settings.json" ".claude/knowledge/" ".claude/cache/" ".claude/plans/" ".claude/scores/")
if [[ ! -f .gitignore ]]; then
    printf '%s\n' "${GITIGNORE_ENTRIES[@]}" > .gitignore
else
    for entry in "${GITIGNORE_ENTRIES[@]}"; do
        if ! grep -qF "$entry" .gitignore 2>/dev/null; then
            echo "$entry" >> .gitignore
        fi
    done
fi

echo -e "  ${GREEN}✓${NC} .claude/ scaffolding (rules, commands, hooks)"

# ============================================================
# Phase 3c: Create project-local knowledge files
# ============================================================
# Predictions and learnings should be per-project, not global
mkdir -p .claude/knowledge

if [[ ! -f ".claude/knowledge/predictions.tsv" ]]; then
    printf "date\tagent\tprediction\tevidence\tresult\tcorrect\tmodel_update\n" > .claude/knowledge/predictions.tsv
    echo -e "  ${GREEN}✓${NC} .claude/knowledge/predictions.tsv"
fi

if [[ ! -f ".claude/knowledge/experiment-learnings.md" ]]; then
    cat > .claude/knowledge/experiment-learnings.md <<'LEARNINGS'
# Experiment Learnings

## Known Patterns (3+ experiments, high confidence)
(none yet — build the model through predictions)

## Uncertain Patterns (1-2 experiments, test again)
(none yet)

## Unknown Territory (0 experiments, highest information value)
- What are the most impactful changes for this codebase?
- What patterns does the codebase follow that scoring should respect?
- What does "value" mean for this specific product?

## Dead Ends (confirmed failures)
(none yet)
LEARNINGS
    echo -e "  ${GREEN}✓${NC} .claude/knowledge/experiment-learnings.md"
fi

# ============================================================
# Phase 4: Validate & Output
# ============================================================

# --- Score bar helper ---
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

# --- Run first eval ---
SCORE=""
if [[ -f "$FOUNDER_DIR/bin/score.sh" ]]; then
    SCORE=$(bash "$FOUNDER_DIR/bin/score.sh" . --quiet --force 2>/dev/null) || SCORE=""
fi

# --- Display ---
echo ""
SEP="  ${DIM}⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯${NC}"

DESC_DISPLAY="${DESCRIPTION:-initialized}"
USER_DISPLAY="${USER:-edit config/founder.yml}"
# Strip bracket placeholders for display
[[ "$USER_DISPLAY" == \[* ]] && USER_DISPLAY="edit config/founder.yml"

echo -e "${SEP}"
echo -e "  ${BOLD}${PROJECT_NAME}${NC} ${DIM}—${NC} ${DESC_DISPLAY}"
echo -e "  ${DIM}for:${NC} ${USER_DISPLAY}"
echo -e "  ${DIM}hypothesis:${NC} \"${HYPOTHESIS}\""
echo ""
echo -e "  ${GREEN}✓${NC} config/founder.yml (${FEATURE_COUNT} features)"
echo -e "  ${GREEN}✓${NC} first eval complete"
echo ""

if [[ -n "$SCORE" ]]; then
    SCORE_NUM="${SCORE%%[^0-9]*}"
    [[ -z "$SCORE_NUM" ]] && SCORE_NUM=0
    SCORE_BAR=$(print_score_bar "$SCORE_NUM")
    echo -e "  ${DIM}score${NC}  ${BOLD}${SCORE}/100${NC}  ${SCORE_BAR}"
else
    echo -e "  ${DIM}score${NC}  ${DIM}—${NC}"
fi
echo -e "         ${DIM}${FEATURE_COUNT} features${NC}"
echo ""
# Explain what the score means for a new user
if [[ -n "$SCORE" && "$SCORE_NUM" -le 50 ]]; then
    echo -e "  ${DIM}The score is your assertion pass rate — what % of your${NC}"
    echo -e "  ${DIM}project's beliefs are passing. Low after init is normal.${NC}"
    echo -e "  ${DIM}/plan finds what to fix. /go builds toward passing.${NC}"
fi

echo -e "${SEP}"
echo ""
echo -e "  ${DIM}next:${NC} ${BOLD}/plan${NC}                 ${DIM}find the bottleneck${NC}"
echo -e "        ${BOLD}/product${NC}              ${DIM}product thinking session${NC}"
echo -e "        ${BOLD}/roadmap${NC}              ${DIM}see your thesis${NC}"
echo ""
