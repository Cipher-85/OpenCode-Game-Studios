# Audit: OpenCode Game Studios vs Codex Game Studios

> **Created:** 2026-07-05
> **Codex source:** https://github.com/Cipher-85/Codex-Game-Studios (v0.3.0, cloned `--depth 1`)
> **OpenCode target:** https://github.com/Cipher-85/opencode-game-studios (commit `2f72e8f`, `main`)

---

## Overview

The Codex-Game-Studios port (v0.3.0) has evolved significantly beyond a
mechanical port — it added **behavioral QoL improvements** that are
engine-agnostic and should be bridged to OpenCode. The gap falls into 8
categories: 2 high-priority (behavioral), 3 medium (operational), 2 low
(optional polish), and 1 explicit skip (Codex-specific infrastructure).

---

## 🔴 Category 1: AGENTS.md behavioral sections (10 missing)

The OpenCode `AGENTS.md` is 42 lines (tech stack + collaboration protocol +
start note). The Codex `AGENTS.md` is 173 lines with these **additional
sections** that drive agent behavior at runtime:

| Section | What it does | Impact if missing |
|---|---|---|
| **Startup Contract** | Authoritative agent registration source; exact naming; no `.claude/` writes; no autonomous commits; context-% compaction decisions | Agents lack startup ground rules |
| **Resume & Wrap-Up Routing** | Routes "resume/pick up/catch up" → `/resume-from-handoff`; "what's next" → `/studio-next`; wrap-up epilogue vs durable `/handoff` | No structured resume flow |
| **Verification Integrity** | Hard rules: never claim unverified results; evidence labels (`verified this turn` / `file-reported` / `blocked` / `not run`); CI-read procedure; recovery procedure | Agents may claim unverified passes |
| **Vertical-Slice Forcing Function** | Classify work as `extend`/`feed`/`carve-out`; smallest playable advance wins unless owed verification blocks | Agents drift to non-slice work |
| **Code-Turn Discipline** | Think → define verifiable success → simplest design → surgical changes → narrowest verification | Agents may over-refactor |
| **Workflow Gates** | Explicit gate list (`/design-review` before GDD→code, `/story-done` before complete, `/smoke-check` before QA hand-off, `/team-qa` for sign-off, `/code-review` after major features) | Gates only in skill bodies, not globally visible |
| **File Lifecycle** | Track vs ignore policy; anti-redundancy (AGENTS.md = hot path only; path-rules = discipline; long procedures in docs); pause audit checklist | No file-tracking discipline |
| **Continuity Epilogue** | After each work unit: summarize → surface owed verification → recommend next → suggest handoff | No post-task continuity |
| **Available Role Agents** | Organized agent roster by tier (leadership / leads / design-content / engineering-QA-ops / engine) | Agents not discoverable from AGENTS.md |
| **Path-Scoped Instructions** | Detailed table mapping each path glob to its rule file(s), including base + specific layering (e.g. `src/**` → `source-code.md`, `src/gameplay/**` → `source-code.md` + `gameplay-code.md`) | Path rules less discoverable |

**Plan:** Rewrite `AGENTS.md` to incorporate all 10 sections, adapted for
OpenCode (`/resume-from-handoff` instead of `$resume-from-handoff`,
`.opencode/` paths, `opencode.json` instructions mechanism).

---

## 🔴 Category 2: 3 new skills missing

The Codex port added 4 new skills. OpenCode has 0 of them (studio-status
exists as a command wrapper but lacks the skill body with the same contract):

| Skill | Lines | Purpose |
|---|---|---|
| **`studio-next`** | 176 | Lightweight continuity router — reads handoff/sprint/stage/slice state, applies vertical-slice forcing function, recommends single best next action. Read-only, never writes/commits/pushes. Includes Continuity Epilogue Pattern to apply after any work unit. |
| **`handoff`** | 167 | Write-side: creates durable `production/session-handoff.md` before pausing. Phases: review gate → choose label → update session state (rotate prior to archive) → refresh local scratchpad → commit when authorized → push when authorized → report and stop. Size check at 25 KB. |
| **`resume-from-handoff`** | 223 | Read-side: turns handoff into oriented prioritized plan. Steps: handle missing → read canonical state → apply vertical-slice forcing → "you are here" map → synthesize worklist by lane → surface blockers/gates → present resume briefing → structured work-item choice via `question` tool. |

