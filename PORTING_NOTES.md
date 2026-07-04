# Porting Notes — OpenCode Game Studios

> Faithful port of `Donchitos/Claude-Code-Game-Studios` to a native OpenCode project.

## Source of truth

- **Upstream repo:** https://github.com/Donchitos/Claude-Code-Game-Studios
- **Source commit:** `984023ddac0d5e27624f2baacde6105e45de375f` (2026-05-13, "Release v1.0.0")
- **Plan:** `opencode-plan.md` (approved 2026-07-04)

## Baseline ledger (Phase 1)

| Area | Source location | Count | Target | Disposition |
|---|---|---|---|---|
| Master config | `CLAUDE.md` (54 lines) | 1 | `AGENTS.md` | Semantic-light port |
| Runtime config | `.claude/settings.json` | 1 | `opencode.json` | Semantic port |
| Status line | `.claude/statusline.sh` | 1 | `.opencode/hooks/statusline.sh` + `/studio-status` | Copy + command wrapper |
| Agents | `.claude/agents/*.md` | 49 | `.opencode/agents/*.md` | Mechanical frontmatter convert |
| Skills | `.claude/skills/*/SKILL.md` | 73 | `.opencode/skills/*/SKILL.md` | Mechanical frontmatter normalize |
| Command wrappers | (new) | 73 | `.opencode/commands/*.md` | New, one per skill |
| Hooks | `.claude/hooks/*.sh` | 12 | `.opencode/hooks/*.sh` | Copy + path adapters |
| Hook plugin | (new) | 1 | `.opencode/plugins/ccgs-hooks.js` | New adapter |
| Rules | `.claude/rules/*.md` | 11 | nested `AGENTS.md` + `.opencode/rules/*.md` | Path-scoped via nested AGENTS.md |
| Docs | `.claude/docs/**` | 63 | `.opencode/docs/**` | Copy + path-ref updates |
| Nested CLAUDE.md | `design/`, `docs/`, `src/` | 3 | nested `AGENTS.md` | Mechanical rename |
| Agent memory | `.claude/agent-memory/lead-programmer/MEMORY.md` | 1 | `.opencode/agent-memory/lead-programmer/MEMORY.md` | Copy + named corrections |
| Test framework | `CCGS Skill Testing Framework/` | 1 tree | same | Copy + retarget to `.opencode/` |
| Shared areas | `design/ docs/ production/ src/` | — | same | Unchanged |
| `.claude/**` runtime | — | — | **not shipped** | Avoid duplicate-loading |

## Locked-in decisions (from plan)

1. **Model tiering** → record original Claude tier (`opus`/`sonnet`/`haiku`) in `metadata.ccgs_tier` only. `model` left unset so agents/skills inherit the invoking agent's configured model. Zero provider assumptions.
2. **Body tool-name pass** → scripted, scoped, whole-word token substitution: `AskUserQuestion` → `question` and `Task` → `task`, applied across agent + skill bodies only. Diff report emitted.
3. **Runtime layout** → clean `.opencode/`-only. The `.claude/` runtime tree is omitted to avoid duplicate skill loading.

## Conversion rules applied

### Agent frontmatter (49 agents)
- `name` dropped (OpenCode uses filename).
- `description` kept. `mode: subagent` added (all are Task-invoked).
- `maxTurns` → `steps` (mechanical integer map).
- `tools` → `permission`, **deny-by-default**: start from all-deny, allow only original tools. Mapping: Read→`read`, Glob→`glob`, Grep→`grep`, Write/Edit→`edit`, Bash→`bash`, WebSearch→`websearch`, WebFetch→`webfetch`, Task→`task`.
- `disallowedTools` → explicit `permission.X: "deny"` even if absent from `tools`.
- `model` unset; original tier → `metadata.ccgs_tier`.
- `memory`, `skills`, `isolation: worktree` → preserved in `metadata` + reasserted as body instruction.

