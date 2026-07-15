# Migration Plan: Codex Game Studios v0.6.1 → OpenCode Game Studios

> **Status**: APPROVED by user (0.5.1 patch bump; full GitHub dest-evidence port;
> OpenCode permission-prompt dialect). Executing.
> **Source**: Codex commit `0c6df429` (2026-07-15) — "Harden handoff push
> approval flow" + `0dd1bd3` (2026-07-15) — "Bump Codex package to 0.6.1".
> **Target**: OpenCode Game Studios, `.opencode/VERSION` = `0.5.0`.
> **Scope**: Single feature — handoff Phase-4 push-approval hardening. 5 files.

## What's new upstream since the last bridge

Two commits land after the v0.5–v0.6 bridge (`0a726f0`, 2026-07-12):

- `0c6df429` — substantive: hardens `handoff/SKILL.md` Phase 4 "Push Handoff"
  (+50/-5). Adds upstream detection, push-remote URL verify, same-turn GitHub
  destination evidence (account/repo/permission), single command-shape rule, and
  fail-closed on policy denial.
- `0dd1bd3` — metadata only: VERSION, CHANGELOG, README, test-evidence. Its
  `.codex/*` deltas are Codex-internal and intentionally not ported.

The intervening `79e30c3` "Release Codex v0.6.0" is ~90% `.codex/*` internals
(`validate_smoke.py`, role-activation fixtures, CCGS frontmatter) — already
excluded by the established "no Codex-platform internals" policy; its advisory
smoke content was bridged in the v0.5.0 Phase-3 work.

## Adaptation decisions (Codex → OpenCode)

1. **Path/dialect**: Codex `.agents/skills/handoff/SKILL.md` → OpenCode
   `.opencode/skills/handoff/SKILL.md`. Codex `$handoff` → OpenCode `/handoff`.
2. **Approval dialect**: Codex `["git","push"]` JSON escalation + `/approve` →
   OpenCode native permission-prompt model. On denial, fail closed; user may
   re-run the push once permission is granted. `/approve` does not exist in
   OpenCode and is dropped.
3. **Wording**: "Codex surface" → "OpenCode session".
4. **GitHub dest-evidence**: full port — `gh auth status`, `gh api user`,
   `gh repo view … viewerPermission` (require `WRITE`/`MAINTAIN`/`ADMIN`).
   Network-restricted sandbox failures are not treated as invalid credentials.
5. **Preserved local improvements** (not in upstream, must not be lost):
   - "Hesitate if branch is `main`/`master`/`develop` — ask before pushing."
   - Runtime push failures (auth/network/rejected) remain non-fatal — handoff is
     valid locally; continue to Phase 5.
6. **Version**: OpenCode owns its line. Single-skill hardening = patch bump
   `0.5.0` → `0.5.1`.
7. **Audit gate**: `run_handoff_review` (`.opencode/audit.sh:333-406`) enforces
   27 review-contract phrases — all in the Round-1/Round-2 sections, none in
   Phase 4 — so the Phase-4 edit is gate-safe. The runtime token-scan forbids
   `.codex`, `.agents/skills`, `$skill`, "CCGS skill" — ported text avoids them.

---

## File 1: `.opencode/skills/handoff/SKILL.md` — Phase 4 rewrite (lines 230-251)

Replace the `## Phase 4: Push Handoff` block through the "hesitate if main/
master/develop" paragraph with the hardened, OpenCode-adapted version that adds:
upstream detection via `git rev-parse --abbrev-ref --symbolic-full-name '@{u}'`;
push-remote URL verification; same-turn GitHub destination evidence; single
command-shape rule; OpenCode permission-prompt authorization; fail-closed on
denial. Preserves: `main`/`master`/`develop` hesitation + non-fatal runtime
failure resilience.

## File 2: `.opencode/VERSION`

`0.5.0` → `0.5.1`.

## File 3: `CHANGELOG.md`

Prepend `## v0.5.1 - 2026-07-16` section describing the hardened push routing,
GitHub dest-evidence, permission-prompt dialect translation, and preserved local
rules; note Codex-platform internals intentionally not ported.

## File 4: `README.md`

Update version references: badge (line 16), package-version text (line 72), tree
comment (line 445) — all `0.5.0` → `0.5.1`.

## File 5: `production/test-evidence/latest.md`

Refresh from stale v0.3.0/2026-07-06 to v0.5.1/2026-07-16; record the actual
`audit.sh all` result from verification.

---

## Verification

1. `bash .opencode/audit.sh all` — expect pass, 0 errors; watch `handoff-review`,
   `release` (VERSION↔CHANGELOG consistency), `closeout`, `runtime` token-scan.
2. Token-leak grep on the edited skill — expect no matches for `.agents/skills`,
   `.codex`, `["git","push"]` JSON, `$handoff`, `/approve`, "Codex surface",
   "CCGS skill".
3. Exercise the Phase 4 snippets on a no-upstream branch and on `main` (which has
   `origin/main`) to confirm the upstream-detection branch logic reads correctly.