The 4th Codex-new skill, `studio-status`, already exists in OpenCode as a
command (`.opencode/commands/studio-status.md`), but not as a full skill. The
Codex version also has a `studio-status-on-start.sh` hook for session-start
status injection — OpenCode's `/studio-status` is on-demand only (documented
gap).

**Plan:** Port all 3 skills to `.opencode/skills/` + matching
`.opencode/commands/` wrappers. Adapt:
- `request_user_input` → `question` tool
- `.agents/skills/` → `.opencode/skills/`
- `$skill-name` → `/skill-name`
- `.codex/docs/` → `.opencode/docs/`
- `apply_patch` references → `write`/`edit`

---

## 🟡 Category 3: 3 new operational docs missing

These docs are the **design contract** that the new skills and AGENTS.md
sections reference:

| Doc | Lines | Content |
|---|---|---|
| **`verification-integrity.md`** | 51 | Hard verification rules (never claim unverified), evidence labels (`verified this turn` / `file-reported` / `blocked` / `not run`), CI-read handling (open concrete run, confirm step, quote key line), incident examples, 5-step recovery procedure |
| **`session-continuity.md`** | 58 | File roles (active.md = live checkpoint, session-handoff.md = canonical resume, session-archive.md = historical only, src/README.md = slice history), pause/resume procedures, context thresholds (50% bounded reads, 60-70% compact/handoff, >70% avoid broad work), 3 handoff depth tiers |
| **`file-lifecycle.md`** | 44 | Track vs ignore vs keep-local policy, anti-redundancy (AGENTS.md = hot path only; path-rules = discipline; long procedures in docs), pause audit checklist (scope adherence, temp files untracked, verification labels accurate, next-action discoverable, fresh-session readability) |

**Plan:** Port all 3 to `.opencode/docs/`, adapting `.codex/` → `.opencode/`
paths and `$skill-name` → `/skill-name`. Add all 3 to the `instructions` array
in `opencode.json` so they're globally loaded for every agent.

---

## 🟡 Category 4: Agent memory expansion (1 → 17)

The OpenCode port has 1 agent-memory file (lead-programmer, with real notes).
The Codex port has **17** — one for every agent that had `memory: project` or
`memory: user` in upstream:

```
art-director, audio-director, creative-director, economy-designer,
game-designer, lead-programmer, level-designer, localization-lead,
narrative-director, performance-analyst, producer, qa-lead,
systems-designer, technical-director, ux-designer, world-builder, writer
```

Each MEMORY.md has:
- A "Memory Contract" stating the agent must read this file before role work
  and must NOT write global Codex/OpenCode memories.
- A "Durable Notes" section (stub for project-specific rulings to be added
  over time).

**Plan:** Create 16 new `MEMORY.md` files in `.opencode/agent-memory/`. The
existing lead-programmer one stays as-is (already has real notes). Copy the
Codex contract text, adapting "Codex" → "OpenCode" and `.codex/` → `.opencode/`.

---

## 🟡 Category 5: Production state files & root docs

**Missing production concepts (referenced by the 3 new skills):**
- `production/session-handoff.md` — canonical resume narrative (created by
  `/handoff`, read by `/resume-from-handoff`)
- `production/session-archive.md` — historical handoff rotation target
- `production/test-evidence/latest.md` — latest test evidence pointer

These are created on demand by the skills; only `.gitkeep` placeholders are
needed for directory structure.

**Missing root files:**
- `CHANGELOG.md` — version history. Codex has v0.1.0 → v0.3.0 documenting
  port milestones. OpenCode should have an equivalent starting at its initial
  commit.
