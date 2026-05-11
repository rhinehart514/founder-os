# Distribution status

Updated: 2026-05-11

Contact email used for submission-ready materials: rhinehart514@gmail.com

## Completed

- GitHub repository metadata aligned:
  - Description: `Multi-agent primitives for Claude Code: consensus, debate, fanout research, skill building, and measured optimization.`
  - Topics: `agentic-coding`, `ai-agents`, `claude-code`, `claude-code-plugin`, `claude-code-skills`, `developer-tools`, `llm-tools`, `multi-agent`
- npm published:
  - `@rhinehart514/founder-os@8.2.0`
  - `@rhinehart514/founder-os@8.2.1`
- GitHub releases created:
  - https://github.com/rhinehart514/founder-os/releases/tag/v8.2.0
  - https://github.com/rhinehart514/founder-os/releases/tag/v8.2.1
- Claude plugin validation passed:
  - `claude plugin validate .`
- Claude marketplace manifest added:
  - `.claude-plugin/marketplace.json`
- Root `SKILL.md` added for skill-directory indexing.
- README install surface updated:
  - Direct plugin install
  - Marketplace install
  - npm install
- Awesome Skills submitted and indexed:
  - https://www.awesomeskills.dev/en/skill/rhinehart514-founder-os
- Tons of Skills nomination submitted:
  - Endpoint returned `{"status":"ok"}`
- Non-LinkedIn launch copy prepared:
  - `docs/distribution.md`

## Blocked Or Manual

- Anthropic official plugin submission:
  - URL: https://platform.claude.com/plugins/submit
  - Blocker: requires authenticated Console login. Direct unauthenticated request redirects to `/login?returnTo=%2Fplugins%2Fsubmit`.
  - Repo is ready for submission: public GitHub repo, marketplace manifest, and `claude plugin validate .` passes.
- Claude Marketplace:
  - URL: https://claude-marketplace.com/submit
  - Blocker: direct POST returns `405`, and the client bundle only displays a local success state without calling a backend.
  - Treat as manual/contact-required unless the site adds a real submission endpoint.
- Reddit, Hacker News, and X:
  - Blocker: no authenticated posting account available in this environment.
  - Ready-to-post copy is in `docs/distribution.md`.
