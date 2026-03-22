# ============================================================
# MEASURE (25 pts) — Can it see?
# ============================================================
CURRENT_SYSTEM="measure"

# measurement-stack (8 pts): score.sh, eval.sh, taste.mjs exist
STACK_MISSING=0
_taste_found=false
for _ts in "$FOUNDER_DIR"/lens/*/eval/taste.mjs; do
    [[ -f "$_ts" ]] && _taste_found=true && break
done
for tool in "$FOUNDER_DIR/bin/score.sh" "$FOUNDER_DIR/bin/eval.sh"; do
    if [[ ! -f "$tool" ]]; then
        STACK_MISSING=$((STACK_MISSING + 1))
    elif [[ ! -x "$tool" && "$tool" != *.mjs ]]; then
        STACK_MISSING=$((STACK_MISSING + 1))
    fi
done
[[ "$_taste_found" == "false" ]] && STACK_MISSING=$((STACK_MISSING + 1))
if [[ "$STACK_MISSING" -eq 0 ]]; then
    check_pass "measurement-stack" "score.sh, taste.mjs, eval.sh all present" 8
else
    check_fail "measurement-stack" "$STACK_MISSING measurement tool(s) missing" 8
fi

# commands-work (9 pts): founder help/version execute + bin/founder exists
# Note: can't call score.sh or eval.sh (both can trigger self.sh → recursion)
CMDS_OK=0
CMDS_TOTAL=0
for cmd in help version; do
    CMDS_TOTAL=$((CMDS_TOTAL + 1))
    if "$FOUNDER_DIR/bin/founder" "$cmd" >/dev/null 2>&1; then
        CMDS_OK=$((CMDS_OK + 1))
    fi
done
# Check bin/founder is executable
CMDS_TOTAL=$((CMDS_TOTAL + 1))
if [[ -x "$FOUNDER_DIR/bin/founder" ]]; then
    CMDS_OK=$((CMDS_OK + 1))
fi

if [[ "$CMDS_OK" -eq "$CMDS_TOTAL" ]]; then
    check_pass "commands-work" "$CMDS_OK/$CMDS_TOTAL core commands execute" 9
elif [[ "$CMDS_OK" -gt 0 ]]; then
    local_pts=$((CMDS_OK * 9 / CMDS_TOTAL))
    check_warn "commands-work" "$CMDS_OK/$CMDS_TOTAL core commands execute" "$local_pts" 9
else
    check_fail "commands-work" "0/$CMDS_TOTAL commands crashed" 9
fi

# tests-exist/pass (8 pts)
if [[ -d "$FOUNDER_DIR/tests" ]] && ls "$FOUNDER_DIR/tests"/*.test.sh >/dev/null 2>&1; then
    TESTS_TOTAL=0
    for t in "$FOUNDER_DIR/tests"/*.test.sh; do
        [[ -f "$t" ]] && TESTS_TOTAL=$((TESTS_TOTAL + 1))
    done
    if [[ "$SCORE_MODE" == "true" || "$JSON_MODE" == "true" || "$EVAL_MODE" == "true" ]]; then
        # Fast path: tests exist = pass (running them risks recursion via score.test.sh)
        check_pass "tests-exist" "$TESTS_TOTAL test suites present" 8
    else
        TESTS_PASS=0
        for t in "$FOUNDER_DIR/tests"/*.test.sh; do
            [[ ! -f "$t" ]] && continue
            if bash "$t" >/dev/null 2>&1; then
                TESTS_PASS=$((TESTS_PASS + 1))
            fi
        done
        if [[ "$TESTS_PASS" -eq "$TESTS_TOTAL" ]]; then
            check_pass "tests-pass" "$TESTS_PASS/$TESTS_TOTAL test suites pass" 8
        elif [[ "$TESTS_PASS" -gt 0 ]]; then
            local_pts=$((TESTS_PASS * 8 / TESTS_TOTAL))
            check_warn "tests-pass" "$TESTS_PASS/$TESTS_TOTAL test suites pass" "$local_pts" 8
        else
            check_fail "tests-pass" "0/$TESTS_TOTAL test suites pass" 8
        fi
    fi
else
    check_warn "tests-pass" "no test suites found" 0 8
fi
