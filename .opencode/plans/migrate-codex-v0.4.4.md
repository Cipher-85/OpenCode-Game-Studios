# Migration Plan: Codex Game Studios v0.4.4 → OpenCode Game Studios

> **Status**: APPROVED by user (v0.4.1 patch bump). Ready to execute.
> **Source**: Codex commit `ddb184c` (2026-07-09) — "Bump Codex package to 0.4.4"
> **Target**: OpenCode Game Studios, currently at `.opencode/VERSION` = `0.4.0`
> **Scope**: Single feature — User-Owned Playtest Focus Contract. 7 files.

## What v0.4.4 adds

When owed verification or the next action is a manual playtest, closeouts must
carry a `Playtest focus:` brief (hypothesis, setup/build, 2–4 observation
prompts, verdict/evidence) instead of a generic "go playtest" nudge — while
leaving game-feel/balance verdicts to the user. A runtime validator enforces
the contract across three surfaces.

## Adaptation decisions (Codex → OpenCode)

1. **Validator host**: Codex `.codex/lib/validate_runtime.py` → OpenCode
   `.opencode/audit.sh` (new `run_playtest_focus`), matching the established
   v0.3.0 decision that translated Python validators into bash audit commands.
2. **Command prefix**: Codex `$cmd` → OpenCode `/cmd`. None of the *added*
   text contains command refs, so no translation needed in new content.
3. **Version**: OpenCode uses its own scheme. Single-feature bridge = patch
   bump `0.4.0` → `0.4.1`. (Also fixes pre-existing README badge staleness:
   badge said `0.3.0` while VERSION was `0.4.0`.)
4. **Out of scope**: Codex v0.4.3 "parity guards / command-policy / upstream
   audit record" are Codex-runtime-specific (`.codex/` config) with no
   OpenCode counterpart — deliberately not bridged.

---

## File 1: `.opencode/skills/playtest-report/SKILL.md`

### 1a. Expand `## Test Focus` (lines 43–44)

**OLD:**
```
## Test Focus
[What specific features or flows were being tested]
```

**NEW:**
```
## Test Focus
- **Hypothesis**: [What feeling, behavior, or evidence this playtest is probing]
- **Setup/build**: [Build, commit, command, save state, or scenario if known]
- **Observation prompts**:
1. [Specific thing to watch for]
2. [Specific thing to watch for]
3. [Optional specific thing to watch for]
4. [Optional specific thing to watch for]
- **Verdict/evidence to return**: [User-owned pass/fail/needs-rethink verdict plus notes, screenshots, logs, or report path]
```

### 1b. Add gap-statement guidance to Phase 2B (after line 97)

**OLD:**
```
Read the raw notes at the provided path. Cross-reference with existing design documents. Fill in the template above with structured findings. Flag any playtest observations that conflict with design intent.
```

**NEW:**
```
Read the raw notes at the provided path. Cross-reference with existing design documents. Fill in the template above with structured findings. Flag any playtest observations that conflict with design intent.

If the notes omit a specific hypothesis or focus, state that gap before
analysis and ask for or infer only a provisional `Playtest focus:` from the
notes. Do not route the user to another manual playtest without a concrete
hypothesis, setup/build if known, 2-4 observation prompts, and the
verdict/evidence the user should return.
```

### 1c. Add playtest-focus routing bullet to Phase 5 (after line 148)

**OLD:**
```
- After fixing bugs: re-run `/bug-triage` to update priorities.
```

**NEW:**
```
- After fixing bugs: re-run `/bug-triage` to update priorities.
- If another user-owned playtest is the routed next step, include `Playtest
  focus:` with the specific hypothesis, setup/build if known, 2-4 observation
  prompts, and the verdict/evidence the user should return. The focus brief
  narrows the test but leaves game-feel and balance decisions to the user.
```

---

## File 2: `.opencode/docs/session-continuity.md`

### 2a. Insert `## User-Owned Playtest Focus` section (between line 27 and `## Pause Procedure`)

**OLD:**
```
The checkpoint exception is narrow. It never authorizes new design, game-feel,
balance, architecture, source, registry, index, status-file, commit, push,
branch, build, boot-smoke, mutating `gh`, or additional file changes.

## Pause Procedure
```

**NEW:**
```
The checkpoint exception is narrow. It never authorizes new design, game-feel,
balance, architecture, source, registry, index, status-file, commit, push,
branch, build, boot-smoke, mutating `gh`, or additional file changes.

## User-Owned Playtest Focus

When owed verification or the next valid lane is a user-owned playtest, preserve
a concrete focus brief in both the closeout and any `## Session Worklist` entry.
Use the label `Playtest focus:` and include:

- **Hypothesis**: what feeling, behavior, or evidence the playtest is probing.
- **Setup/build**: the build, command, save state, or scenario to use when
  known.
