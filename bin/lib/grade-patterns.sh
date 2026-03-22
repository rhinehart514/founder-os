# grade-patterns.sh — Claim pattern matching for prediction grading
#
# Functions: parse_claim
#
# Depends on: grade-signals.sh (_is_feature_name)

# Extract claim components from prediction text.
# Returns: direction feature from_val to_val
# direction: raise|drop|improve|stable
parse_claim() {
    local text="$1"
    local direction="" feature="" from_val="" to_val=""

    # Pre-processing: strip "because Y" clause to prevent greedy interference.
    # Save the full text for causal fallback, but match patterns against the claim part only.
    local claim_text="$text"
    if [[ "$text" =~ ^(.+)[[:space:]]+because[[:space:]] ]]; then
        claim_text="${BASH_REMATCH[1]}"
    fi

    # --- TIER 1: Numeric patterns (most specific — "X from N to M") ---

    # Pattern: "X eval/feature from N to M" or "X eval/feature to N" (eval-cache lookup — BEFORE generic "from N to M")
    if [[ "$claim_text" =~ ([a-zA-Z_.-]+)[[:space:]]+(eval|feature)[[:space:]]+(from[[:space:]]+[0-9]+[[:space:]]+)?to[[:space:]]+([0-9]+) ]]; then
        direction="eval_target"
        feature="${BASH_REMATCH[1]}"
        to_val="${BASH_REMATCH[4]}"
    elif [[ "$claim_text" =~ ([a-zA-Z_.-]+)[[:space:]]+(will[[:space:]]+)?score[[:space:]]+([0-9]+) ]]; then
        direction="eval_target"
        feature="${BASH_REMATCH[1]}"
        to_val="${BASH_REMATCH[3]}"
    # Pattern: "raise X from N to M+"
    elif [[ "$claim_text" =~ raise[[:space:]]+([a-zA-Z_-]+)[[:space:]]+from[[:space:]]+([0-9]+)[[:space:]]+to[[:space:]]+([0-9]+) ]]; then
        direction="raise"
        feature="${BASH_REMATCH[1]}"
        from_val="${BASH_REMATCH[2]}"
        to_val="${BASH_REMATCH[3]}"
    # Pattern: "will raise X from N to M+"
    elif [[ "$claim_text" =~ will[[:space:]]+raise[[:space:]]+([a-zA-Z_-]+)[[:space:]]+from[[:space:]]+([0-9]+)[[:space:]]+to[[:space:]]+([0-9]+) ]]; then
        direction="raise"
        feature="${BASH_REMATCH[1]}"
        from_val="${BASH_REMATCH[2]}"
        to_val="${BASH_REMATCH[3]}"
    # Pattern: "X from N to M+"
    elif [[ "$claim_text" =~ ([a-zA-Z_-]+)[[:space:]]+from[[:space:]]+([0-9]+)[[:space:]]+to[[:space:]]+([0-9]+) ]]; then
        direction="raise"
        feature="${BASH_REMATCH[1]}"
        from_val="${BASH_REMATCH[2]}"
        to_val="${BASH_REMATCH[3]}"
    # Pattern: "X will reach/exceed/hit N" (numeric target)
    elif [[ "$claim_text" =~ ([a-zA-Z_.-]+)[[:space:]]+(will[[:space:]]+)?(reach|exceed|hit)[[:space:]]+([0-9]+) ]]; then
        direction="numeric_target"
        feature="${BASH_REMATCH[1]}"
        to_val="${BASH_REMATCH[4]}"
    elif [[ "$claim_text" =~ (reach|exceed|hit|get[[:space:]]+to)[[:space:]]+([0-9]+) ]]; then
        direction="numeric_target"
        to_val="${BASH_REMATCH[2]}"
        if [[ "$claim_text" =~ ([a-zA-Z_.-]+)[[:space:]]+(will[[:space:]]+)?(reach|exceed|hit|get[[:space:]]+to) ]]; then
            feature="${BASH_REMATCH[1]}"
        fi
    # Pattern: "N assertions will pass"
    elif [[ "$claim_text" =~ ([0-9]+)[[:space:]]+assertions?[[:space:]]+will[[:space:]]+pass ]]; then
        direction="assertion_count"
        to_val="${BASH_REMATCH[1]}"
    # Pattern: "score N" / "to score N" (overall score target)
    elif [[ "$claim_text" =~ (score|scoring)[[:space:]]+(stays?[[:space:]]+at[[:space:]]+|at[[:space:]]+|to[[:space:]]+)?([0-9]+) ]]; then
        direction="score_target"
        feature="score"
        to_val="${BASH_REMATCH[3]}"

    # --- TIER 2: Verb patterns with named subjects ("X will work/fail") ---

    # Pattern: "X will work" / "X will succeed"
    elif [[ "$claim_text" =~ ([a-zA-Z_.-]+)[[:space:]]+will[[:space:]]+(work|succeed|pass) ]]; then
        direction="will_work"
        feature="${BASH_REMATCH[1]}"
    # Pattern: "X will fail" / "X will break"
    elif [[ "$claim_text" =~ ([a-zA-Z_.-]+)[[:space:]]+will[[:space:]]+(fail|break|crash) ]]; then
        direction="will_fail"
        feature="${BASH_REMATCH[1]}"

    # --- TIER 3: Filesystem patterns ---

    # Pattern: "feature X exists" / "file X exists"
    elif [[ "$claim_text" =~ (feature|file)[[:space:]]+([a-zA-Z_./-]+)[[:space:]]+exists ]]; then
        direction="exists"
        feature="${BASH_REMATCH[2]}"
    # Pattern: "file X contains Y" / "X contains Y"
    elif [[ "$claim_text" =~ ([a-zA-Z_./-]+)[[:space:]]+contains ]]; then
        direction="contains"
        feature="${BASH_REMATCH[1]}"

    fi

    # --- TIER 4: Directional patterns (post-chain, since feature name validation can fail) ---
    if [[ -z "$direction" ]]; then
        # Try "X will improve/increase" with valid feature name
        if [[ "$claim_text" =~ ([a-zA-Z_.-][a-zA-Z_.-][a-zA-Z_.-]+)[[:space:]]+will[[:space:]]+(improve|increase|raise|grow|rise) ]]; then
            local _feat="${BASH_REMATCH[1]}"
            if _is_feature_name "$_feat"; then
                direction="directional_up"
                feature="$_feat"
            fi
        fi
        # Try "X improve/increase" (no "will")
        if [[ -z "$direction" && "$claim_text" =~ ([a-zA-Z_.-][a-zA-Z_.-][a-zA-Z_.-]+)[[:space:]]+(improve|increase|raise|grow|rise) ]]; then
            local _feat2="${BASH_REMATCH[1]}"
            if _is_feature_name "$_feat2"; then
                direction="directional_up"
                feature="$_feat2"
            fi
        fi
        # Try "X will decrease/drop"
        if [[ -z "$direction" && "$claim_text" =~ ([a-zA-Z_.-][a-zA-Z_.-][a-zA-Z_.-]+)[[:space:]]+will[[:space:]]+(decrease|drop|lower|decline|shrink|fall) ]]; then
            local _feat3="${BASH_REMATCH[1]}"
            if _is_feature_name "$_feat3"; then
                direction="directional_down"
                feature="$_feat3"
            fi
        fi
        # Try "X decrease/drop" (no "will")
        if [[ -z "$direction" && "$claim_text" =~ ([a-zA-Z_.-][a-zA-Z_.-][a-zA-Z_.-]+)[[:space:]]+(decrease|drop|lower|decline|shrink|fall) ]]; then
            local _feat4="${BASH_REMATCH[1]}"
            if _is_feature_name "$_feat4"; then
                direction="directional_down"
                feature="$_feat4"
            fi
        fi
        # No-subject fallback: "will drop" / "will decrease"
        if [[ -z "$direction" && "$claim_text" =~ will[[:space:]]+(drop|decrease|lower) ]]; then
            direction="drop"
        fi
        # No-subject fallback: "will improve" / "will increase"
        if [[ -z "$direction" && "$claim_text" =~ will[[:space:]]+(improve|increase) ]]; then
            direction="raise"
        fi

    # --- TIER 4.5: Qualitative patterns (adjective/verb/noun claims) ---

        # "will be [adjective]" — qualitative comparison claim
        # better, faster, simpler, cleaner, easier, more reliable, more accurate, higher, lower
        if [[ -z "$direction" && "$claim_text" =~ will[[:space:]]+be[[:space:]]+(better|faster|simpler|cleaner|easier|smoother|stronger|more[[:space:]]+reliable|more[[:space:]]+accurate|more[[:space:]]+stable|more[[:space:]]+honest|higher|lower) ]]; then
            local _adj="${BASH_REMATCH[1]}"
            # Try to extract subject before "will be"
            if [[ "$claim_text" =~ ([a-zA-Z_.-]{3,})[[:space:]]+will[[:space:]]+be[[:space:]]+ ]]; then
                feature="${BASH_REMATCH[1]}"
                _is_feature_name "$feature" || feature=""
            fi
            case "$_adj" in
                lower) direction="qualitative_down" ;;
                *)     direction="qualitative_up" ;;
            esac
        fi

        # "should [verb]" — expectation claim checked via assertions
        if [[ -z "$direction" && "$claim_text" =~ should[[:space:]]+(work|pass|succeed|improve|hold|transfer|apply|scale|run|compile|build) ]]; then
            direction="should_verb"
            local _verb="${BASH_REMATCH[1]}"
            # Try to extract subject before "should"
            if [[ "$claim_text" =~ ([a-zA-Z_.-]{3,})[[:space:]]+should ]]; then
                feature="${BASH_REMATCH[1]}"
                _is_feature_name "$feature" || feature=""
            fi
        fi

        # "expect [noun]" — expectation claim checked via score delta
        if [[ -z "$direction" && "$claim_text" =~ expect[[:space:]]+(improvement|regression|increase|decrease|drop|gain|decline|progress|growth|stability) ]]; then
            local _noun="${BASH_REMATCH[1]}"
            case "$_noun" in
                regression|decrease|drop|decline) direction="expect_down" ;;
                stability) direction="expect_stable" ;;
                *) direction="expect_up" ;;
            esac
            # Try to extract subject before "expect"
            if [[ "$claim_text" =~ ([a-zA-Z_.-]{3,})[[:space:]]+expect ]]; then
                feature="${BASH_REMATCH[1]}"
                _is_feature_name "$feature" || feature=""
            fi
        fi
        # Also handle "I expect" / "we expect" form
        if [[ -z "$direction" && "$claim_text" =~ (I|we)[[:space:]]+expect[[:space:]]+(improvement|regression|increase|decrease|drop|gain|decline|progress|growth|stability) ]]; then
            local _noun2="${BASH_REMATCH[2]}"
            case "$_noun2" in
                regression|decrease|drop|decline) direction="expect_down" ;;
                stability) direction="expect_stable" ;;
                *) direction="expect_up" ;;
            esac
        fi
    fi

    # --- TIER 5: Broad patterns (lowest priority) ---
    if [[ -z "$direction" ]]; then
        if [[ "$claim_text" =~ ([0-9]+)[[:space:]]+(sessions?|days?|weeks?|months?) ]]; then
            direction="time_based"
            to_val="${BASH_REMATCH[1]}"
            feature="${BASH_REMATCH[2]}"
        # Pattern: "X depends on Y" / "feature X depends on Y" / "X requires Y"
        elif [[ "$claim_text" =~ ([a-zA-Z_.-]+)[[:space:]]+(depends[[:space:]]+on|requires)[[:space:]]+([a-zA-Z_.-]+) ]]; then
            direction="dependency"
            feature="${BASH_REMATCH[1]}"
            to_val="${BASH_REMATCH[3]}"  # the dependency (Y)
        # Pattern: "users will [verb]" / "founders will [verb]" / "people will [verb]"
        elif [[ "$claim_text" =~ (users?|founders?|people|devs?|developers?|customers?)[[:space:]]+(will[[:space:]]+)?(adopt|install|use|try|ignore|skip|love|hate|churn|return|click|bounce|convert|upgrade|downgrade|complain|recommend|share|discover|find|prefer|avoid|switch|choose|leave|stay|sign[[:space:]]*up|drop[[:space:]]*off|pay|buy|subscribe) ]]; then
            direction="user_behavior"
            feature="${BASH_REMATCH[1]}"
            to_val="${BASH_REMATCH[3]}"
        elif [[ "$claim_text" =~ ([a-zA-Z_.-][a-zA-Z_.-][a-zA-Z_.-]+)[[:space:]]+(will[[:space:]]+)?(produce|generate|create|enable|reduce|eliminate) ]]; then
            direction="will_work"
            feature="${BASH_REMATCH[1]}"
        elif [[ "$claim_text" =~ will[[:space:]]+be[[:space:]]+the[[:space:]]+(highest|best|hardest|most|lowest|worst|easiest) ]]; then
            direction="superlative"
        # Causal fallback: if we stripped "because" earlier and nothing matched
        elif [[ "$claim_text" != "$text" ]]; then
            if [[ "$claim_text" =~ (will[[:space:]]+)?(work|succeed|pass|ship|land|hold|transfer|get) ]]; then
                direction="causal_bool"
                feature="causal"
            fi
        fi
    fi

    echo "$direction|$feature|$from_val|$to_val"
}