- `ATTRIBUTION.md` — upstream attribution + coexistence constraints. States
  the port is pinned to upstream commit `984023d`, keeps upstream MIT license,
  and does not modify `.claude/` or `CLAUDE.md` (adapted: does not ship
  `.claude/` at all).

**Plan:**
- Add `CHANGELOG.md` with initial entry documenting the OpenCode port.
- Add `ATTRIBUTION.md` adapted for OpenCode.
- The production files are created by the skills; no static files needed
  beyond existing `.gitkeep`.

---

## 🟡 Category 6: Modified skill bodies (continuity integration)

The Codex port modified 5+ skill bodies to integrate the continuity system.
After porting the 3 new skills, these skill bodies need the same updates:

| Skill | Change |
|---|---|
| `gate-check` | Phase 7: append `/studio-next` routing after gate verdict instead of static menu |
| `code-review` | Phase 9: suggest `/handoff` when session state should be preserved; route to `/studio-next` |
| `story-done` | Phase 8: append `/studio-next` routing; suggest `/handoff` |
| `help` | Step 7: route to `/studio-next` for post-task continuity |
| `start` | Closing: mention `/studio-next` as the continuity router |

The substantive phase/checklist content of these skills remains faithful to
upstream — the changes are to closing/routing sections only.

**Plan:** After porting the 3 new skills, update the closing sections of these
5 skills. Apply `opencode` path conventions (`.opencode/docs/` not
`.codex/docs/`, `/skill-name` not `$skill-name`).

---

## 🟢 Category 7: Path-rules restructure (optional improvement)

The Codex port restructured path rules into
`.codex/instructions/path-rules/` (15 files) with:
- **`source-code.md`** as a base rule loaded for ALL `src/**` edits, plus
  more specific sub-rules layered on top
- **`tool-code.md`** (new — rules for `tools/` directory)
- **`design-directory.md`** and **`docs-directory.md`** as base rules for
  those trees
- Separation of path-rules (prose, in `instructions/path-rules/`) from
  command-policy (in `rules/*.rules`)

The OpenCode port has 11 nested `AGENTS.md` files (one per rule path) but:
- No base-rule layering (`src/AGENTS.md` exists but doesn't explicitly say
  "also load the more specific rule for your subdirectory")
- No `tools/` coverage
- Path rules and command policy are both in the same mechanism

**Plan:** Optional. Could enhance `src/AGENTS.md` to reference sub-rule
AGENTS.md files explicitly. Add `tools/AGENTS.md`. Low priority — the nested
AGENTS.md approach already works via OpenCode's tree-walking discovery.

---

## 🟢 Category 8: Studio-status skill + hook

The Codex port has:
- A `studio-status` **skill** (30 lines) that reads `production/stage.txt`,
  `production/review-mode.txt`, `production/session-state/active.md` and
  renders a status breadcrumb.
- A `studio-status-on-start.sh` **hook** (482 bytes) that runs at SessionStart
  to print the status, since Codex lacks a custom TUI footer item.

The OpenCode port has a `/studio-status` **command** only (runs statusline.sh
on demand). It does not have the skill body or the session-start hook.

**Plan:** Consider porting the `studio-status` skill body for consistency
with the other 3 new skills. The session-start hook is less valuable in
OpenCode (which has `session.created` event support via the plugin, and the
desktop app sends notifications). Low priority.

---

## ⚪ Category 9: Codex-specific infrastructure (NOT bridging)

These are Codex-specific and either don't apply to OpenCode or need radical
adaptation:

