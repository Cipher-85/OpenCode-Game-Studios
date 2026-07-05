---
name: studio-next
description: "Lightweight OpenCode Game Studios continuity router. Reads handoff, session, sprint, stage, workflow, and slice state to recommend the single best next action after a work unit."
---

# Studio Next

Use this skill when the user asks what to do next after finishing work, after a
resume briefing, at the end of a skill, or when the project has multiple plausible
lanes. This is the continuity brain, not a full audit.

This skill is read-only. It never writes files, runs mutating commands, commits,
pushes, edits hooks, launches builds, or emits hook output.

## Relationship To Nearby Skills

- `/help` remains the phase router. It reads the workflow catalog and identifies
  the first required phase step.
- `/project-stage-detect` remains the full artifact audit.
- `/resume-from-handoff` remains the deep session-entry reader when a canonical
  handoff exists.
- `/story-done` remains the story closure verifier.
- `producer` remains an escalation path for scope, milestone, production
  planning, and cross-discipline coordination. Do not make producer always-on.
- `/studio-next` reads the same state and chooses the best next action for
  continuity after a discrete unit of work.

## Step 1: Load Lightweight State

Read any of these files that exist. Missing files are `unset`; do not create
them.

1. `production/session-handoff.md`
2. `production/session-state/active.md`
3. `production/sprint-status.yaml`
4. `production/stage.txt`
5. `.opencode/docs/workflow-catalog.yaml`
6. `src/README.md`
7. `production/qa/smoke-*.md` and `production/qa/qa-signoff-*.md`, latest only
8. `.opencode/skills/*/SKILL.md`, frontmatter names only, to know which routed
   commands are installed

Use lightweight git reads only when useful:

```bash
git status --short
git branch --show-current
```

Do not run any command that changes the working tree, launches a build, commits,
pushes, or touches remote services.

## Step 2: Apply The Vertical-Slice Forcing Function

Before recommending work, answer these four points from `src/README.md`,
handoff state, or session state. Label unverified claims as reported by the file
that supplied them.

1. Current slice version and what is real versus stubbed.
2. Last clean boot or playtest claim, including whether it was verified in this
   turn.
3. Smallest next playable advance, no larger than one focused session.
4. Classification for each viable lane:
   - `extend`: directly makes the playable slice larger or more complete.
   - `feed`: supplies required design, art, QA, or architecture input for the
     slice.
   - `carve-out`: useful but not on the slice path.

The smallest playable advance overrides generic process work unless a gate,
blocker, or owed verification makes process work the necessary next action.

## Step 3: Build Candidate Lanes

Collect up to five plausible lanes from the loaded state:

- Handoff next action or active session next pointer.
- Ready or in-progress sprint stories from `production/sprint-status.yaml`.
- Owed verification, such as `/code-review`, `/story-done`, `/smoke-check`,
  `/team-qa`, or a missing test run.
- Phase next step from `.opencode/docs/workflow-catalog.yaml`.
- Gate or production planning work, such as `/gate-check` or producer escalation.
- Handoff preservation when session state has meaningful new context and
  `/handoff` is installed.

Route using installed commands when possible:

- Story not yet validated: `/story-readiness [story-path]`
- Story ready for implementation: `/dev-story [story-path]`
- Implementation finished but unreviewed: `/code-review [files] [story-path]`
- Reviewed implementation not closed: `/story-done [story-path]`
- Sprint stories complete but not smoke checked: `/smoke-check sprint`
- Smoke passed but QA not signed off: `/team-qa sprint`
- Phase advancement question: `/gate-check [target-phase]`
- Phase uncertainty or large artifact gap: `/project-stage-detect`
- Session preservation: `/handoff [short-label]` when installed
- Scope, milestone, or cross-discipline ambiguity: escalate to `producer`

If a routed command is not installed, recommend the closest installed command and
state the missing command plainly.

## Step 4: Rank And Choose One Best Action

Rank candidates in this order:

1. Blocking owed verification from just-finished work.
2. Smallest next playable advance on the vertical slice.
3. Current in-progress story or section.
4. Next ready Must Have sprint story.
5. Required workflow-catalog step for the current phase.
6. Handoff preservation if session state should be durable.
7. Optional hygiene or carve-out work.

Recommend exactly one best next action. Include:

- Command to run.
- Why this is the best next action now.
- Slice classification (`extend`, `feed`, or `carve-out`).
- Any prerequisite owed check.
- Whether the recommendation is based on verified state or file-reported state.

## Step 5: Use Structured Choice Only When Needed

If there is one clear best action, output it and stop. Do not ask an unnecessary
choice question.

If there are genuinely 2-3 viable lanes with similar priority, use the `question`
tool when available:

- Header: `Next work`
- Question: `Which lane should we take next?`
- Options: 2-3 mutually exclusive lanes
- Put the recommended lane first and append `(Recommended)` to its label
- Each option description must include command, reason, slice classification,
  and rough size in sessions

If the `question` tool is unavailable, fall back to a concise numbered prompt
with the same 2-3 options.

Do not use a broad "what do you want to do?" ending. The output must either
recommend one action or offer a small structured lane choice.

## Output Shape

```text
## Studio Next

State read: <files used, with missing files omitted>
Slice: <version or unset> | Last clean boot/playtest: <verified/reported/unset>

Best next action:
- <command> - <why this is next> [extend/feed/carve-out, <verified/reported>]

Owed before starting:
- <checks or "None">

Why not the other lanes:
- <short note only when another lane looked plausible>
```

When multiple lanes are viable, add the structured choice immediately after this
briefing.

## Continuity Epilogue Pattern

At the end of any discrete work unit, mentally apply this same check even when
the user did not invoke `/studio-next` explicitly:

1. Summarize what completed.
2. Surface owed verification.
3. Recommend the single best next action.
4. Suggest `/handoff` when session state should be preserved.
