# OpenCode Game Studios — Faithful Port Plan

> **Status:** Plan approved 2026-07-04 (amendments folded in).
> **Source of truth:** `Donchitos/Claude-Code-Game-Studios` @ commit `984023ddac0d5e27624f2baacde6105e45de375f` (2026-05-13).
> **Target:** A native OpenCode project that behaves as close to the Claude Code original as OpenCode allows.

## Locked-in decisions (recommended defaults)

1. **Model tiering** → record original Claude tier (`opus`/`sonnet`/`haiku`) in agent/skill `metadata.ccgs_tier` only. Leave `model` unset so every agent/skill inherits the invoking agent's configured model. Zero provider assumptions; no hardcoded model IDs.
2. **Body tool-name pass** → scripted, scoped, whole-word token substitution: `AskUserQuestion` → `question` and `Task` → `task`, applied across agent + skill bodies only. No prose rewriting. **Outputs a diff-report artifact** listing every substitution for review.
3. **Runtime layout** → clean `.opencode/`-only. The `.claude/` runtime tree is omitted from the shipped port to avoid OpenCode loading both `.claude/skills` and `.opencode/skills` (which would duplicate skills).

## Runtime verification

OpenCode **v1.17.13** is installed at `~/.opencode/bin/opencode` (not on the shell PATH; invoke via full path or add `~/.opencode/bin` to PATH). The audit session is running inside it with `--auto`. Docs consulted (opencode.ai/docs, last updated Jul 3 2026) align with this build, so the compatibility map in §2 is docs-and-runtime verified. Verified CLI inspection commands used by this plan:
- `opencode debug config` — show resolved configuration
- `opencode debug skill` — list all available skills (confirms `.opencode/skills` loads)
- `opencode debug agent <name>` — show a specific agent's resolved config
- `opencode debug paths` / `opencode debug info` — global paths and debug info

Remaining runtime unknowns are narrower than docs-only: the exact **event payload shapes** for plugin hooks (§5 two-stage gate) and the **nested-AGENTS.md loading semantics** (§8).

---

## 0. Key findings that shape the strategy

Verified from OpenCode docs:

1. **OpenCode skills ≠ slash commands.** Skills (`.opencode/skills/<name>/SKILL.md`) load on-demand via the `skill` tool; the `/start`-style UX requires separate `.opencode/commands/*.md` wrappers. Preserving the 73 slash commands is **additive** (wrappers), not a rename.
2. **OpenCode skill frontmatter recognizes only `name, description, license, compatibility, metadata`.** All other CCGS skill fields (`allowed-tools`, `user-invocable`, `argument-hint`, `model`, `agent`, `context`, `isolation`) are silently ignored. To avoid losing them they must move into `metadata`.
3. **Claude-compat in OpenCode is partial.** It covers `CLAUDE.md` (fallback when no `AGENTS.md`) and `.claude/skills/` + `~/.claude/skills/`. It does **not** cover `.claude/agents/`, `.claude/rules/`, `.claude/hooks/`, `settings.json`, or `statusLine`. A pure "leave it in `.claude/`" port is impossible — agents, rules, hooks, permissions, and statusline must move to native mechanisms regardless.

---

## 0.5 Behavioral invariants (the contract everything below obeys)

These are the product-behavior guarantees the port must not violate. Every later section is subordinate to these.

- **User-driven collaboration:** Question → Options → Decision → Draft → Approval. No file is written without explicit user sign-off ("May I write this to [filepath]?").
- **Advisory-only gates:** `/gate-check` and director reviews inform the user; they do **not** hard-block unless the specific workflow says so.
- **Minimal autonomous action:** agents and skills never silently advance project stage, change review mode, or commit. State changes are user-driven.
- **File-backed continuity:** all session/project state is recoverable from repo files (`production/session-state/**`, `stage.txt`, `review-mode.txt`, sprint/epic/GDD/ADR paths).
- **Safety bias:** destructive git/shell blocked; `.env` reads denied; invalid JSON in `assets/data/**` blocking; protected-branch push advisory.
- **Non-stricter-than-upstream:** review modes (`full`/`lean`/`solo`), gate strictness, and permission posture must not become more restrictive than the Claude Code original. When in doubt, preserve the looser behavior.

