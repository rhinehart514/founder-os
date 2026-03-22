# Configuration Gotchas

Built from real failure modes. Update this when /configure leads to bad outcomes.

## Cost tier mistakes
- **Economy to save money when quality matters**: If eval scores are low and the builder is producing weak code, economy makes it worse. Economy is for exploration and low-stakes work — not for building core features.
- **Premium for everything**: Premium doesn't mean better. Haiku is genuinely better for measurement (cheaper, faster, sufficient). Premium wastes tokens on tasks that don't benefit from opus-level reasoning.

## Autonomy mistakes
- **Full-auto to skip the hard gate friction**: The hard gate exists because "obvious" moves have the highest skip-regret rate. If you're annoyed by the gate, that's a signal the moves aren't well-defined — fix the plan, not the gate.
- **Supervised when the plan is solid**: If /plan produced a clear, confident plan with specific moves, supervised adds friction without safety. Match autonomy to plan confidence.

## Config-as-fix antipattern
- **Changing config to fix scores**: Scores are low because the product needs work, not because configuration is wrong. /configure changes HOW the system operates, not WHAT it produces. If scores are low, run /plan, not /configure.
- **Preferences override escalation**: If you're overriding 4+ of 5 settings, the defaults are wrong — that's a signal to update the defaults in the code, not pile on preferences.

## File handling mistakes
- **Overwriting preferences.yml**: Always merge with existing content. The user may have set agents.cost in a previous session and is now only changing output.verbosity. Read-modify-write, don't truncate.
- **Editing founder.yml from /configure**: founder.yml is the project source of truth. /configure writes ONLY to preferences.yml. If a founder.yml change is needed, tell the user — don't do it.
