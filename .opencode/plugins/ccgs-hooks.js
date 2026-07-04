/**
 * CCGS Hooks Plugin — OpenCode events → Claude-shaped shell scripts.
 *
 * Each OpenCode event delegates to the preserved shell script in .opencode/hooks/,
 * building a Claude-shaped stdin JSON so the scripts stay nearly unchanged.
 *
 * Event map (see PORTING_NOTES.md §5):
 *   session.created                  → session-start.sh, detect-gaps.sh
 *   tool.execute.before (bash)       → validate-commit.sh, validate-push.sh
 *   tool.execute.before (task)       → log-agent.sh           (SubagentStart emulation)
 *   tool.execute.after (write/edit)  → validate-assets.sh, validate-skill-change.sh
 *   tool.execute.after (task)        → log-agent-stop.sh      (SubagentStop emulation)
 *   experimental.session.compacting  → pre-compact.sh         (injects output.context[])
 *   session.compacted                → post-compact.sh
 *   session.idle                     → session-stop.sh
 *
 * Exit semantics:
 *   advisory scripts (exit 0)  → run silently, side-effects only
 *   blocking scripts (exit 1/2)→ throw to abort the tool call
 */

export const CCGSHooks = async ({ project, client, $, directory, worktree }) => {
  const cwd = worktree || directory

  /**
   * Run a hook script, piping Claude-shaped JSON to its stdin.
   * Returns { exitCode, stdout, stderr }.
   */
  async function runScript(script, stdinData) {
    const input = stdinData ? JSON.stringify(stdinData) : "{}"
    let cmd = $`printf '%s' ${input} | bash .opencode/hooks/${script}`.nothrow().quiet()
    // .cwd() is supported on Bun's $ shell; guard in case of version differences
    if (typeof cmd.cwd === "function") cmd = cmd.cwd(cwd)
    const result = await cmd
    return {
      exitCode: result.exitCode ?? 0,
      stdout: String(result.stdout ?? ""),
      stderr: String(result.stderr ?? ""),
    }
  }

  /** Blocking helper: throw if the script exited with a non-zero blocking code. */
  function blockIfFailed(result, codes = [1, 2]) {
    if (codes.includes(result.exitCode)) {
      const msg = (result.stderr || result.stdout || "").trim()
      throw new Error(msg || "Hook blocked this operation.")
    }
  }

  /** Best-effort advisory log. */
  async function advise(result) {
    const out = (result.stderr || result.stdout || "").trim()
    if (out) {
      try {
        await client.app.log({ body: { service: "ccgs-hooks", level: "info", message: out } })
      } catch (_) { /* logging is best-effort */ }
    }
  }

  return {
    // ── SessionStart emulation ──────────────────────────────────────────
    "session.created": async () => {
      const r1 = await runScript("session-start.sh")
      const r2 = await runScript("detect-gaps.sh")
      // session.created has no conversation-injection mechanism (documented gap);
      // scripts run for side-effects + we log advisory output.
      await advise(r1)
      await advise(r2)
    },

    // ── PreToolUse emulation ────────────────────────────────────────────
    "tool.execute.before": async (input, output) => {
      if (input.tool === "bash") {
        const command = output.args?.command ?? ""
        // validate-commit.sh — exit 2 = block
        const r1 = await runScript("validate-commit.sh", {
          tool_name: "Bash",
          tool_input: { command },
        })
        if (r1.exitCode !== 0) {
          await advise(r1)
          blockIfFailed(r1, [2])
        }
        // validate-push.sh — exit 2 = block (currently advisory upstream)
        const r2 = await runScript("validate-push.sh", {
          tool_name: "Bash",
          tool_input: { command },
        })
        if (r2.exitCode !== 0) await advise(r2)
        blockIfFailed(r2, [2])
      }

      // SubagentStart emulation via task tool
      if (input.tool === "task") {
        const agentType =
          output.args?.subagent_type || output.args?.type || "unknown"
        await runScript("log-agent.sh", { agent_type: agentType })
      }
    },

    // ── PostToolUse emulation ───────────────────────────────────────────
    "tool.execute.after": async (input, output) => {
      if (["write", "edit", "apply_patch"].includes(input.tool)) {
        // Extract file path(s); apply_patch may touch multiple files
        let paths = []
        if (input.tool === "apply_patch") {
          const patch = output.args?.patch || output.args?.diff || ""
          const re = /^[+-]{3}\s+(.*)$/gm
          let m
          while ((m = re.exec(patch)) !== null) {
            const p = m[1].trim()
            if (p && p !== "/dev/null") paths.push(p)
          }
        }
        if (paths.length === 0 && output.args?.filePath) {
          paths = [output.args.filePath]
        }
        if (paths.length === 0 && output.args?.file_path) {
          paths = [output.args.file_path]
        }

        for (const filePath of paths) {
          // validate-assets.sh — exit 1 = block (upstream uses exit 1, not 2)
          const r1 = await runScript("validate-assets.sh", {
            tool_name: "Write",
            tool_input: { file_path: filePath },
          })
          if (r1.exitCode !== 0) {
            await advise(r1)
            blockIfFailed(r1, [1])
          }
          // validate-skill-change.sh — advisory only
          const r2 = await runScript("validate-skill-change.sh", {
            tool_name: "Write",
            tool_input: { file_path: filePath },
          })
          await advise(r2)
        }
      }

      // SubagentStop emulation via task tool
      if (input.tool === "task") {
        const agentType =
          output.args?.subagent_type || output.args?.type || "unknown"
        await runScript("log-agent-stop.sh", { agent_type: agentType })
      }
    },

    // ── PreCompact emulation ────────────────────────────────────────────
    "experimental.session.compacting": async (input, output) => {
      const r = await runScript("pre-compact.sh")
      if (r.stdout) {
        output.context.push(r.stdout)
      }
    },

    // ── PostCompact emulation ───────────────────────────────────────────
    "session.compacted": async () => {
      const r = await runScript("post-compact.sh")
      await advise(r)
    },

    // ── Stop emulation ──────────────────────────────────────────────────
    "session.idle": async () => {
      await runScript("session-stop.sh")
    },
  }
}
