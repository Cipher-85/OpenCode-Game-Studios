<p align="center">
  <h1 align="center">OpenCode Game Studios</h1>
  <p align="center">
    Turn a single OpenCode session into a full game development studio.
    <br />
    49 agents. 73 skills. One coordinated AI team.
  </p>
</p>

<p align="center">
  <a href="LICENSE"><img src="https://img.shields.io/badge/license-MIT-blue.svg" alt="MIT License"></a>
  <a href=".opencode/agents"><img src="https://img.shields.io/badge/agents-49-blueviolet" alt="49 Agents"></a>
  <a href=".opencode/skills"><img src="https://img.shields.io/badge/skills-73-green" alt="73 Skills"></a>
  <a href=".opencode/commands"><img src="https://img.shields.io/badge/commands-73-yellow" alt="73 Commands"></a>
  <a href=".opencode/hooks"><img src="https://img.shields.io/badge/hooks-12-orange" alt="12 Hooks"></a>
  <a href="https://opencode.ai"><img src="https://img.shields.io/badge/built%20for-OpenCode-f5f5f5" alt="Built for OpenCode"></a>
</p>

---

> **A faithful port of [Claude Code Game Studios](https://github.com/Donchitos/Claude-Code-Game-Studios) (commit `984023d`) to a native OpenCode project.**
> See [PORTING_NOTES.md](PORTING_NOTES.md) for the full porting log, decisions, and known gaps.

## Why This Exists

Building a game solo with AI is powerful — but a single chat session has no structure. No one stops you from hardcoding magic numbers, skipping design docs, or writing spaghetti code. There's no QA pass, no design review, no one asking "does this actually fit the game's vision?"

**OpenCode Game Studios** solves this by giving your AI session the structure of a real studio. Instead of one general-purpose assistant, you get 49 specialized agents organized into a studio hierarchy — directors who guard the vision, department leads who own their domains, and specialists who do the hands-on work. Each agent has defined responsibilities, escalation paths, and quality gates.

The result: you still make every decision, but now you have a team that asks the right questions, catches mistakes early, and keeps your project organized from first brainstorm to launch.

---

## What's Included

| Category | Count | Description |
|----------|-------|-------------|
| **Agents** | 49 | Specialized subagents across design, programming, art, audio, narrative, QA, and production |
| **Skills** | 73 | On-demand behaviors loaded via the `skill` tool for every workflow phase |
| **Commands** | 73 | Slash commands (`/start`, `/design-system`, `/dev-story`, `/story-done`, etc.) that wrap the skills |
| **Hooks** | 12 | Automated validation via a plugin adapter (`ccgs-hooks.js`) — commits, pushes, assets, session lifecycle, agent audit trail, gap detection |
| **Rules** | 11 | Path-scoped coding standards enforced via nested `AGENTS.md` when editing gameplay, engine, AI, UI, network code, and more |
| **Templates** | 41 | Document templates for GDDs, UX specs, ADRs, sprint plans, HUD design, accessibility, and more |

## Studio Hierarchy

Agents are organized into three tiers, matching how real studios operate:

```
Tier 1 — Directors (originally Opus-tier)
  creative-director    technical-director    producer

Tier 2 — Department Leads (originally Sonnet-tier)
  game-designer        lead-programmer       art-director
  audio-director       narrative-director    qa-lead
  release-manager      localization-lead

Tier 3 — Specialists (originally Sonnet/Haiku-tier)
  gameplay-programmer  engine-programmer     ai-programmer
  network-programmer   tools-programmer      ui-programmer
  systems-designer     level-designer        economy-designer
  technical-artist     sound-designer        writer
  world-builder        ux-designer           prototyper
  performance-analyst  devops-engineer       analytics-engineer
  security-engineer    qa-tester             accessibility-specialist
  live-ops-designer    community-manager
```

> **Note on model tiering:** The original Claude tier (opus/sonnet/haiku) is
> preserved as `metadata.ccgs_tier` on each agent for reference. `model` is left
> unset so every agent inherits the invoking agent's configured model — zero
> provider assumptions. To enable real tier-based selection, edit `opencode.json`.

### Engine Specialists

The template includes agent sets for all three major engines. Use the set that matches your project:

| Engine | Lead Agent | Sub-Specialists |
|--------|-----------|-----------------|
| **Godot 4** | `godot-specialist` | GDScript, Shaders, GDExtension |
| **Unity** | `unity-specialist` | DOTS/ECS, Shaders/VFX, Addressables, UI Toolkit |
| **Unreal Engine 5** | `unreal-specialist` | GAS, Blueprints, Replication, UMG/CommonUI |

## Slash Commands

Type `/` in OpenCode to access all 73 commands:

**Onboarding & Navigation**
`/start` `/help` `/project-stage-detect` `/setup-engine` `/adopt`

**Game Design**
`/brainstorm` `/map-systems` `/design-system` `/quick-design` `/review-all-gdds` `/propagate-design-change`

**Art & Assets**
`/art-bible` `/asset-spec` `/asset-audit`

**UX & Interface Design**
`/ux-design` `/ux-review`

**Architecture**
`/create-architecture` `/architecture-decision` `/architecture-review` `/create-control-manifest`

**Stories & Sprints**
`/create-epics` `/create-stories` `/dev-story` `/sprint-plan` `/sprint-status` `/story-readiness` `/story-done` `/estimate`

**Reviews & Analysis**
`/design-review` `/code-review` `/balance-check` `/content-audit` `/scope-check` `/perf-profile` `/tech-debt` `/gate-check` `/consistency-check` `/security-audit`

**QA & Testing**
`/qa-plan` `/smoke-check` `/soak-test` `/regression-suite` `/test-setup` `/test-helpers` `/test-evidence-review` `/test-flakiness` `/skill-test` `/skill-improve`

**Production**
`/milestone-review` `/retrospective` `/bug-report` `/bug-triage` `/reverse-document` `/playtest-report`

**Release**
`/release-checklist` `/launch-checklist` `/changelog` `/patch-notes` `/hotfix` `/day-one-patch`

**Creative & Content**
`/prototype` `/onboard` `/localize`

**Team Orchestration** (coordinate multiple agents on a single feature)
`/team-combat` `/team-narrative` `/team-ui` `/team-release` `/team-polish` `/team-audio` `/team-level` `/team-live-ops` `/team-qa`

**Studio**
`/studio-status` — show context %, model, production stage, and epic/feature/task breadcrumb.

## Getting Started

### Prerequisites

- [Git](https://git-scm.com/)
- [OpenCode](https://opencode.ai) v1.17+ (`~/.opencode/bin/opencode`)
- **Recommended**: [jq](https://jqlang.github.io/jq/) (for hook validation) and Python 3 (for JSON validation)

All hooks fail gracefully if optional tools are missing — nothing breaks, you just lose validation.

### Setup

1. **Clone or use as template**:
   ```bash
   git clone <your-fork-url> my-game
   cd my-game
   ```

2. **Open OpenCode** and start a session:
   ```bash
   opencode
   ```

3. **Run `/start`** — the system asks where you are (no idea, vague concept,
   clear design, existing work) and guides you to the right workflow. No assumptions.

   Or jump directly to a specific command if you already know what you need:
   - `/brainstorm` — explore game ideas from scratch
   - `/setup-engine godot 4.6` — configure your engine if you already know
   - `/project-stage-detect` — analyze an existing project

## Upgrading

Already using an older version of this template? See [UPGRADING.md](UPGRADING.md)
for step-by-step migration instructions.

## Project Structure

```
AGENTS.md                            # Master instructions (collaboration protocol)
opencode.json                        # Permissions, plugin ref, instruction globs
.opencode/
  agents/                            # 49 agent definitions (markdown + YAML frontmatter)
  skills/                            # 73 skill definitions (subdirectory per skill)
  commands/                          # 73 slash-command wrappers
  hooks/                             # 12 hook scripts + statusline.sh
  plugins/
    ccgs-hooks.js                    # Event adapter: OpenCode events → shell scripts
  docs/
    workflow-catalog.yaml            # 7-phase pipeline definition (read by /help)
    templates/                       # 41 document templates
  rules/                             # 11 path-scoped rule reference copies
  agent-memory/                      # Agent memory notes (lead-programmer)
src/                                 # Game source code
assets/                              # Art, audio, VFX, shaders, data files
design/                              # GDDs, narrative docs, level designs
docs/                                # Technical documentation and ADRs
tests/                               # Test suites (unit, integration, performance, playtest)
prototypes/                          # Throwaway prototypes (isolated from src/)
production/                          # Sprint plans, milestones, release tracking
```

> Path-scoped coding standards live as nested `AGENTS.md` files at each rule's
> path root (e.g. `src/gameplay/AGENTS.md`, `design/gdd/AGENTS.md`).
> Reference copies are kept in `.opencode/rules/`.

## How It Works

### Agent Coordination

Agents follow a structured delegation model:

1. **Vertical delegation** — directors delegate to leads, leads delegate to specialists
2. **Horizontal consultation** — same-tier agents can consult each other but can't make binding cross-domain decisions
3. **Conflict resolution** — disagreements escalate up to the shared parent (`creative-director` for design, `technical-director` for technical)
4. **Change propagation** — cross-department changes are coordinated by `producer`
5. **Domain boundaries** — agents don't modify files outside their domain without explicit delegation

### Collaborative, Not Autonomous

This is **not** an auto-pilot system. Every agent follows a strict collaboration protocol:

1. **Ask** — agents ask questions before proposing solutions
2. **Present options** — agents show 2-4 options with pros/cons
3. **You decide** — the user always makes the call
4. **Draft** — agents show work before finalizing
5. **Approve** — nothing gets written without your sign-off

You stay in control. The agents provide structure and expertise, not autonomy.

### Automated Safety

The **`ccgs-hooks.js` plugin** maps OpenCode events to the preserved shell scripts:

| Script | OpenCode event | What It Does |
|--------|---------------|--------------|
| `validate-commit.sh` | `tool.execute.before` (bash) | Checks for hardcoded values, TODO format, JSON validity, design doc sections — exits early if the command is not `git commit` |
| `validate-push.sh` | `tool.execute.before` (bash) | Warns on pushes to protected branches — exits early if the command is not `git push` |
| `validate-assets.sh` | `tool.execute.after` (write/edit) | Validates naming conventions and JSON structure — exits early if the file is not in `assets/` |
| `session-start.sh` | `session.created` | Shows current branch and recent commits for orientation |
| `detect-gaps.sh` | `session.created` | Detects fresh projects (suggests `/start`) and missing design docs |
| `pre-compact.sh` | `experimental.session.compacting` | Injects session state into compaction context |
| `post-compact.sh` | `session.compacted` | Reminds to restore session state from `active.md` |
| `session-stop.sh` | `session.idle` | Archives `active.md` to session log and records git activity |
| `log-agent.sh` | `tool.execute.before` (task) | Audit trail start — logs subagent invocation |
| `log-agent-stop.sh` | `tool.execute.after` (task) | Audit trail stop — completes subagent record |
| `validate-skill-change.sh` | `tool.execute.after` (write/edit) | Advises running `/skill-test` after any `.opencode/skills/` change |

> **Note**: Advisory hooks (exit 0) run silently; blocking hooks (exit 1/2) cause
> the plugin to `throw`, aborting the tool call. See `.opencode/hooks/fixtures/`
> for the two-stage payload verification gate.

**Permission rules** in `opencode.json` auto-allow safe operations (git status, test runs) and block dangerous ones (force push, `rm -rf`, reading `.env` files).

### Path-Scoped Rules

Coding standards are automatically enforced via nested `AGENTS.md` based on file location:

| Path | Enforces |
|------|----------|
| `src/gameplay/**` | Data-driven values, delta time usage, no UI references |
| `src/core/**` | Zero allocations in hot paths, thread safety, API stability |
| `src/ai/**` | Performance budgets, debuggability, data-driven parameters |
| `src/networking/**` | Server-authoritative, versioned messages, security |
| `src/ui/**` | No game state ownership, localization-ready, accessibility |
| `design/gdd/**` | Required 8 sections, formula format, edge cases |
| `tests/**` | Test naming, coverage requirements, fixture patterns |
| `prototypes/**` | Relaxed standards, README required, hypothesis documented |

## Design Philosophy

This template is grounded in professional game development practices:

- **MDA Framework** — Mechanics, Dynamics, Aesthetics analysis for game design
- **Self-Determination Theory** — Autonomy, Competence, Relatedness for player motivation
- **Flow State Design** — Challenge-skill balance for player engagement
- **Bartle Player Types** — Audience targeting and validation
- **Verification-Driven Development** — Tests first, then implementation

## Customization

This is a **template**, not a locked framework. Everything is meant to be customized:

- **Add/remove agents** — delete agent files you don't need, add new ones for your domains
- **Edit agent prompts** — tune agent behavior, add project-specific knowledge
- **Modify skills** — adjust workflows to match your team's process
- **Add rules** — create new nested `AGENTS.md` for your project's directory structure
- **Tune hooks** — adjust validation strictness, add new checks
- **Pick your engine** — use the Godot, Unity, or Unreal agent set (or none)
- **Set review intensity** — `full` (all director gates), `lean` (phase gates only), or `solo` (none). Set during `/start` or edit `production/review-mode.txt`.

## Platform Support

All hooks use POSIX-compatible patterns (`grep -E`, not `grep -P`) and include
fallbacks for missing tools, so they run on macOS, Linux, and Windows (Git Bash/WSL).
The original `notify.sh` was Windows-only; the OpenCode desktop app sends system
notifications automatically, so it is mapped best-effort via `tui.toast.show` or dropped.

## License

MIT License. See [LICENSE](LICENSE) for details.
