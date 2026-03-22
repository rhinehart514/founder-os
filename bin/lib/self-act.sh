# ============================================================
# ACT (25 pts) — Can it execute?
# ============================================================
CURRENT_SYSTEM="act"

# commands-depth (5 pts): slash commands are substantive, not stubs
SKILL_DIR="$FOUNDER_DIR/skills"
if [[ -d "$SKILL_DIR" ]]; then
    STUB_COUNT=0
    SKILL_COUNT=0
    for skill_file in "$SKILL_DIR"/*/SKILL.md; do
        [[ ! -f "$skill_file" ]] && continue
        SKILL_COUNT=$((SKILL_COUNT + 1))
        lines=$(wc -l < "$skill_file" 2>/dev/null | tr -d ' ')
        if [[ "$lines" -lt 20 ]]; then
            STUB_COUNT=$((STUB_COUNT + 1))
        fi
    done
    if [[ "$SKILL_COUNT" -eq 0 ]]; then
        check_fail "skills-depth" "no skills found" 5
    elif [[ "$STUB_COUNT" -gt 0 ]]; then
        check_warn "skills-depth" "$STUB_COUNT/$SKILL_COUNT skills are stubs (<20 lines)" 2 5
    else
        check_pass "skills-depth" "$SKILL_COUNT skills, all substantive" 5
    fi
else
    check_fail "skills-depth" "no skills directory" 5
fi

# hook-health (5 pts): hooks resolve and are executable
HOOK_TIMEOUT_MS=$(cfg self.hook_timeout_ms 200)
HOOKS_BROKEN=0
HOOKS_CHECKED=0

if [[ -n "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
    # Plugin mode: validate hooks.json and referenced .sh files
    HOOKS_JSON="$FOUNDER_DIR/hooks/hooks.json"
    if [[ -f "$HOOKS_JSON" ]] && command -v jq &>/dev/null; then
        while IFS= read -r hook_cmd; do
            [[ -z "$hook_cmd" ]] && continue
            HOOKS_CHECKED=$((HOOKS_CHECKED + 1))
            # Expand ${CLAUDE_PLUGIN_ROOT} template variable
            hook_cmd="${hook_cmd//\$\{CLAUDE_PLUGIN_ROOT\}/$FOUNDER_DIR}"
            # Strip quotes used for paths with spaces
            hook_cmd="${hook_cmd//\"/}"
            # Extract just the executable (first word before args)
            local_cmd="${hook_cmd%% *}"
            if [[ ! -f "$local_cmd" ]]; then
                HOOKS_BROKEN=$((HOOKS_BROKEN + 1))
            elif [[ ! -x "$local_cmd" ]]; then
                HOOKS_BROKEN=$((HOOKS_BROKEN + 1))
            fi
        done < <(jq -r '.. | .command? // empty' "$HOOKS_JSON" 2>/dev/null)
    elif [[ ! -f "$HOOKS_JSON" ]]; then
        HOOKS_BROKEN=1
        HOOKS_CHECKED=1
    fi
elif [[ -f "$PWD/.claude/settings.json" ]] && command -v jq &>/dev/null; then
    # Project-local: parse settings.json for hook commands
    while IFS= read -r hook_cmd; do
        [[ -z "$hook_cmd" ]] && continue
        HOOKS_CHECKED=$((HOOKS_CHECKED + 1))
        if [[ ! -f "$hook_cmd" ]]; then
            HOOKS_BROKEN=$((HOOKS_BROKEN + 1))
        elif [[ ! -x "$hook_cmd" ]]; then
            HOOKS_BROKEN=$((HOOKS_BROKEN + 1))
        fi
    done < <(jq -r '.. | .command? // empty' "$PWD/.claude/settings.json" 2>/dev/null)
else
    # Fall back to global hooks dir (legacy install)
    HOOKS_DIR="$HOME/.claude/hooks"
    if [[ -d "$HOOKS_DIR" ]]; then
        for hook in "$HOOKS_DIR"/*.sh; do
            [[ ! -f "$hook" ]] && continue
            HOOKS_CHECKED=$((HOOKS_CHECKED + 1))
            if [[ -L "$hook" ]]; then
                target=$(readlink "$hook" 2>/dev/null)
                if [[ ! -f "$target" ]]; then
                    HOOKS_BROKEN=$((HOOKS_BROKEN + 1))
                    continue
                fi
            fi
            if [[ ! -x "$hook" ]]; then
                HOOKS_BROKEN=$((HOOKS_BROKEN + 1))
                continue
            fi
        done
    fi
fi

if [[ "$HOOKS_CHECKED" -eq 0 ]]; then
    check_warn "hook-health" "no hooks found" 0 5
elif [[ "$HOOKS_BROKEN" -gt 0 ]]; then
    check_fail "hook-health" "$HOOKS_BROKEN hook(s) broken or not executable" 5
else
    check_pass "hook-health" "$HOOKS_CHECKED hooks healthy" 5
fi

# config-coherence (5 pts): founder.yml required sections present
CONFIG_FILE="$FOUNDER_DIR/config/founder.yml"
if [[ ! -f "$CONFIG_FILE" ]]; then
    check_fail "config-coherence" "founder.yml not found" 6
else
    MISSING_SECTIONS=0
    for section in value scoring integrity experiments self; do
        if ! grep -q "^${section}:" "$CONFIG_FILE" 2>/dev/null; then
            MISSING_SECTIONS=$((MISSING_SECTIONS + 1))
        fi
    done
    # Check all lens configs for required sections
    for _lcf in "$FOUNDER_DIR"/lens/*/config/founder-*.yml; do
        [[ -f "$_lcf" ]] || continue
        if ! grep -q "^taste:" "$_lcf" 2>/dev/null; then
            MISSING_SECTIONS=$((MISSING_SECTIONS + 1))
        fi
    done
    if [[ "$MISSING_SECTIONS" -gt 0 ]]; then
        check_warn "config-coherence" "$MISSING_SECTIONS required section(s) missing from founder.yml" 2 5
    else
        check_pass "config-coherence" "founder.yml has all required sections" 5
    fi
