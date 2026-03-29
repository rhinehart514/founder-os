# Stranger Test Protocol

First-time install and usage test for someone who has never seen founder-os.

## Prerequisites

- macOS or Linux
- [jq](https://jqlang.github.io/jq/) installed
- [Claude Code](https://claude.ai/code) CLI installed and authenticated
- Screen recording enabled (QuickTime or similar)

## Steps

### 1. Install (~2 min)

```bash
git clone https://github.com/glittercowboy/founder-os.git
cd founder-os
bash install.sh
```

**Observe:** Does it complete without errors? Are all checks green?

### 2. Onboard (~3 min)

```bash
cd your-test-project  # or any project directory
claude
# type: /onboard
```

**Observe:** Does it produce a `config/founder.yml`? Does it detect features? How long does it take?

### 3. Validate demand (~5 min)

```
/demand new "describe your test idea here"
```

**Observe:** Does it run the kill check? Does it WebSearch? Does it produce a portfolio entry in `config/portfolio.yml`? Is the output actionable or generic?

### 4. Measure (~3 min)

```
/measure
```

**Observe:** Does it produce a score? Are tier breakdowns shown? Does the "next step" recommendation make sense?

### 5. Dashboard (~1 min)

```
/founder
```

**Observe:** Does it show portfolio state? Is the demand status rendered? Is there one clear next action?

## Known Limitations

- Visual/taste scoring is disabled (routes require auth — dead end, not a bug)
- World-awareness is planned, not active
- No web frontend — this is a CLI-native tool

## What to Record

For each step:
1. Time to complete
2. Any errors or confusing output
3. Did you know what to do next without being told?
4. One word for how the experience felt

## After the Test

Share the screen recording and notes. Key questions:
- Where did you get stuck?
- What did you expect to happen that didn't?
- Would you use this again? Why or why not?