---

## 1. Original Project Inventory (verified by parsing all files)

| Area | Location | Count / Format | Runtime role |
|---|---|---|---|
| Master config | `CLAUDE.md` (54 lines) | 6 `@path` imports | Top-level instructions, collaboration protocol |
| Runtime config | `.claude/settings.json` | `statusLine`, `permissions.{allow,deny}`, `hooks` (9 event keys) | Permissions + hook wiring |
| Status line | `.claude/statusline.sh` | bash, reads session JSON on stdin | Footer: `ctx% \| model \| stage \| breadcrumb` |
| Agents | `.claude/agents/*.md` | 49 | Subagents invoked via `Task` |
| Skills | `.claude/skills/*/SKILL.md` | 73 (one file per dir) | The slash-command behaviors |
| Hooks | `.claude/hooks/*.sh` | 12 | Safety / gap / compaction / audit |
| Rules | `.claude/rules/*.md` | 11, each `paths:` frontmatter + prose | Path-scoped coding standards |
| Docs | `.claude/docs/**` | 19 docs + 40 templates + `workflow-catalog.yaml` (7 phases, 45 steps) | Imported / reference content |
| Nested CLAUDE.md | `design/`, `docs/`, `src/`, testing framework | 4 files | Scope-local standards |
| Memory | `.claude/agent-memory/lead-programmer/MEMORY.md` | 1 file (only populated one) | Agent notes |
| Test framework | `CCGS Skill Testing Framework/` | catalog.yaml + rubric + 49 agent specs + 72 skill specs | Drives `/skill-test` |
| Shared areas | `design/ docs/ production/ src/` | stage.txt, review-mode.txt, active.md, sprints, epics, GDDs, ADRs | File-backed continuity |
| Other | `.github/`, `LICENSE`, `README.md`, `UPGRADING.md`, `CONTRIBUTING.md`, `SECURITY.md` | — | Meta |

**Agent frontmatter (all 49):** `name`, `description`, `tools` (Read/Glob/Grep/Write/Edit/Bash/WebSearch/Task), `model` (opus×3 / sonnet×44 / haiku×2), `maxTurns` (30/25/20/10), plus occasional `memory` (17), `disallowedTools` (15), `skills` (6), `isolation: worktree` (1 — prototyper only).

**Skill frontmatter (all 73):** `name`, `description`, `argument-hint`, `user-invocable: true`, `allowed-tools`, `model` (sonnet×63 / haiku×7 / opus×3), plus occasional `agent` (20), `context` (3, shell preambles), `isolation` (2).

**Runtime interaction:** `CLAUDE.md` imports core docs → `/start` writes `stage.txt` + `review-mode.txt` and routes to the next skill → skills read/write `production/**` and `design/**`, hand off via `/next-skill`, spawn agents via `Task`, capture decisions via `AskUserQuestion` → hooks enforce safety + write audit logs → `workflow-catalog.yaml` drives `/help`.

---

## 2. Claude Code → OpenCode Compatibility Map (verified)

