# grade-signals.sh — Signal-based grading from external data sources
#
# Functions: grade_customer_signal, grade_strategy_signal, grade_eval_feature,
#            grade_via_signals, _is_feature_name
#
# Requires: CUSTOMER_INTEL_FILE, STRATEGY_FILE, EVAL_CACHE_FILE (set by parent grade.sh)

# Check customer-intel.json for signals supporting/contradicting a prediction about users/customers/demand
grade_customer_signal() {
    local prediction="$1"
    [[ ! -f "$CUSTOMER_INTEL_FILE" ]] && { echo "SKIP"; return; }
    command -v jq &>/dev/null || { echo "SKIP"; return; }

    # Extract key terms from prediction for matching against customer themes
    local pred_lower
    pred_lower=$(echo "$prediction" | tr '[:upper:]' '[:lower:]')

    # Look for matching themes in customer-intel.json
    # themes[].theme, themes[].signal_strength, themes[].quotes[]
    local matching_themes=""
    local strong_match=false
    local theme_count=0

    while IFS= read -r theme_line; do
        [[ -z "$theme_line" ]] && continue
        local theme_lower
        theme_lower=$(echo "$theme_line" | tr '[:upper:]' '[:lower:]')

        # Extract key nouns from prediction and check if theme references them
        local match=false
        for keyword in agency agencies user users customer customers demand market pain friction switch switching adopt adoption churn retention onboard pricing price pay paying revenue; do
            if [[ "$pred_lower" == *"$keyword"* && "$theme_lower" == *"$keyword"* ]]; then
                match=true
                break
            fi
        done
        # Also match if prediction and theme share a 7+ char word (domain-specific)
        # Excludes common words that would cause false matches
        if [[ "$match" == false ]]; then
            for word in $(echo "$pred_lower" | tr -cs '[:alpha:]' '\n' | sort -u); do
                [[ ${#word} -lt 7 ]] && continue
                # Skip common English words that aren't domain-specific
                case "$word" in
                    because|between|through|without|another|already|however|something|anything|nothing|everything|everyone|someone|working|building|getting|running|looking|thinking|changes|current|different|actually|probably|should) continue ;;
                esac
                if [[ "$theme_lower" == *"$word"* ]]; then
                    match=true
                    break
                fi
            done
        fi

        if [[ "$match" == true ]]; then
            theme_count=$((theme_count + 1))
            matching_themes="${matching_themes}${theme_line}; "
            # Check signal strength
            local strength
            strength=$(jq -r ".themes[] | select(.theme == \"$theme_line\") | .signal_strength // \"unknown\"" "$CUSTOMER_INTEL_FILE" 2>/dev/null)
            [[ "$strength" == "strong" ]] && strong_match=true
        fi
    done < <(jq -r '.themes[].theme // empty' "$CUSTOMER_INTEL_FILE" 2>/dev/null)

    if [[ "$theme_count" -gt 0 ]]; then
        matching_themes="${matching_themes%;*}"
        if [[ "$strong_match" == true ]]; then
            echo "YES|Confirmed by customer signal (${theme_count} theme(s), strong): ${matching_themes:0:120}"
        elif [[ "$theme_count" -ge 2 ]]; then
            echo "PARTIAL|Supported by customer signal (${theme_count} themes, moderate): ${matching_themes:0:120}"
        else
            echo "PARTIAL|Weak customer signal (1 theme): ${matching_themes:0:120}"
        fi
    else
        echo "SKIP"
    fi
}

# Check strategy.yml for signals about market/competitor/positioning predictions
grade_strategy_signal() {
    local prediction="$1"
    [[ ! -f "$STRATEGY_FILE" ]] && { echo "SKIP"; return; }

    local pred_lower
    pred_lower=$(echo "$prediction" | tr '[:upper:]' '[:lower:]')

    # Extract strategy state
    local stage bottleneck_name bottleneck_desc
    stage=$(grep '^  stage:' "$STRATEGY_FILE" | head -1 | sed 's/.*: *//' | tr -d '"' || true)
    bottleneck_name=$(grep '^  name:' "$STRATEGY_FILE" | head -1 | sed 's/.*: *//' | tr -d '"' || true)
    bottleneck_desc=$(grep '^  description:' "$STRATEGY_FILE" | head -1 | sed 's/.*: *//' | tr -d '"' || true)

    # Check if prediction aligns with or contradicts strategy
    local evidence=""
    local verdict="SKIP"

    # Check if prediction mentions the bottleneck
    local bn_lower
    bn_lower=$(echo "$bottleneck_name $bottleneck_desc" | tr '[:upper:]' '[:lower:]')
    for word in $(echo "$bn_lower" | tr -cs '[:alpha:]' '\n' | sort -u); do
        [[ ${#word} -lt 5 ]] && continue
        if [[ "$pred_lower" == *"$word"* ]]; then
            evidence="Prediction aligns with current bottleneck: ${bottleneck_name}"
            verdict="YES"
            break
        fi
    done

    # Check if prediction mentions stage-related concepts
    if [[ "$verdict" == "SKIP" ]]; then
        case "$stage" in
            one)
                if [[ "$pred_lower" == *"first user"* || "$pred_lower" == *"first loop"* || "$pred_lower" == *"external"* || "$pred_lower" == *"onboard"* ]]; then
                    evidence="Aligned with stage one focus (first user/loop). Stage: ${stage}"
                    verdict="YES"
                fi
                if [[ "$pred_lower" == *"growth"* || "$pred_lower" == *"scale"* || "$pred_lower" == *"distribution"* ]]; then
                    evidence="Contradicts stage one — prediction about growth/scale at stage ${stage}"
                    verdict="NO"
                fi
                ;;
            some)
                if [[ "$pred_lower" == *"retention"* || "$pred_lower" == *"come back"* || "$pred_lower" == *"return"* ]]; then
                    evidence="Aligned with stage some focus (retention). Stage: ${stage}"
                    verdict="YES"
                fi
                ;;
            many)
                if [[ "$pred_lower" == *"distribution"* || "$pred_lower" == *"discover"* ]]; then
                    evidence="Aligned with stage many focus (distribution). Stage: ${stage}"
                    verdict="YES"
                fi
                ;;
        esac
    fi

    # Check unknowns — if prediction matches a resolved unknown, grade it
    if [[ "$verdict" == "SKIP" ]]; then
        local resolved_results
        resolved_results=$(awk '/priority: resolved/{found=1} found && /result:/{print; found=0}' "$STRATEGY_FILE" 2>/dev/null)
        if [[ -n "$resolved_results" ]]; then
            local result_lower
            result_lower=$(echo "$resolved_results" | tr '[:upper:]' '[:lower:]')
            for word in $(echo "$pred_lower" | tr -cs '[:alpha:]' '\n' | sort -u); do
                [[ ${#word} -lt 5 ]] && continue
                if [[ "$result_lower" == *"$word"* ]]; then
                    evidence="Matches resolved strategy unknown: ${resolved_results:0:100}"
                    verdict="PARTIAL"
                    break
                fi
            done
        fi
    fi

    if [[ "$verdict" != "SKIP" ]]; then
        echo "${verdict}|Strategy signal: ${evidence:0:150}"
    else
        echo "SKIP"
    fi
}

# Check eval-cache for feature score changes when prediction names a feature
grade_eval_feature() {
    local prediction="$1" pred_date="$2"
    [[ ! -f "$EVAL_CACHE_FILE" ]] && { echo "SKIP"; return; }
    command -v jq &>/dev/null || { echo "SKIP"; return; }

    local pred_lower
    pred_lower=$(echo "$prediction" | tr '[:upper:]' '[:lower:]')

    # Get feature names from eval-cache
    local features
    features=$(jq -r 'keys[]' "$EVAL_CACHE_FILE" 2>/dev/null)
    [[ -z "$features" ]] && { echo "SKIP"; return; }

    # Check if prediction mentions any eval-cache feature by name
    local matched_feature="" matched_score=""
    while IFS= read -r feat; do
        [[ -z "$feat" ]] && continue
        local feat_lower
        feat_lower=$(echo "$feat" | tr '[:upper:]' '[:lower:]')
        # Match feature name in prediction (word boundary approximation)
        if [[ "$pred_lower" == *"$feat_lower"* ]]; then
            matched_feature="$feat"
            matched_score=$(jq -r ".\"$feat\".score // empty" "$EVAL_CACHE_FILE" 2>/dev/null)
            break
        fi
    done <<< "$features"

    [[ -z "$matched_feature" || -z "$matched_score" ]] && { echo "SKIP"; return; }

    # Determine if prediction claims improvement, decline, or a target
    local claim_dir=""
    if [[ "$pred_lower" =~ (improve|increase|raise|better|higher|grow|rise|push) ]]; then
        claim_dir="up"
    elif [[ "$pred_lower" =~ (decrease|drop|lower|decline|worse|fall|regress) ]]; then
        claim_dir="down"
    elif [[ "$pred_lower" =~ (stay|stable|hold|keep|maintain|unchanged) ]]; then
        claim_dir="stable"
    fi

    # Get delivery sub-score if available (since task focuses on delivery)
    local delivery_score
    delivery_score=$(jq -r ".\"$matched_feature\".delivery_score // empty" "$EVAL_CACHE_FILE" 2>/dev/null)

    local detail="Feature ${matched_feature} eval: score=${matched_score}"
    [[ -n "$delivery_score" ]] && detail="${detail}, delivery=${delivery_score}"

    # Check delta field if available
    local delta_field
    delta_field=$(jq -r ".\"$matched_feature\".delta // empty" "$EVAL_CACHE_FILE" 2>/dev/null)
    [[ -n "$delta_field" ]] && detail="${detail}, trend=${delta_field}"

    case "$claim_dir" in
        up)
            if [[ "$delta_field" == "better" ]]; then
                echo "YES|Eval confirms improvement: ${detail}"
            elif [[ -n "$matched_score" && "$matched_score" =~ ^[0-9]+$ && "$matched_score" -ge 70 ]]; then
                echo "PARTIAL|Feature healthy but delta unclear: ${detail}"
            else
                echo "NO|No improvement signal: ${detail}"
            fi
            ;;
        down)
            if [[ "$delta_field" == "worse" ]]; then
                echo "YES|Eval confirms decline: ${detail}"
            else
                echo "NO|No decline signal: ${detail}"
            fi
            ;;
        stable)
            if [[ "$delta_field" == "same" || -z "$delta_field" ]]; then
                echo "YES|Eval confirms stable: ${detail}"
            elif [[ "$delta_field" == "better" ]]; then
                echo "PARTIAL|Actually improved (predicted stable): ${detail}"
            else
                echo "NO|Changed (predicted stable): ${detail}"
            fi
            ;;
        *)
            # No directional claim but we found the feature — report current state
            if [[ -n "$matched_score" && "$matched_score" =~ ^[0-9]+$ && "$matched_score" -ge 70 ]]; then
                echo "PARTIAL|Feature referenced, currently healthy: ${detail}"
            else
                echo "SKIP"
            fi
            ;;
    esac
}

# Dispatch signal-based grading for predictions that parse_claim couldn't handle
grade_via_signals() {
    local prediction="$1" pred_date="$2"
    local pred_lower
    pred_lower=$(echo "$prediction" | tr '[:upper:]' '[:lower:]')

    # Try customer-intel for user/customer/demand predictions
    if [[ "$pred_lower" =~ (user|customer|demand|adoption|churn|retention|onboard|pain|friction|switch|market[[:space:]]+fit|persona|segment) ]]; then
        local result
        result=$(grade_customer_signal "$prediction")
        if [[ "${result%%|*}" != "SKIP" ]]; then
            echo "customer_signal|$result"
            return
        fi
    fi

    # Try strategy for market/competitor/positioning predictions
    if [[ "$pred_lower" =~ (market|competitor|positioning|stage|bottleneck|strategy|distribution|growth|retention|first[[:space:]]+loop|niche|moat) ]]; then
        local result
        result=$(grade_strategy_signal "$prediction")
        if [[ "${result%%|*}" != "SKIP" ]]; then
            echo "strategy_signal|$result"
            return
        fi
    fi

    # Try eval-cache for predictions mentioning feature names
    local result
    result=$(grade_eval_feature "$prediction" "$pred_date")
    if [[ "${result%%|*}" != "SKIP" ]]; then
        echo "eval_feature|$result"
        return
    fi

    echo "SKIP|SKIP"
}

# Helper: check if a word is a valid feature name (not a function word)
_is_feature_name() {
    local word="$1"
    case "$word" in
        will|the|this|that|its|and|but|for|not|has|was|are|can|may|our|all|any|how|who|with|from|into|also|very|just|only|then|than|when|what|which|each|some|most|such|much)
            return 1 ;;
        *)
            return 0 ;;
    esac
}