- **Observation prompts**: 2-4 observation prompts for specific things the
  user should watch for.
- **Verdict/evidence to return**: the user-owned pass/fail/needs-rethink
  verdict plus the notes, screenshots, logs, or playtest report path needed to
  make the evidence usable.

The brief narrows the test; it does not make the game-feel, balance, keep,
revert, or tune decision for the user.

## Pause Procedure
```

### 2b. Add playtest-focus line to Pause Procedure step 3 (after "The user can reply with `1`.")

**OLD:**
```
   `Next action:` then `1. (Recommended) [action label] - [brief reason /
   command]`. The user can reply with `1`.
```

**NEW:**
```
   `Next action:` then `1. (Recommended) [action label] - [brief reason /
   command]`. The user can reply with `1`.
   If that lane is a user-owned playtest, include the preserved `Playtest
   focus:` brief before the next-action prompt.
```

---

## File 3: `AGENTS.md`

### 3a. Add playtest-focus sub-bullet to closeout contract (after line 43)

**OLD:**
```
  `Next action:` then `1. (Recommended) [action label] - [brief reason /
  command]`. Base that next action on the `## Session Worklist` when
  `production/session-state/active.md` exists. The user can reply with `1`.
```

**NEW:**
```
  `Next action:` then `1. (Recommended) [action label] - [brief reason /
  command]`. Base that next action on the `## Session Worklist` when
  `production/session-state/active.md` exists. The user can reply with `1`.
  - When the next action or owed verification is a user-owned playtest, include
    `Playtest focus:` with the hypothesis, setup/build if known, 2-4 observation
    prompts, and the verdict/evidence the user should return.
```

---

## File 4: `.opencode/audit.sh` — new `run_playtest_focus` validator + wiring

### 4a. Add `playtest` to the usage comment (line 12 area)

**OLD:**
```
#   checkpoint   Check active.md silent-checkpoint contract on skills/agents
#   runtime      Check for stale references
```

**NEW:**
```
#   checkpoint   Check active.md silent-checkpoint contract on skills/agents
#   playtest     Check playtest-focus contract on root/continuity/skill surfaces
#   runtime      Check for stale references
```

### 4b. Add `playtest` to the command-parsing case (line 29)

**OLD:**
```
    all|agents|skills|runtime|config|hooks|smoke|release|closeout|checkpoint) command="$1"; shift ;;
```

**NEW:**
```
    all|agents|skills|runtime|config|hooks|smoke|release|closeout|checkpoint|playtest) command="$1"; shift ;;
```

### 4c. Add the `run_playtest_focus` function (insert after `run_checkpoint` closing `}`, before `run_runtime()`)

**INSERT before the line `run_runtime() {`:**

```bash
run_playtest_focus() {
  printf '\n── Playtest Focus Contract ────────────────────────────────\n'
  local -a surfaces=(
    "AGENTS.md"
    ".opencode/docs/session-continuity.md"
    ".opencode/skills/playtest-report/SKILL.md"
  )
  local -a phrases=(
    "user-owned playtest"
    "Playtest focus:"
    "hypothesis"
    "setup/build"
    "2-4 observation"
    "verdict/evidence"
  )
  local checked=0
  local rel
  for rel in "${surfaces[@]}"; do
    local f="$root/$rel"
    checked=$((checked + 1))
    [ -f "$f" ] || { fail "$rel (missing file)"; continue; }
    local missing=() p
    for p in "${phrases[@]}"; do
      if ! grep -qiF "$p" "$f" 2>/dev/null; then missing+=("$p"); fi
    done
    # session-continuity also requires the Session Worklist reference
    if [ "$rel" = ".opencode/docs/session-continuity.md" ]; then
      if ! grep -qiF "Session Worklist" "$f" 2>/dev/null; then missing+=("Session Worklist"); fi
    fi
    if [ "${#missing[@]}" -eq 0 ]; then
      pass "$rel (playtest focus contract)"
    else
      fail "$rel missing: ${missing[*]}"
    fi
  done
  printf '  %d playtest-focus surfaces checked\n' "$checked"
}

```

### 4d. Wire into the `all` case (add `run_playtest_focus` after `run_checkpoint`)

**OLD:**
```
  all)
    run_agents
    run_skills
    run_closeout
    run_checkpoint
    run_runtime
    run_config
    run_hooks
    run_smoke
    ;;
```

**NEW:**
```
  all)
    run_agents
    run_skills
    run_closeout
    run_checkpoint
    run_playtest_focus
    run_runtime
    run_config
    run_hooks
    run_smoke
    ;;
```

### 4e. Add `playtest` dispatch + update Available list

**OLD:**
```
  checkpoint) run_checkpoint ;;
  runtime)  run_runtime ;;