### Skill frontmatter (73 skills)
- Reduced to OpenCode-recognized fields: `name`, `description`.
- All other original fields moved into `metadata`: `allowed-tools`, `user-invocable`, `argument-hint`, `model` (as `ccgs_tier`), `agent`, `context`, `isolation`.
- Body unchanged except scoped `AskUserQuestion`→`question` / `Task`→`task` token pass.

### Command wrappers (73 commands)
- `template` body = skill body inlined via `@.opencode/skills/<name>/SKILL.md` + argument line.
- `agent:` ← skill's original `agent` field (20 skills); unset otherwise.
- `subtask: true` for orchestrator/delegation skills (`team-*` + skills spawning subagents).
- `description:` ← skill's `description`.
- `model:` unset (decision 1).

## Upstream-quirks freeze list (NOT fixed — original behavior)

- `vertical-slice` skill is missing from `CCGS Skill Testing Framework/catalog.yaml` (73 skills vs 72 catalog entries).
- Stale "52 skills" / "72 skills" counts inside `skill-test/SKILL.md` samples.
- `validate-assets.sh` blocks with exit 1, not Claude's exit-2 convention.
- `context: fork` linter check in `skill-test` is dead code (no skill uses `context: fork`).

## Unavoidable behavior differences (gaps)

1. **No native always-on status footer.** Info preserved via `/studio-status` command; always-visible footer is a gap. The `/studio-status` command pipes `/dev/null` to `statusline.sh`, so live session data (model, context%) is unavailable — only the stage from `production/stage.txt` renders. This is an unavoidable gap: OpenCode commands can't access live session JSON.
2. **`session.created` ≠ Claude `SessionStart`.** Fires on creation, may differ from "open".
3. **No documented `SubagentStart`/`Stop` parity** — emulated via task-tool before/after logging.
4. **Model tiering preserved as metadata only** — no real tier-based model selection.
5. **Agent `memory` has no native mechanism** — only lead-programmer had populated memory; preserved as body instruction + `.opencode/agent-memory/`.
6. **`isolation: worktree` (prototyper only) has no native equivalent** — preserved as body instruction requiring user approval.
7. **Agent `metadata` passed through to provider** — OpenCode routes unknown agent frontmatter fields into `options`, which are sent to the LLM provider as model options. The `metadata` object (`ccgs_tier`, `memory`, `skills`, `isolation`) is harmless (providers ignore unknown nested options) but not clean. No action needed unless a provider rejects it.
8. **Plugin `$` API runtime verification (Stage 2 gate)** — The `ccgs-hooks.js` adapter uses Bun's `$` shell API with a `.cwd()` availability guard. Static fixture tests pass; runtime payload capture (Stage 2) is required to confirm: (a) script receives correct stdin JSON, (b) advisory hooks don't block, (c) blocking hooks throw correctly.

## Post-audit corrections

The following issues were identified in a side-by-side audit against upstream and fixed:

- **`question`/`todowrite` permissions** — originally set to `deny` for all 49 agents (deny-by-default). Changed to `allow` because `AskUserQuestion` and `TodoWrite` were implicitly available to all Claude Code agents (never listed in `tools` but always usable). The deny was stricter than upstream and broke 15 delegating skills (e.g. `/code-review` → lead-programmer instructs `Use question:` but `question` was denied).
- **72 testing-framework spec files** — frontmatter assertion line was stale ("Has required frontmatter fields: name, description, argument-hint, user-invocable, allowed-tools"). Updated to reflect OpenCode's `metadata` frontmatter model.
- **`hooks-reference.md`** — was documenting old Claude event names (SessionStart, PreToolUse, etc.). Updated with OpenCode event mapping column.
- **`CLAUDE-local-template.md`** — renamed to `AGENTS-local-template.md` and repurposed for OpenCode's override mechanism (no auto-loaded `.local` variant; must be added to `instructions` array).
