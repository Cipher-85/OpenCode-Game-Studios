# Latest Test Evidence

Date: 2026-07-16

Scope: OpenCode Game Studios v0.5.1 — port of Codex Game Studios handoff-push
hardening (upstream commit `0c6df429`, "Harden handoff push approval flow") into
the OpenCode-native port. Version-bump metadata from upstream `0dd1bd3`
("Bump Codex package to 0.6.1") applied in OpenCode form (own version line).

## Commands Run

```bash
bash .opencode/audit.sh all
rg -n '\.agents/skills|\.codex|"\["git|\$handoff|\$skill|/approve|Codex surface|CCGS skill' .opencode/skills/handoff/SKILL.md
git rev-parse --abbrev-ref HEAD
git rev-parse --abbrev-ref --symbolic-full-name '@{u}'
git remote get-url --push origin
```

## Result

- `bash .opencode/audit.sh all`: pass (0 errors)
  - agents: 49 checked
  - skills: 77 checked
  - closeout: 19 checked (15 marker-triggered + complete, 4 no-marker skipped)
  - active-state checkpoint: 38 files, 0 violations
  - playtest-focus: 3 surfaces
  - bug-lifecycle: 2 surfaces
  - handoff-review: 2 surfaces — `handoff/SKILL.md (review gate contract)`
    and `AGENTS.md (handoff review exception)` both pass; the Phase 4 edit did
    not disturb the 27 required review-contract phrases (all live in the
    Round-1/Round-2 sections)
  - resume contract: 0 violations
  - runtime: no `.claude/` or `CLAUDE.md` references
  - config: opencode.json valid; all instruction files exist
  - install-safety: 5 guards pass
  - hooks: 12 checked; fixture tests 11 passed, 0 failed
  - smoke: 49 agents, 77 skills, 77 commands, 12 hooks, 17 agent-memory, 15 rules
- Token-leak grep over the edited skill: no matches (exit 1) — no `.agents/`,
  `.codex`, `["git","push"]` JSON, `$handoff`/`$skill`, `/approve`,
  "Codex surface", or "CCGS skill" tokens leaked into the OpenCode skill.
- Phase 4 snippet exercise:
  - Current branch resolves to `main`.
  - Upstream detection returns `origin/main` (exit 0) — the existing-upstream
    case routes to plain `git push`.
  - `git remote get-url --push origin` returns the verified github.com push URL.
  - A temporary no-upstream branch yields the expected non-zero lookup
    (`fatal: no upstream configured`, exit 128), which the skill treats as the
    no-upstream case routing to `git push -u origin <branch>` — not a Phase
    failure. Temp branch created and deleted during the check.

## Notes

- Verification ran in `/Users/yongatron/Development/opencode-game-studios`.
- Files changed this session: `.opencode/skills/handoff/SKILL.md` (Phase 4
  rewrite), `.opencode/VERSION` (`0.5.0` → `0.5.1`), `CHANGELOG.md`
  (v0.5.1 section), `README.md` (version badge + two text refs),
  `production/test-evidence/latest.md` (this file), and the migration plan at
  `.opencode/plans/migrate-codex-v0.6.1.md`.
- OpenCode-local rules preserved through the port: hesitate before pushing
  `main`/`master`/`develop`; runtime push failures (auth/network/rejected)
  remain non-fatal.
- Codex-platform internals from the v0.6.0/v0.6.1 releases (`.codex/*`
  validators, `validate_smoke.py`, role-activation fixtures, CCGS frontmatter)
  intentionally not ported — out of scope per the established bridging policy.