| Claude concept | OpenCode target | Strategy |
|---|---|---|
| `CLAUDE.md` | `AGENTS.md` + `opencode.json.instructions[]` | `@path` imports → `instructions` glob (canonical mechanism) |
| `.claude/agents/*.md` | `.opencode/agents/*.md` | Frontmatter convert; bodies unchanged (except tool-token pass) |
| `.claude/skills/*/SKILL.md` | `.opencode/skills/*/SKILL.md` | Frontmatter normalize (extras → `metadata`); bodies unchanged |
| Slash-command skills | `.opencode/commands/*.md` | **Add** 73 wrappers (one per skill) |
| `Task` tool | `task` tool | Direct (same name & schema: `subagent_type`, `prompt`) |
| `AskUserQuestion` tool | `question` tool | Same semantics; scoped token rename in bodies |
| `TodoWrite` | `todowrite` | Same |
| `WebSearch` / `WebFetch` | `websearch` / `webfetch` | Direct |
| `Write`/`Edit`/`Read`/`Glob`/`Grep` | `write`/`edit`/`read`/`glob`/`grep` | Direct (case-insensitive to model) |
| `settings.json.permissions` | `opencode.json.permission` | `Bash(git status*)`→`bash.{"git status*":"allow"}`, `Read(**/.env*)`→`read.{"*.env*":"deny"}` |
| `.claude/rules/*.md` (`paths:`) | **Nested `AGENTS.md`** (path-only) at each path root | Faithful path-scoping; collaboration protocol kept global via `instructions`, not in nested files; `.opencode/rules/*.md` kept as reference copies |
| `SessionStart` | `session.created` event | Closest fit (gap noted) |
| `PreToolUse` Bash | `tool.execute.before` (`input.tool==="bash"`) | Direct |
| `PostToolUse` Write\|Edit | `tool.execute.after` (`write`/`edit`/`apply_patch`) | Adapter extracts paths |
| `PreCompact` | `experimental.session.compacting` | Good fit — inject active.md + git state |
| `PostCompact` | `session.compacted` event | Reasonable |
| `Stop` | `session.idle` event | Reasonable |
| `SubagentStart` / `SubagentStop` | `tool.execute.before/after` (`task`) | Emulation via task-tool logging |
| `Notification` | `tui.toast.show` (best-effort) or drop | Cross-platform best-effort; desktop app also notifies automatically |
| `statusLine.command` | none native | `/studio-status` command + optional plugin (always-on footer is a gap) |
| `memory: project\|user` | none native | Preserve `agent-memory/` + body instruction (emulation) |
| `isolation: worktree` | none native | Body instruction requiring user approval (emulation) |
| `maxTurns` | `steps` | Mechanical map |
| Agent `tools` allow-list | `permission` object | **Deny-by-default**, allow only original tools (see §4.5) |

**Notes on tool mapping:**
- **No `permission.task` restrictions added.** Claude enforces the studio hierarchy by prompt convention, not hard tool restrictions; the OpenCode port preserves that (`task` stays `allow` for all agents).
- **`AskUserQuestion` → `question` carries a residual risk.** Schemas differ: Claude's tabbed/multi-question layouts and >4-option usages may need splitting across one or more `question` calls. Validation must review any usage with >4 options or multiple questions.
- **Agent `tools` → `permission` is deny-by-default** (§4.5): OpenCode defaults to allow-all, so each converted agent must deny everything not in its original `tools` list or behavior becomes *looser* than upstream.

---

## 3. Behavioral Preservation Plan

