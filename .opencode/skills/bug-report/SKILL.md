---
name: bug-report
description: Creates a structured bug report from a description, or analyzes code to identify potential bugs. Ensures every bug report has full reproduction steps, severity assessment, and context.
metadata:
  allowed-tools: Read, Glob, Grep, Write
  user-invocable: true
  argument-hint: '[description] | analyze [path-to-file]'
  ccgs_tier: sonnet
---

## Phase 1: Parse Arguments

Determine the mode from the argument:

- No keyword → **Description Mode**: generate a structured bug report from the provided description
- `analyze [path]` → **Analyze Mode**: read the target file(s) and identify potential bugs
- `verify [BUG-ID]` → **Verify Mode**: confirm a reported fix actually resolved the bug
- `close [BUG-ID]` → **Close Mode**: mark a verified bug as closed with resolution record

If no argument is provided, ask the user for a bug description before proceeding.

---

## Phase 2A: Description Mode

1. **Parse the description** for key information: what broke, when, how to reproduce it, and what the expected behavior is.

2. **Search the codebase** for related files using Grep/Glob to add context (affected system, likely files).

3. **Draft the bug report**:

```markdown
# Bug Report

## Summary
**Title**: [Concise, descriptive title]
**ID**: BUG-[NNNN]
**Severity**: [S1-Critical / S2-Major / S3-Minor / S4-Trivial]
**Priority**: [P1-Immediate / P2-Next Sprint / P3-Backlog / P4-Wishlist]
**Status**: Open
**Reported**: [Date]
**Reporter**: [Name]

## Classification
- **Category**: [Gameplay / UI / Audio / Visual / Performance / Crash / Network]
- **System**: [Which game system is affected]
- **Frequency**: [Always / Often (>50%) / Sometimes (10-50%) / Rare (<10%)]
- **Regression**: [Yes/No/Unknown -- was this working before?]

## Environment
- **Build**: [Version or commit hash]
- **Platform**: [OS, hardware if relevant]
- **Scene/Level**: [Where in the game]
- **Game State**: [Relevant state -- inventory, quest progress, etc.]

## Reproduction Steps
**Preconditions**: [Required state before starting]

1. [Exact step 1]
2. [Exact step 2]
3. [Exact step 3]

**Expected Result**: [What should happen]
**Actual Result**: [What actually happens]

## Technical Context
- **Likely affected files**: [List of files based on codebase search]
- **Related systems**: [What other systems might be involved]
- **Possible root cause**: [If identifiable from the description]

## Evidence
- **Logs**: [Relevant log output if available]
- **Visual**: [Description of visual evidence]

## Related Issues
- [Links to related bugs or design documents]

## Notes
[Any additional context or observations]
```

---

## Phase 2B: Analyze Mode

1. **Read the target file(s)** specified in the argument.

2. **Identify potential bugs**: null references, off-by-one errors, race conditions, unhandled edge cases, resource leaks, incorrect state transitions.

3. **For each potential bug**, generate a bug report using the template above, with the likely trigger scenario and recommended fix filled in.

---

## Phase 2C: Verify Mode

Read `production/qa/bugs/[BUG-ID].md`. Extract the reproduction steps and expected result.

1. **Re-run reproduction steps** — use Grep/Glob to check whether the root cause code path still exists as described. If the fix removed or changed it, note the change.
2. **Run the related test** — if the bug's system has a test file in `tests/`, run it via Bash and report pass/fail.
3. **Check for regression** — grep the codebase for any new occurrence of the pattern that caused the bug.

Produce a verification verdict:

- **VERIFIED FIXED** — reproduction steps no longer produce the bug; related tests pass
- **STILL PRESENT** — bug reproduces as described; fix did not resolve the issue
- **CANNOT VERIFY** — automated checks inconclusive; manual playtest required

If the verdict is **VERIFIED FIXED**, treat verification, closure, stale triage
metadata cleanup, and session-state routing as one deterministic bug lifecycle
operation when the facts are unambiguous.

Before writing, present the verification evidence and ask once for the full
changeset:

> "May I update these files to mark [BUG-ID] Verified Fixed, add verification
> evidence, close the bug, refresh stale triage metadata when safe, and update
> the derived checkpoint in `production/session-state/active.md`?
> Files: `production/qa/bugs/[BUG-ID].md`, [any affected
> `production/qa/bug-triage-*.md` files], `production/session-state/active.md`."

