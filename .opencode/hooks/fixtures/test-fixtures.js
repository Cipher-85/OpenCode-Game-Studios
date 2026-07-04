/**
 * Hook Fixture Tests (Stage 1 — static payload shape verification).
 *
 * Verifies that the Claude-shaped JSON the adapter builds for each script
 * matches the documented shape. This does NOT test live OpenCode events —
 * that is Stage 2 (runtime capture).
 *
 * Run:  bun test-fixtures.js    (or: node test-fixtures.js)
 */

const assert = require("assert")

// ── Simulate the adapter's stdin normalization logic ──────────────────

function buildStdinForScript(script, openCodePayload) {
  // Replicates the logic in ccgs-hooks.js runScript() calls
  switch (script) {
    case "session-start.sh":
    case "detect-gaps.sh":
    case "pre-compact.sh":
    case "post-compact.sh":
    case "session-stop.sh":
      return {}
    case "validate-commit.sh":
    case "validate-push.sh":
      return {
        tool_name: "Bash",
        tool_input: { command: openCodePayload.command ?? "" },
      }
    case "validate-assets.sh":
    case "validate-skill-change.sh":
      return {
        tool_name: "Write",
        tool_input: { file_path: openCodePayload.filePath ?? "" },
      }
    case "log-agent.sh":
    case "log-agent-stop.sh":
      return {
        agent_type: openCodePayload.subagent_type ?? "unknown",
      }
    default:
      throw new Error(`Unknown script: ${script}`)
  }
}

function extractApplyPatchPaths(patchText) {
  const paths = []
  const re = /^[+-]{3}\s+(.*)$/gm
  let m
  while ((m = re.exec(patchText)) !== null) {
    const p = m[1].trim()
    if (p && p !== "/dev/null") paths.push(p)
  }
  return paths
}

// ── Tests ──────────────────────────────────────────────────────────────

let passed = 0, failed = 0
function test(name, fn) {
  try { fn(); passed++; console.log(`  ✓ ${name}`) }
  catch (e) { failed++; console.error(`  ✗ ${name}\n    ${e.message}`) }
}

console.log("Stage 1 — Static Payload Fixture Tests\n")

test("session-start.sh receives empty object", () => {
  const stdin = buildStdinForScript("session-start.sh", {})
  assert.deepStrictEqual(stdin, {})
})

test("detect-gaps.sh receives empty object", () => {
  const stdin = buildStdinForScript("detect-gaps.sh", {})
  assert.deepStrictEqual(stdin, {})
})

test("validate-commit.sh receives tool_input.command from bash args", () => {
  const stdin = buildStdinForScript("validate-commit.sh", {
    command: "git commit -m 'feat: add combat'",
  })
  assert.strictEqual(stdin.tool_name, "Bash")
  assert.strictEqual(stdin.tool_input.command, "git commit -m 'feat: add combat'")
})

test("validate-push.sh receives tool_input.command", () => {
  const stdin = buildStdinForScript("validate-push.sh", {
    command: "git push origin main",
  })
  assert.strictEqual(stdin.tool_input.command, "git push origin main")
})

test("validate-assets.sh receives tool_input.file_path from write args", () => {
  const stdin = buildStdinForScript("validate-assets.sh", {
    filePath: "assets/data/items.json",
  })
  assert.strictEqual(stdin.tool_name, "Write")
  assert.strictEqual(stdin.tool_input.file_path, "assets/data/items.json")
})

test("validate-skill-change.sh receives tool_input.file_path", () => {
  const stdin = buildStdinForScript("validate-skill-change.sh", {
    filePath: ".opencode/skills/start/SKILL.md",
  })
  assert.strictEqual(stdin.tool_input.file_path, ".opencode/skills/start/SKILL.md")
})

test("log-agent.sh receives agent_type from task subagent_type", () => {
  const stdin = buildStdinForScript("log-agent.sh", { subagent_type: "game-designer" })
  assert.strictEqual(stdin.agent_type, "game-designer")
})

test("log-agent.sh defaults agent_type to unknown when missing", () => {
  const stdin = buildStdinForScript("log-agent.sh", {})
  assert.strictEqual(stdin.agent_type, "unknown")
})

test("apply_patch path extraction parses --- and +++ headers", () => {
  const patch = [
    "--- a/src/foo.gd",
    "+++ b/src/foo.gd",
    "@@ -1,3 +1,3 @@",
    " old line",
    "+new line",
    "--- /dev/null",
    "+++ b/src/new.gd",
  ].join("\n")
  const paths = extractApplyPatchPaths(patch)
  assert.ok(paths.includes("b/src/foo.gd"))
  assert.ok(paths.includes("b/src/new.gd"))
  assert.ok(!paths.includes("/dev/null"))
})

test("pre-compact.sh receives empty object", () => {
  assert.deepStrictEqual(buildStdinForScript("pre-compact.sh", {}), {})
})

test("session-stop.sh receives empty object", () => {
  assert.deepStrictEqual(buildStdinForScript("session-stop.sh", {}), {})
})

console.log(`\n${passed} passed, ${failed} failed`)
process.exit(failed > 0 ? 1 : 0)
