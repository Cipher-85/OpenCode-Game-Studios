# Changelog

## v0.2.1 - 2026-07-05

Bridged Codex Game Studios v0.3.1–v0.3.2 decision-prompt and handoff improvements
into the OpenCode-native port.

- Added low-friction decision-prompt rules so next-step handoffs list real viable
  options (usually 3-5, fewer when fewer are real), mark one `(Recommended)`, and
  support short numbered or `a. yes` / `b. no` replies when OpenCode has no
  clickable choice UI.
- Updated `/studio-next` to rank viable next actions instead of collapsing most
  situations to a single next step, while keeping mandatory gates as go/no-go
  prompts.
- Made explicit `/handoff` invocation authorize the OpenCode-native handoff
  workflow end to end: continuity-file updates, path-scoped staging, the standard
  handoff commit, and a normal push of the current branch. Kept the exception
  narrowly scoped — no source edits, no branch switching, no force-push, and no
  `--no-verify` or amend workarounds.
- Added the `Low-Friction Decision Prompts` section and the `/handoff` exception
  to `AGENTS.md`.
- Modernized `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md`: added the no-clickable-UI
  fallback guidance and renamed `AskUserQuestion` → `question` throughout (the
  original port only renamed tools in agent/skill bodies, leaving this doc on the
  legacy Claude tool name).

## v0.2.0 - 2026-07-05

- Bridged Codex Game Studios QoL improvements:
  - Rewrote root `AGENTS.md` with 10 behavioral sections (Startup Contract,
    Resume & Wrap-Up Routing, Verification Integrity, Vertical-Slice Forcing
    Function, Code-Turn Discipline, Workflow Gates, File Lifecycle, Continuity
    Epilogue, Available Role Agents, Path-Scoped Instructions routing table).
  - Added 3 new continuity skills: `/studio-next`, `/handoff`,
    `/resume-from-handoff` + command wrappers.
  - Added 3 operational docs: `verification-integrity.md`,
    `session-continuity.md`, `file-lifecycle.md` (loaded globally via
    `opencode.json` instructions).
  - Expanded agent memory from 1 to 17 files (all upstream `memory:` scoped
    agents now have repo-local MEMORY.md contracts).
  - Added `tools/AGENTS.md` path rule.
  - Added path-rule routing table to AGENTS.md (nested AGENTS.md files are not
    auto-discovered by OpenCode — agents must be told to read them).
- Added `CHANGELOG.md` and `ATTRIBUTION.md`.
- Fixed post-audit issues:
  - `question` and `todowrite` permissions set to `allow` on all 49 agents
    (implicitly available in Claude Code; deny-by-default was stricter than
    upstream).
  - Updated 72 testing-framework spec files for OpenCode `metadata` frontmatter.
  - Updated `hooks-reference.md` with OpenCode event mapping.
  - Renamed `CLAUDE-local-template.md` → `AGENTS-local-template.md`.
  - Hardened plugin `$` API with `.cwd()` availability guard.

## v0.1.0 - 2026-07-04

Initial OpenCode Game Studios public release.

- Ported the Claude Code Game Studios role-agent and workflow-skill structure to
  OpenCode-native agents, skills, commands, hooks, plugin adapter, and startup
  instructions.
- 49 agents (permission deny-by-default, `metadata.ccgs_tier` model-tier routing).
- 73 skills (frontmatter normalized: `name`/`description` top-level, extras in
  `metadata`).
- 74 commands (73 skill wrappers + `/studio-status`).
- 12 hooks + `ccgs-hooks.js` plugin adapter (OpenCode events → shell scripts).
- 11 path-scoped rules as nested `AGENTS.md`.
- Static fixture tests for hook payload shapes.
- Preserved upstream MIT attribution.