Do not stop after VERIFIED FIXED to offer `/bug-report close [BUG-ID]` as the
next action when closure facts are deterministic. Do not ask a separate "May I
write?" for `production/session-state/active.md` when the update is only a
derived checkpoint for completed bug lifecycle work. Do not ask a separate "May
I write?" for this file.

Bundle only deterministic metadata cleanup:
- Set top-level `**Status**: Verified Fixed`.
- Add or update verification evidence with the command(s), grep checks, commit
  or file evidence, and verifier.
- Append the Closure Record from Phase 2D and set top-level `**Status**: Closed`
  when the closure record can be completed from known facts.
- Refresh affected `production/qa/bug-triage-*.md` reports only when the refresh
  removes closed bugs, updates open/closed counts, clears a stale recommended
  action, or records "0 open bugs" without assigning priorities or changing
  sprint scope.
- Update `production/session-state/active.md` only with derived checkpoint
  routing: completed bug lifecycle work, files touched, owed verification, and
  the next valid Session Worklist lane.

Do not bundle and stop for user decision if triage would require assigning
priorities, choosing sprint scope, marking bugs Won't Fix, changing severity, or
resolving conflicting bug states.

If the verdict is **STILL PRESENT** or **CANNOT VERIFY**, ask:

> "May I update `production/qa/bugs/[BUG-ID].md` to set Status: Still Present /
> Cannot Verify and add the verification evidence?"

If STILL PRESENT: reopen the bug, set Status back to Open, and suggest re-running `/hotfix [BUG-ID]`.

---

## Phase 2D: Close Mode

Read `production/qa/bugs/[BUG-ID].md`. Confirm Status is `Verified Fixed` before closing. If status is anything else, stop: "Bug [ID] must be Verified Fixed before it can be closed. Run `/bug-report verify [BUG-ID]` first."

Append a closure record to the bug file:

```markdown
## Closure Record
**Closed**: [date]
**Resolution**: Fixed — [one-line description of what was changed]
**Fix commit / PR**: [if known]
**Verified by**: qa-tester
**Closed by**: [user]
**Regression test**: [test file path, or "Manual verification"]
**Status**: Closed
```

Update the top-level `**Status**: Open` field to `**Status**: Closed`.

If the bug is already `Verified Fixed`, close the bug and refresh stale triage
metadata under the same approval when the refresh is safe deterministic cleanup.
Before writing, list the exact files and ask once:

> "May I update these files to close [BUG-ID], refresh stale triage metadata
> when safe, and update the derived checkpoint in
> `production/session-state/active.md`?
> Files: `production/qa/bugs/[BUG-ID].md`, [any affected
> `production/qa/bug-triage-*.md` files], `production/session-state/active.md`."

Do not ask a separate "May I write?" for `production/session-state/active.md`
when the update is only a derived checkpoint for completed bug lifecycle work.
Do not ask a separate "May I write?" for this file.

Safe stale triage metadata refresh includes removing the closed bug from open
bug tables, updating open/closed counts, clearing stale "fix this bug" actions,
and recording a zero-open-bugs refresh. It must not assign priorities, choose
sprint scope, mark bugs Won't Fix, change severity, or resolve conflicting bug
states.

If stale triage metadata exists but is unsafe to refresh automatically, close
the bug and mark triage cleanup as non-blocking owed follow-up instead of
blocking closure.

---

## Phase 3: Save Report

Present the completed bug report(s) to the user.

Ask: "May I write this to `production/qa/bugs/BUG-[NNNN].md`?"

If yes, write the file, creating the directory if needed. Verdict: **COMPLETE** — bug report filed.

If no, stop here. Verdict: **BLOCKED** — user declined write.

---

## Phase 4: Next Steps

After saving, suggest based on mode:

**After filing (Description/Analyze mode):**
- Run `/bug-triage` to prioritize alongside existing open bugs
- If S1 or S2: run `/hotfix [BUG-ID]` for emergency fix workflow

**After fixing the bug (developer confirms fix is in):**
- Run `/bug-report verify [BUG-ID]` — confirm the fix actually works before closing
- Never mark a bug closed without verification — a fix that doesn't verify is still Open

**After verify returns VERIFIED FIXED:**
- When closure facts are deterministic, complete verification, closure, stale
  triage metadata cleanup, and derived session-state routing under the same
  approved changeset.
- If closure or triage refresh requires a manual decision, stop at the decision
  point and make the blocked item explicit.