- **Collaboration protocol** (Question → Options → Decision → Draft → Approval): preserved verbatim in `AGENTS.md` and kept globally reachable via `opencode.json.instructions`; OpenCode's Plan mode coexists (repo instructions still enforce sign-off).
- **49 agents:** names, prompts, model-tier *intent*, `maxTurns`→`steps`, tool surface preserved. Hierarchy stays **prompt-enforced** (no `permission.task` restrictions added — Claude didn't hard-restrict either).
- **73 skills:** names, bodies, phase structure, file writes, `/handoff` references preserved. Frontmatter extras move to `metadata` so `/skill-test` and audits still see them.
- **73 slash commands:** every original `/name` reproduced as a command wrapper that inlines the matching skill body and passes `$ARGUMENTS`.
- **Workflow phases / gates:** `workflow-catalog.yaml` copied; stage names, review modes (`full`/`lean`/`solo`), advisory (non-blocking) gate semantics unchanged. **Must not become stricter than upstream** (§0.5).
- **File-backed continuity:** `production/session-state/active.md`, `stage.txt`, `review-mode.txt`, sprint-status, session-logs — paths unchanged.
- **Safety semantics:** invalid JSON in `assets/data/**` stays **blocking**; protected-branch push stays **advisory**; `.env` reads denied; destructive git/bash denied. Exit-code mapping: Claude exit 2 (and validate-assets' exit 1) → plugin `throw`.
- **Path-scoped rules:** preserved as nested `AGENTS.md` (path-specific standards only); global protocol stays in `instructions`.
- **Status line:** info preserved via `/studio-status`; always-visible footer = unavoidable gap.

**Unavoidable behavior differences** (documented in `PORTING_NOTES.md`):
1. No native always-on status footer.
2. `session.created` ≠ Claude `SessionStart` (fires on creation, may differ from "open").
3. No documented `SubagentStart`/`Stop` parity — emulated via task-tool before/after.
4. Model tiering preserved as metadata only (per locked decision 1).
5. Agent `memory` has no native mechanism — only lead-programmer had populated memory.

---

## 4. File-by-File / Directory Port Plan

| Original | Target | Action |
|---|---|---|
| `CLAUDE.md` | `AGENTS.md` | **Semantic-light**: keep protocol, drop `@imports` (moved to `instructions`), update `/start` note |
| `.claude/settings.json` | `opencode.json` | **Semantic**: permission map + plugin ref + instructions + paths |
| `.claude/agents/*.md` (49) | `.opencode/agents/*.md` | **Mechanical** frontmatter convert; bodies byte-identical (except tool-token pass) |
| `.claude/skills/*/SKILL.md` (73) | `.opencode/skills/*/SKILL.md` | **Mechanical** frontmatter normalize (extras → `metadata`); bodies unchanged |
| (new) 73 skill invocations | `.opencode/commands/*.md` | **New** wrappers (see §4.5 template) |
| `.claude/hooks/*.sh` (12) | `.opencode/hooks/*.sh` | **Copy + path/payload adapters** (`.claude/skills` → `.opencode/skills` in validate-skill-change) |
| (new) | `.opencode/plugins/ccgs-hooks.js` | **New** adapter: OpenCode events → shell scripts |
| `.claude/statusline.sh` | `.opencode/hooks/statusline.sh` + `.opencode/commands/studio-status.md` | Preserve logic as on-demand command |
| `.claude/docs/**` | `.opencode/docs/**` | **Copy**; mechanical `.claude`/`CLAUDE.md` path-refs updated |
| `.claude/docs/workflow-catalog.yaml` | `.opencode/docs/workflow-catalog.yaml` | **Copy** + command/path refs |
| `.claude/rules/*.md` (11) | nested `AGENTS.md` (path-only) + `.opencode/rules/*.md` (reference) | Bodies preserved; scope via nested AGENTS.md; protocol stays global via `instructions`; rule coverage audit (§6) |
| `.claude/agent-memory/**` | `.opencode/agent-memory/**` | Copy; named corrections (§4.5) |
| `design/CLAUDE.md`, `docs/CLAUDE.md`, `src/CLAUDE.md` | `design/AGENTS.md`, `docs/AGENTS.md`, `src/AGENTS.md` | Mechanical |
| `design/ docs/ production/ src/` | same | Unchanged |
| `CCGS Skill Testing Framework/` | same | **Copy** + update `.claude/skills` → `.opencode/skills`, frontmatter-key expectations |
| `.github/`, `LICENSE`, etc. | same | Copy |
| `README.md`, `UPGRADING.md` | same | Rewrite install/runtime sections only |
| `.claude/**` runtime tree | **not shipped** | Avoid duplicate-loading collisions with `.opencode/` |
| (new) | `PORTING_NOTES.md` | Source commit, gaps, decisions |

**New native files:** `.opencode/plugins/ccgs-hooks.js`, `.opencode/commands/studio-status.md`, `opencode.json`, `AGENTS.md`, nested rule `AGENTS.md` files, `PORTING_NOTES.md`.

---

## 4.5 Conversion rules (mechanical, auditable)

Rules every converter script must follow. Each produces a report artifact.

**Command-wrapper template** (73 wrappers in `.opencode/commands/<name>.md`):
- `template` body = skill body inlined via `@.opencode/skills/<name>/SKILL.md` (commands support `@file` refs), plus an argument-handling line `\n\nArguments: $ARGUMENTS`.
- `agent:` ← the skill's original `agent` field (20 skills, e.g. `technical-director`); unset otherwise (runs in current primary agent).
- `subtask: true` for orchestrator/delegation skills (`team-*`, plus any skill whose body spawns subagents via `task`); unset otherwise.
- `description:` ← skill's `description`.
- `model:` unset (per locked decision 1).

**Agent frontmatter** (49 agents in `.opencode/agents/<name>.md`):
- `description` kept. `mode: subagent` (all 49 — they are Task-invoked).
- `maxTurns` → `steps` (mechanical integer map).
- **`tools` → `permission`, deny-by-default:** start from all-tools-deny, then set `allow` only for tools in the original `tools` list. Mapping: Read→`read`, Glob→`glob`, Grep→`grep`, Write/Edit→`edit`, Bash→`bash`, WebSearch→`websearch`, WebFetch→`webfetch`, Task→`task`. This is the **highest-fidelity-risk step** in the port — a missed tool makes the agent *stricter* than upstream. Per-agent parity check required (§6).
- **`disallowedTools` → explicit deny:** `disallowedTools.X` → `permission.X: "deny"` (15 agents, e.g. `disallowedTools: Bash` → `bash: deny`), even if X is already absent from `tools`.
- `model` unset; original tier (`opus`/`sonnet`/`haiku`) → `metadata.ccgs_tier`.
- `memory`, `skills`, `isolation: worktree` have no native equivalent → preserved in `metadata` and reasserted as a body instruction.
- `name` dropped (OpenCode uses filename).

**Skill frontmatter** (73 skills in `.opencode/skills/<name>/SKILL.md`):
- Reduce to OpenCode-recognized fields: `name`, `description`.
- Move ALL other original fields into `metadata`: `allowed-tools`, `user-invocable`, `argument-hint`, `model` (as `ccgs_tier`), `agent`, `context`, `isolation`. (OpenCode silently ignores unknown top-level fields, so this is lossless and required for `/skill-test` + audits to still see them.)
- Body unchanged except the scoped `AskUserQuestion`→`question` / `Task`→`task` token pass (decision 2), which emits a **diff report**.

**`agent-memory/lead-programmer/MEMORY.md` corrections** (named, not "fix stale notes"):
- Remove/annotate the `context: fork` frontmatter convention — no skill uses it; it is a dead linter check, not a real schema.
- Update any `.claude/...` paths to `.opencode/...`.

**Body tool-name pass** (decision 2, scoped to agent + skill bodies only):
- `AskUserQuestion` → `question`; `Task` → `task`. Scripted, whole-word, case-sensitive. Emits a diff-report artifact. Does not touch prose, comments, or these plan files.

---

## 5. Hook / Automation Port Plan

Single plugin `.opencode/plugins/ccgs-hooks.js` exports hooks; each delegates to the preserved shell script in `.opencode/hooks/`, building a Claude-shaped stdin JSON so scripts stay nearly unchanged.

| Claude hook | OpenCode event | Script | Notes |
|---|---|---|---|
| SessionStart ×2 | `session.created` | session-start.sh, detect-gaps.sh | Closest fit; gap vs Claude "open" |
| PreToolUse:Bash ×2 | `tool.execute.before` (`bash`) | validate-commit.sh, validate-push.sh | `output.args.command`; exit 2 → `throw` to block |
| PostToolUse:Write\|Edit ×2 | `tool.execute.after` (`write`/`edit`/`apply_patch`) | validate-assets.sh, validate-skill-change.sh | Extract `filePath`; for apply_patch parse patch text; update skill path check |
| PreCompact | `experimental.session.compacting` | pre-compact.sh | Push `output.context[]` |
| PostCompact | `session.compacted` | post-compact.sh | Emit reminder |
| Stop | `session.idle` | session-stop.sh | Archive active.md, log |
| SubagentStart/Stop | `tool.execute.before/after` (`task`) | log-agent.sh, log-agent-stop.sh | Read `subagent_type` from task args |
| Notification | `tui.toast.show` (best-effort) or drop | notify.sh | Windows-only originally; desktop app also auto-notifies |

**Adapter rules:** preserve exit semantics (advisory prints + return; blocking → `throw`); keep `jq` + grep fallback; keep POSIX `grep -E`.

**Two-stage hook verification gate (Phase 5 exit):**
1. **Static payload fixtures** — one fixture per hook event, built from OpenCode docs, asserting the adapter normalizes the event payload into the Claude-shaped JSON the shell scripts expect (`tool_input.command`, `tool_input.file_path`, `.agent_type`, `.message`).
2. **Runtime payload capture** — once OpenCode is installed, log the real `input`/`output` for each event and diff against the static fixture. **Event existence ≠ payload-shape parity**; the docs do not fully specify field names for every event, so this capture is mandatory, not optional.

**Compaction (both phases):** inject recovery context (`active.md`, git state, WIP markers) in `experimental.session.compacting` **and** emit the restore-state reminder on `session.compacted`. Belt-and-suspenders since PostCompact parity is emulated.

**Notifications:** `notify.sh` is Windows-only upstream. Map `Notification` to `tui.toast.show` (documented event) as a best-effort cross-platform channel; otherwise drop. The OpenCode desktop app also sends system notifications automatically on session idle/error, so this is low-priority.

---

## 6. Validation Strategy

**Static parity:**
- Exact counts: 49 agents / 73 skills / 73 commands / 11 rule-scope mappings / 12 hook behaviors / 40 templates.
- `opencode.json` validates against `https://opencode.ai/config.json`.
- **Parser check on every converted agent + skill** (frontmatter parses; required fields present).
- **Per-agent permission parity check:** each agent's `permission.allow` set == its original `tools` list (deny-by-default rule, §4.5).
- Every command wrapper resolves to an existing skill (`agent:` target exists where set).
- **Rule coverage audit:** all 11 original `paths:` globs have a matching nested `AGENTS.md`.
- **Stale-reference scan:** ripgrep for `.claude/` runtime refs, `CLAUDE.md`, Claude model names (`opus`/`sonnet`/`haiku` outside `metadata`), and Claude tool names (`AskUserQuestion`/`Task` outside allowed legacy mentions). Allow only inside `metadata` and `PORTING_NOTES.md`.
- No `.claude/` runtime shipped.

**Upstream-quirks freeze list (validation must NOT "fix" these — they are original behavior):**
- `vertical-slice` skill is missing from `CCGS Skill Testing Framework/catalog.yaml` (73 skills vs 72 catalog entries).
- Stale "52 skills" / "72 skills" counts inside `skill-test/SKILL.md` samples.
- `validate-assets.sh` blocks with exit 1, not Claude's exit-2 convention.
- `context: fork` linter check in `skill-test` is dead code (no skill uses `context: fork`).

**Behavioral smoke:** `/start` (empty project) asks starting point, writes stage/review-mode only after selection; `/brainstorm` director-gate flow; `/dev-story` blocks cleanly on missing TR/ADR/control-manifest; `/team-combat` orchestration + approval transitions; `/skill-test static start`; agent invocation for game-designer / lead-programmer / producer / qa-lead / prototyper; permission smoke (destructive bash denied, `git status` allowed, `.env` read denied); hook fixtures for commit / push / asset / skill-change / task-logging / compaction; review any `question` usage with >4 options or multiple questions.

**Runtime gate:** run `opencode debug config` (confirmed command in v1.17.13) to confirm the plugin/permissions/instructions resolve; `opencode debug skill` to confirm all 73 skills load from `.opencode/skills`; `opencode debug agent <name>` (e.g. `creative-director`, `game-designer`, `prototyper`) to confirm agent permission/model/steps resolved as designed. Throwaway session runs `/start`, `/studio-status`, one agent task, one hook-triggering edit; transcript diff vs Claude behavior.

**Regression checklist:** command / agent / stage / review-mode names unchanged; safety block/warn semantics match; no prompt rewrites in mechanical phases.

---

## 7. Migration Phases

1. **Baseline ledger** — record commit, counts, per-file disposition. *Verify:* ledger accounts for everything.
2. **Native scaffold** — `AGENTS.md`, `opencode.json`, `.opencode/` skeleton, `PORTING_NOTES.md`. *Verify:* schema validates; no behavior rewritten.
3. **Mechanical agents/skills/commands** — 49 agents + 73 skills (frontmatter only) + 73 command wrappers + scoped `AskUserQuestion`→`question` / `Task`→`task` token pass + **diff report**. *Verify:* frontmatter parser + command↔skill parity + per-agent permission parity.
4. **Docs/templates/rules/state** — `.opencode/docs/**`, workflow-catalog, nested path-only AGENTS.md, nested design/docs/src AGENTS.md, MEMORY.md named corrections. *Verify:* expanded stale-path scan; rule coverage audit = 11.
5. **Hook plugin shim** — `ccgs-hooks.js` + adapted scripts + **two-stage payload gate** (static fixtures, then runtime capture). *Verify:* fixture tests per hook pass; runtime payload diff clean.
6. **Skill-test framework** — retarget to `.opencode/`. *Verify:* `/skill-test static/category/audit` pass; upstream-quirk freeze list honored (no silent fixes).
7. **Runtime smoke + docs** — run `opencode debug config` / `debug skill` / `debug agent` (v1.17.13 confirmed) + smoke session; finalize README/UPGRADING. *Verify:* live load + parity transcript.

No broad rewrites in phases 1–4.

---

## 8. Risks & Open Questions

- **Runtime mostly verified** — OpenCode v1.17.13 installed and running; config/skill/agent inspection commands confirmed. Remaining unknowns: exact plugin **event payload shapes** (§5 two-stage gate) and **nested-AGENTS.md loading semantics** (below). Event existence ≠ payload-shape parity.
- **Model tiering** — preserved as metadata only per decision 1; users wanting real tier-based model selection must edit `opencode.json` later.
- **`session.created` vs `SessionStart`** — semantic mismatch; `session-start` / `detect-gaps` output may appear at a different moment.
- **No `SubagentStart`/`Stop` parity** — audit logging becomes task-tool-emulated.
- **Nested `AGENTS.md` loading** — mitigated by keeping the collaboration protocol global via `opencode.json.instructions`; nested files carry path-specific standards only. Remaining edge: deeply nested paths may get only the nearest path rules, but none of the 11 CCGS rule globs nest under each other, so this is a non-issue in practice.
- **Agent `tools` → `permission` deny-by-default** — highest fidelity risk; mitigated by per-agent parity check (§6).
- **`apply_patch` path extraction** in post-tool hook needs care.
- **`AskUserQuestion` → `question` schema differences** — residual risk after the token pass; mitigated by reviewing multi-question/>4-option usages.
- **Command-wrapper template** — `agent:` / `subtask:` propagation rules are designed but need runtime confirmation that `@file` inlining + `$ARGUMENTS` behaves identically to Claude's slash-command skill invocation.
- Pre-existing upstream quirks are frozen, not fixed (§6 freeze list).

---

## Sources audited

- Upstream: https://github.com/Donchitos/Claude-Code-Game-Studios (@ `984023d`)
- OpenCode docs: `/docs/`, `/docs/config/`, `/docs/agents/`, `/docs/skills/`, `/docs/commands/`, `/docs/rules/`, `/docs/plugins/`, `/docs/permissions/`, `/docs/references/`
- OpenCode config schema: https://opencode.ai/config.json
