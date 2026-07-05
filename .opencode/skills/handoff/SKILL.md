---
name: handoff
description: "Use when the user wants to stop, pause, checkpoint, switch machines, or preserve current session state for a future OpenCode session."
---

# Handoff

Create a durable OpenCode session handoff for this project. This is the write-side
pair for `/resume-from-handoff`.

## Preconditions

- Respect the current branch. Never switch branches during handoff.
- Pushing the handoff to the current branch's remote is expected behavior,
  not a merge to main. Do not conflate the two.
- Do not edit legacy Claude runtime files or instruction surfaces.
- Explicit invocation of `/handoff` authorizes this skill's declared handoff
  workflow without a second approval confirmation: update continuity files, stage
  relevant uncommitted changes by path, create the standard handoff commit, and
  push the current branch.
- Declared continuity files:
  `production/session-handoff.md`, `production/session-archive.md`, and
  `production/session-state/active.md`.
- Show the user the intended handoff label and concise update summary, then
  run the declared handoff workflow directly. Do not pause between the summary,
  continuity writes, commit, and push unless the work would leave the declared
  workflow.
- This authorization does not include making new source edits outside the
  continuity files, design decisions, game-feel/balance calls, writes outside
  declared continuity files, branch switching, force-pushes, or `--no-verify` /
  amend workarounds.
- Use evidence from the current turn for every status, count, and verification
  claim.
- If a command fails, halt the current phase and report the exact failure.

## Phase 0: Review Gate

Before writing the final handoff or committing, review all files created or
materially changed in this session.

1. Self-review each touched file for project rules, design gates, naming, test
   standards, and reporting integrity.
2. Run an appropriate review when available for substantial code, executable
   specs, cross-cutting docs, or milestone work. Use an adversarial/focused
   review only for major milestone deliverables or explicit user challenge
   language.
3. Triage findings:
   - Agree and confident to fix: fix now, then verify.
   - Agree but out of scope: record in the handoff Deferred section with the
     finding quoted.
   - Disagree, uncertain, or scope-changing: stop and surface to the user.
4. If fixes were applied, self-review the fix set. Run a second review only for
   high-severity findings or cross-cutting executable changes.
5. Cap review invocations at 3 unless the user explicitly approves more.

Proceed only when no finding is blocking on user input.

## Phase 1: Choose The Label

Use the user-provided argument as the handoff label. If none is provided, infer
a short noun phrase from the active work. If still ambiguous, use
`session-checkpoint`.

The standard commit subject is:

```text
WIP: <label> - CONTEXT HANDOFF
```

## Phase 2: Update Session State

Read these before editing when they exist:

- `production/session-handoff.md`
- `production/session-archive.md`
- `production/session-state/active.md`

Create `production/session-handoff.md` if it does not exist. Create
`production/session-archive.md` only when rotating a prior live session or when a
repo-local continuity rule requires it.

### Maintain The Slice Source Pointer

`production/session-handoff.md` is the contract consumed by
`/resume-from-handoff`. It must contain a project-specific pointer named:

```text
Playable/Slice State Source: <relative path or Not declared>
```

Do not hardcode a project path in this skill. Preserve the current value when it
is still supported by the files you read. Update it only when the user gives a
new path, an existing handoff/template already declares a better path, or the
current work created a clearly canonical playable-state document. If no source
is known, write `Playable/Slice State Source: Not declared`.

### Rotate The Prior Session

If `production/session-handoff.md` contains a `## Most Recent Session` entry,
move that prior session block to the top of `production/session-archive.md`
under `## Session Narratives`. Preserve the moved prose verbatim.

### Write The New Live Handoff

Update only the live sections that changed:

- Last updated pointer.
- Current Stage / Next Action.
- `Playable/Slice State Source`.
- Tracked Open Items.
- Director Gates / Architecture Registry / Systems Index when changed.
- Key Decisions Summary, appending durable decisions only.
- `## Most Recent Session`, with trigger, work completed, files touched,
  decisions, blockers, review outcome, deferred items, and next action.

If approved content exists only in conversation, stop and surface it. Do not hide
an approved-but-unpersisted state.

### Size Check

Run:

```bash
wc -c production/session-handoff.md
```

If the live handoff is over 25 KB, investigate rotation or bloated live sections
before continuing.

## Phase 2.5: Refresh Local Scratchpad

Overwrite `production/session-state/active.md` with a short pointer stub to
`production/session-handoff.md`. It is gitignored scratch state in many
projects; keep it coherent but do not stage it unless the repo explicitly tracks
it.

## Phase 3: Commit Handoff

Run:

```bash
git status --short
git diff
git log -5 --oneline
```

If there are no relevant uncommitted changes, skip the commit and say why.

Otherwise stage only the relevant paths by name. Avoid broad staging unless the
user explicitly asked for it. `/handoff` invocation is commit authorization for
the relevant handoff work. Before committing, verify:

```bash
git diff --cached --name-status
```

Commit with the standard handoff subject.

Never use `--no-verify`. Never amend as a workaround for a failed hook.

## Phase 4: Push Handoff

Determine the current branch:

```bash
git rev-parse --abbrev-ref HEAD
```

Push the handoff commit to the current branch's remote. This is a routine
backup of the handoff state — not a merge decision and not a push to main.
Explicit `/handoff` invocation is normal push authorization for the standard
handoff commit.

- If the branch has an upstream: `git push`
- If the branch has no upstream: `git push -u origin <branch>`

Never force-push. If the push fails (auth, network, rejected), report it and
continue to Phase 5 — the handoff is valid locally regardless.

Pushing to a feature or test branch is expected handoff behavior. Only
hesitate if the current branch is `main`, `master`, or `develop` — in that
case, ask the user before pushing.

## Phase 5: Report And Stop

Report in 15 lines or fewer:

- Label.
- Branch.
- Commit, or why commit was skipped.
- Push result, or why push was skipped.
- Handoff doc next action.
- Playable/slice source path, or `Not declared`.
- Open blockers or deferred items.

After reporting, stop. Do not start new feature work in the same turn.
