# Hook Payload Fixtures (Two-Stage Gate — Phase 5)

> **Stage 1 (static):** one fixture per hook event, asserting the `ccgs-hooks.js`
> adapter normalizes the OpenCode payload into the Claude-shaped JSON the shell
> scripts expect. Run `node test-fixtures.js` (or `bun test-fixtures.js`).
>
> **Stage 2 (runtime capture):** once running inside OpenCode, log the real
> `input`/`output` for each event and diff against the static fixture.
> **Event existence ≠ payload-shape parity** — this capture is mandatory.

## Expected Claude-shaped stdin per script

| Script | stdin JSON shape | Blocking exit codes |
|---|---|---|
| `session-start.sh` | `{}` (no stdin read) | — |
| `detect-gaps.sh` | `{}` (no stdin read) | — |
| `validate-commit.sh` | `{"tool_name":"Bash","tool_input":{"command":"git commit ..."}}` | 2 |
| `validate-push.sh` | `{"tool_name":"Bash","tool_input":{"command":"git push ..."}}` | 2 |
| `validate-assets.sh` | `{"tool_name":"Write","tool_input":{"file_path":"assets/data/foo.json"}}` | 1 |
| `validate-skill-change.sh` | `{"tool_name":"Write","tool_input":{"file_path":".opencode/skills/start/SKILL.md"}}` | — (advisory) |
| `pre-compact.sh` | `{}` (no stdin read) | — |
| `post-compact.sh` | `{}` (no stdin read) | — |
| `session-stop.sh` | `{}` (no stdin read) | — |
| `log-agent.sh` | `{"agent_type":"game-designer"}` | — |
| `log-agent-stop.sh` | `{"agent_type":"game-designer"}` | — |
| `notify.sh` | **dropped** (Windows-only upstream; OpenCode desktop auto-notifies) | — |

## OpenCode event → adapter normalization

| OpenCode event | `input.tool` | Adapter extracts | Feeds script as |
|---|---|---|---|
| `session.created` | — | — | runs session-start.sh + detect-gaps.sh (no stdin) |
| `tool.execute.before` | `bash` | `output.args.command` | `tool_input.command` |
| `tool.execute.before` | `task` | `output.args.subagent_type` | `agent_type` |
| `tool.execute.after` | `write` / `edit` | `output.args.filePath` | `tool_input.file_path` |
| `tool.execute.after` | `apply_patch` | parse `output.args.patch` paths | `tool_input.file_path` (per file) |
| `tool.execute.after` | `task` | `output.args.subagent_type` | `agent_type` |
| `experimental.session.compacting` | — | — | runs pre-compact.sh; stdout → `output.context[]` |
| `session.compacted` | — | — | runs post-compact.sh |
| `session.idle` | — | — | runs session-stop.sh |

## Stage 2 — Runtime capture checklist

For each event above, run a throwaway session that triggers it and verify:
1. The script receives the expected Claude-shaped JSON on stdin.
2. Advisory scripts (exit 0) do not block.
3. Blocking scripts (exit 1/2) cause `throw` in the adapter.
4. `pre-compact.sh` stdout appears in the compaction context.