fi

# act-commands-execute (5 pts): founder help/version run
# Note: can't call score.sh or eval.sh here (both can call self.sh → recursion)
ACT_CMDS_OK=0
ACT_CMDS_TOTAL=2

for cmd in help version; do
    if "$FOUNDER_DIR/bin/founder" "$cmd" >/dev/null 2>&1; then
        ACT_CMDS_OK=$((ACT_CMDS_OK + 1))
    fi
done

if [[ "$ACT_CMDS_OK" -eq "$ACT_CMDS_TOTAL" ]]; then
    check_pass "commands-execute" "$ACT_CMDS_OK/$ACT_CMDS_TOTAL commands produce output" 5
elif [[ "$ACT_CMDS_OK" -gt 0 ]]; then
    local_pts=$((ACT_CMDS_OK * 5 / ACT_CMDS_TOTAL))
    check_warn "commands-execute" "$ACT_CMDS_OK/$ACT_CMDS_TOTAL commands produce output" "$local_pts" 5
else
    check_fail "commands-execute" "0/$ACT_CMDS_TOTAL commands produce output" 5
fi

# plan-active (5 pts): plan.yml exists with non-stale tasks
PLAN_CHECK_FILE=""
for _pf in "$PWD/.claude/plans/plan.yml" "$HOME/.claude/plans/plan.yml"; do
    [[ -f "$_pf" ]] && PLAN_CHECK_FILE="$_pf" && break
done
if [[ -z "$PLAN_CHECK_FILE" ]]; then
    check_warn "plan-active" "no plan.yml — run /plan to create one" 0 5
else
    PLAN_TODO=$(grep -c 'status: todo' "$PLAN_CHECK_FILE" 2>/dev/null | tr -d ' \n' || true)
    PLAN_DONE=$(grep -c 'status: done' "$PLAN_CHECK_FILE" 2>/dev/null | tr -d ' \n' || true)
    [[ -z "$PLAN_TODO" || ! "$PLAN_TODO" =~ ^[0-9]+$ ]] && PLAN_TODO=0
    [[ -z "$PLAN_DONE" || ! "$PLAN_DONE" =~ ^[0-9]+$ ]] && PLAN_DONE=0
    PLAN_TOTAL=$((PLAN_TODO + PLAN_DONE))
    # Check plan staleness (>48h old = stale)
    if [[ "$(uname)" == "Darwin" ]]; then
        PLAN_MOD=$(stat -f %m "$PLAN_CHECK_FILE" 2>/dev/null || echo 0)
    else
        PLAN_MOD=$(stat -c %Y "$PLAN_CHECK_FILE" 2>/dev/null || echo 0)
    fi
    PLAN_AGE_H=$(( ($(date +%s) - PLAN_MOD) / 3600 ))
    if [[ "$PLAN_TOTAL" -eq 0 ]]; then
        check_warn "plan-active" "plan.yml exists but has no tasks" 2 5
    elif [[ "$PLAN_AGE_H" -gt 48 ]]; then
        check_warn "plan-active" "plan ${PLAN_AGE_H}h old with ${PLAN_TODO} todo tasks — may be stale" 2 5
    elif [[ "$PLAN_TODO" -gt 0 ]]; then
        check_pass "plan-active" "${PLAN_TODO} todo / ${PLAN_DONE} done tasks, updated ${PLAN_AGE_H}h ago" 5
    else
        check_pass "plan-active" "all ${PLAN_DONE} tasks done — plan complete" 5
    fi
fi