| Item | Why skip |
|---|---|
| `.codex/config.toml`, `models.toml` | Codex-specific config; OpenCode uses `opencode.json` |
| `.codex/agents/*.toml` | TOML agent format; OpenCode uses markdown agents with YAML frontmatter |
| `.codex/hooks.json` | Codex hook wiring via `bash -lc` discovery; OpenCode uses `ccgs-hooks.js` plugin |
| `.codex/rules/settings.rules` | Codex command-policy format (`prefix_rule`); OpenCode uses `opencode.json` permission object |
| `install.sh` / `uninstall.sh` | Designed for multi-target Codex installs with coexistence detection; OpenCode projects are self-contained |
| `release.sh` | Codex-specific `codex-vX.Y.Z` tag governance; OpenCode can use standard git tags |
| `manifest/` (3 JSON files) | SHA256 inventory for coexistence tracking and incremental patching; overkill for self-contained OpenCode projects |
| `lib/validate_*.py` | Python validators for Codex's audit framework (manifest, runtime, hooks, install, rules, release, smoke); would need radical rewrite for OpenCode |
| `audit.sh` | Dispatcher for Codex validators |
| `studio-status-on-start.sh` | Codex-specific session-start hook |
| `.codex/tests/fixtures/` | Codex-specific test fixtures for the audit framework |

---

## Bridging Plan

| Priority | Category | Items | Effort |
|---|---|---|---|
| 🔴 **P0** | 1 | Rewrite `AGENTS.md` with 10 behavioral sections | Medium |
| 🔴 **P0** | 2 | Port 3 new skills (`studio-next`, `handoff`, `resume-from-handoff`) + command wrappers | Medium |
| 🟡 **P1** | 3 | Port 3 new docs (`verification-integrity`, `session-continuity`, `file-lifecycle`) + add to `instructions` | Small |
| 🟡 **P1** | 4 | Create 16 agent-memory MEMORY.md files | Small |
| 🟡 **P1** | 5 | Add `CHANGELOG.md` + `ATTRIBUTION.md` | Small |
| 🟡 **P2** | 6 | Update 5 skill bodies for continuity integration (`gate-check`, `code-review`, `story-done`, `help`, `start`) | Small |
| 🟢 **P3** | 7 | Add `tools/AGENTS.md` path rule; enhance base-rule layering | Trivial |
| 🟢 **P3** | 8 | Port `studio-status` skill body for consistency | Trivial |
| ⚪ Skip | 9 | Codex-specific infrastructure | — |

### Suggested implementation order

1. **P0 — AGENTS.md rewrite** (the behavioral foundation everything else references)
2. **P0 — 3 new skills + commands** (the operational tools the AGENTS.md sections reference)
3. **P1 — 3 new docs** (the design contracts the skills enforce)
4. **P1 — 16 agent-memory files** (quick scripted creation)
5. **P1 — CHANGELOG + ATTRIBUTION** (quick)
6. **P2 — skill body updates** (closing-section integration with new skills)
7. **P3 — optional polish** (tools rule, studio-status skill)

### Key adaptation rules (Codex → OpenCode)

| Codex | OpenCode |
|---|---|
| `$skill-name` | `/skill-name` |
| `.codex/docs/` | `.opencode/docs/` |
| `.codex/agents/*.toml` | `.opencode/agents/*.md` |
| `.agents/skills/` | `.opencode/skills/` |
| `request_user_input` | `question` |
| `.codex/instructions/path-rules/` | nested `AGENTS.md` (already in place) |
| `config.toml` | `opencode.json` |
| `apply_patch` | `write` / `edit` / `apply_patch` |

---

## Codex reference inventory (for porting source material)

| Source path | Use |
|---|---|
| `.codex/AGENTS.md` (root, 173 lines) | Source for AGENTS.md rewrite |
| `.agents/skills/studio-next/SKILL.md` (176 lines) | Source for studio-next skill |
| `.agents/skills/handoff/SKILL.md` (167 lines) | Source for handoff skill |
| `.agents/skills/resume-from-handoff/SKILL.md` (223 lines) | Source for resume-from-handoff skill |
| `.codex/docs/verification-integrity.md` (51 lines) | Source for verification doc |
| `.codex/docs/session-continuity.md` (58 lines) | Source for continuity doc |
| `.codex/docs/file-lifecycle.md` (44 lines) | Source for lifecycle doc |
| `.codex/agent-memory/*/MEMORY.md` (17 dirs) | Source for 16 new memory files |
| `ATTRIBUTION.md` (21 lines) | Source for attribution doc |
| `CHANGELOG.md` (50 lines) | Source for changelog format |
