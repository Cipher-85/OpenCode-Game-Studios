# Verification Integrity

Verification claims must describe evidence, not intent. A result is verified
only when the command or check ran in the current turn, or when the answer labels
the result as historical/file-reported and names the source.

## Hard Rules

- Do not say a build, test, lint, audit, smoke check, or playtest passed unless
  the result was observed.
- Do not convert "not run" into "passed" because the change was small.
- Do not treat CI badges, workflow names, or expected job behavior as logs.
- If a command fails because of environment, missing dependency, sandbox, or
  timeout, report that exact state and the owed command.
- If a check is skipped by design, say why it was skipped.

## Evidence Labels

Use precise labels in status reports:

- `verified this turn`: command/check was run and output inspected.
- `file-reported`: a repo file claims the result; not independently verified.
- `blocked`: could not run; include the blocker.
- `not run`: intentionally not run or out of scope.

## CI Read Handling

When using CI or hosted checks:

1. Open the concrete run, job, or log.
2. Confirm the status and the relevant failing/passing step.
3. Quote or summarize only the key line needed to support the claim.
4. If the run is queued, cancelled, expired, or inaccessible, report that state.

## Incident Examples

- Wrong: "Tests pass" after editing a test file but not running the suite.
- Right: "Tests not run; owed: `godot --headless --script tests/gdunit4_runner.gd`."
- Wrong: "CI is green" after seeing only a branch badge.
- Right: "CI file-reported green in `production/qa/...`; not verified this turn."

## Recovery Procedure

If a verification claim may be wrong:

1. Stop expanding scope.
2. Re-run or inspect the exact check if feasible.
3. Correct the status plainly in the next user-visible message.
4. Add the owed verification to the final response and continuity epilogue.
5. If the uncertainty affects implementation safety, recommend the verification
   as the next action before more feature work.
