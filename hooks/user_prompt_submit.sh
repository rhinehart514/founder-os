#!/usr/bin/env bash
# user_prompt_submit.sh — UserPromptSubmit hook (BLOCKING, always allows)
# Deterministic intent routing. Pattern matches user prompt against the intent table.
# Target: <10ms (pure string matching, no file I/O).

set -euo pipefail

INPUT=$(cat)

# --- Parse prompt from input JSON ---
PROMPT=""
if command -v jq &>/dev/null; then
    PROMPT=$(echo "$INPUT" | jq -r '.prompt // ""' 2>/dev/null || echo "")
else
    PROMPT=$(echo "$INPUT" | grep -o '"prompt"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/"prompt"[[:space:]]*:[[:space:]]*"//;s/"$//' 2>/dev/null || echo "")
fi

# Skip if already a slash command
if [[ "$PROMPT" == /* ]]; then
    echo '{"decision": "allow"}'
    exit 0
fi

# Skip if too long (not a natural language intent)
if [[ ${#PROMPT} -gt 200 ]]; then
    echo '{"decision": "allow"}'
    exit 0
fi

# Lowercase for matching
LOWER=$(echo "$PROMPT" | tr '[:upper:]' '[:lower:]')

SUGGESTION=""
case "$LOWER" in
    # Eval / quality (absorbs old /score routing)
    *"is this good"*|*"how's the product"*|*"how is the product"*|*"product quality"*|*"unified score"*|*"score everything"*)
        SUGGESTION="/eval" ;;
    # Eval / assertions
    *"evaluate"*|*"run assertions"*|*"check quality"*|*"check code"*|*"delivery"*|*"craft"*)
        SUGGESTION="/eval" ;;
    # Taste / visual
    *"what does it look like"*|*"visual eval"*|*"design quality"*|*"how's the ui"*|*"how is the ui"*|*"taste"*)
        SUGGESTION="/taste" ;;
    # Flows / QA
    *"does it work"*|*"test the frontend"*|*"check the flows"*|*"is it broken"*|*"qa"*|*"flawless"*)
        SUGGESTION="/taste flows" ;;
    # Plan / bottleneck
    *"what should i work on"*|*"what should we work on"*|*"start a session"*|*"what's the bottleneck"*|*"what is the bottleneck"*|*"what matters"*|*"what's important"*)
        SUGGESTION="/plan" ;;
    # Go / build
    *"just build it"*|*"just go"*|*"start building"*|*"autonomous"*|*"fix everything"*)
        SUGGESTION="/go" ;;
    # Onboard / setup
    *"set this up"*|*"bootstrap"*|*"initialize"*|*"onboard"*|*"new here"*|*"what is this project"*|*"first time"*)
        SUGGESTION="/onboard" ;;
    # Ideate
    *"brainstorm"*|*"feature ideas"*|*"what could we build"*|*"ideas"*)
        SUGGESTION="/ideate" ;;
    # Ideate (feature improvement)
    *"how to improve"*|*"make"*"better"*|*"needs work"*|*"thoughts on"*)
        SUGGESTION="/ideate" ;;
    # Research
    *"what don't we know"*|*"what do we not know"*|*"explore"*|*"gather data"*|*"research"*)
        SUGGESTION="/research" ;;
    # Dashboard / status
    *"where are we"*|*"dashboard"*|*"status"*|*"where am i"*)
        SUGGESTION="/founder" ;;
    # Roadmap
    *"what's the roadmap"*|*"what is the roadmap"*|*"versions"*|*"what's next for the project"*|*"thesis"*)
        SUGGESTION="/roadmap" ;;
    # Ship / deploy
    *"deploy"*|*"ship it"*|*"release"*)
        SUGGESTION="/ship" ;;
    # Push / quality sweep
    *"make everything better"*|*"close all gaps"*|*"push scores"*|*"quality sweep"*|*"improve everything"*)
        SUGGESTION="/push" ;;
    # Todo / backlog
    *"backlog"*|*"todo"*|*"capture this"*|*"add to backlog"*)
        SUGGESTION="/todo" ;;
    # Product thinking
    *"is this the right thing"*|*"product thinking"*|*"who cares"*|*"assumptions"*|*"should we build this"*|*"pressure test"*)
        SUGGESTION="/product" ;;
    # Money / pricing
    *"pricing"*|*"unit economics"*|*"revenue"*|*"what should we charge"*|*"business model"*|*"runway"*)
        SUGGESTION="/money" ;;
    # Copy
    *"landing page"*|*"pitch"*|*"write copy"*|*"release notes"*|*"onboarding text"*)
        SUGGESTION="/copy" ;;
    # Help
    *"what can you do"*|*"help me"*|*"how does this work"*|*"what commands"*)
        SUGGESTION="/founder help" ;;
esac

if [[ -n "$SUGGESTION" ]]; then
    echo "{\"decision\": \"allow\", \"additionalContext\": \"The user likely wants ${SUGGESTION}. Run it.\"}"
else
    echo '{"decision": "allow"}'
fi