```

**NEW:**
```
  checkpoint) run_checkpoint ;;
  playtest) run_playtest_focus ;;
  runtime)  run_runtime ;;
```

**OLD (error message):**
```
    *) printf 'Unknown command: %s\nAvailable: all, agents, skills, closeout, checkpoint, runtime, config, hooks, smoke, release\n' "$command" >&2; exit 2 ;;
```

**NEW:**
```
    *) printf 'Unknown command: %s\nAvailable: all, agents, skills, closeout, checkpoint, playtest, runtime, config, hooks, smoke, release\n' "$command" >&2; exit 2 ;;
```

---

## File 5: `.opencode/VERSION`

**OLD:** `0.4.0`
**NEW:** `0.4.1`

---

## File 6: `CHANGELOG.md`

### 6a. Insert v0.4.1 entry before v0.4.0

**OLD:**
```
# Changelog

## v0.4.0 - 2026-07-09
```

**NEW:**
```
# Changelog

## v0.4.1 - 2026-07-09

Bridged Codex Game Studios v0.4.4 (user-owned playtest focus contract) into
the OpenCode-native port.

- Added a user-owned playtest focus contract so closeouts and owed verification
  include a `Playtest focus:` brief (hypothesis, setup/build, 2-4 observation
  prompts, verdict/evidence) instead of generic playtest requests, while
  leaving game-feel and balance verdicts with the user.
- Updated `/playtest-report` templates and routing so new reports and follow-up
  playtests carry a concrete hypothesis before sending the user back to play.
- Updated `AGENTS.md` and `session-continuity.md` to preserve the playtest
  focus brief in closeouts and `## Session Worklist` entries.
- Added a `run_playtest_focus` validator to `.opencode/audit.sh` (run via
  `audit.sh playtest` or as part of `audit.sh all`) that enforces the
  playtest-focus contract across root instructions, continuity docs, and the
  playtest-report workflow.

## v0.4.0 - 2026-07-09
```

---

## File 7: `README.md`

### 7a. Version badge (line 16)

**OLD:** `src="https://img.shields.io/badge/version-0.3.0-blue" alt="v0.3.0"`
**NEW:** `src="https://img.shields.io/badge/version-0.4.1-blue" alt="v0.4.1"`

### 7b. Package version line (line 72)

**OLD:** `Package version: `0.3.0` (see [`.opencode/VERSION`](.opencode/VERSION)).`
**NEW:** `Package version: `0.4.1` (see [`.opencode/VERSION`](.opencode/VERSION)).`

### 7c. Add playtest-focus bullet to "Current Status" list (after "This release includes:")

**OLD:**
```
This release includes:
- Session Worklist routing cache (`## Session Worklist` + `## Phase Guard` in
```

**NEW:**
```
This release includes:
- User-owned playtest focus routing: when owed verification or the next action
  is a manual playtest, closeouts include a `Playtest focus:` brief with the
  hypothesis, setup/build, observation prompts, and verdict/evidence to return.
  `/playtest-report` templates and follow-up routing now require concrete
  hypotheses before sending the user back to play, while preserving the user's
  ownership of game-feel and balance verdicts. A `run_playtest_focus` validator
  keeps the contract present in root instructions, session-continuity docs, and
  the playtest-report workflow.
- Session Worklist routing cache (`## Session Worklist` + `## Phase Guard` in
```

### 7d. Project Structure version comment (line 367)

**OLD:** `  VERSION                            # Package version (0.3.0)`
**NEW:** `  VERSION                            # Package version (0.4.1)`

---

## Verification (run after all edits applied)

```bash
bash .opencode/audit.sh playtest    # new validator: 3 surfaces, 0 missing phrases
bash .opencode/audit.sh all         # no regressions across all validators
bash .opencode/audit.sh release     # VERSION 0.4.1 matches CHANGELOG ## v0.4.1
```

Expected: all green. `run_playtest_focus` checks 3 surfaces for phrases
`user-owned playtest`, `Playtest focus:`, `hypothesis`, `setup/build`,
`2-4 observation`, `verdict/evidence` (session-continuity also `Session Worklist`).

---

## Execution checklist

- [ ] File 1a — playtest-report Test Focus expanded
- [ ] File 1b — playtest-report Phase 2B gap guidance
- [ ] File 1c — playtest-report Phase 5 routing bullet
- [ ] File 2a — session-continuity User-Owned Playtest Focus section
- [ ] File 2b — session-continuity Pause Procedure line
- [ ] File 3a — AGENTS.md closeout sub-bullet
- [ ] File 4a–4e — audit.sh run_playtest_focus + wiring
- [ ] File 5 — VERSION 0.4.0 → 0.4.1
- [ ] File 6a — CHANGELOG v0.4.1 entry
- [ ] File 7a–7d — README badge + version + status bullet + structure comment
- [ ] Verify: audit.sh playtest / all / release all pass
