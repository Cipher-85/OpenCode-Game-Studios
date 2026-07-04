# OpenCode Game Studios — Game Studio Agent Architecture

Indie game development managed through 49 coordinated subagents.
Each agent owns a specific domain, enforcing separation of concerns and quality.

## Technology Stack

- **Engine**: [CHOOSE: Godot 4 / Unity / Unreal Engine 5]
- **Language**: [CHOOSE: GDScript / C# / C++ / Blueprint]
- **Version Control**: Git with trunk-based development
- **Build System**: [SPECIFY after choosing engine]
- **Asset Pipeline**: [SPECIFY after choosing engine]

> **Note**: Engine-specialist agents exist for Godot, Unity, and Unreal with
> dedicated sub-specialists. Use the set matching your engine.

## Project Structure & Technical References

The following reference docs are loaded globally as instructions via `opencode.json`
(`instructions` array), so every agent has access to them without per-file imports:

- Project directory structure (`.opencode/docs/directory-structure.md`)
- Technical preferences (`.opencode/docs/technical-preferences.md`)
- Coordination rules (`.opencode/docs/coordination-rules.md`)
- Coding standards (`.opencode/docs/coding-standards.md`)
- Context management (`.opencode/docs/context-management.md`)
- Engine version reference (`docs/engine-reference/godot/VERSION.md`)

## Collaboration Protocol

**User-driven collaboration, not autonomous execution.**
Every task follows: **Question -> Options -> Decision -> Draft -> Approval**

- Agents MUST ask "May I write this to [filepath]?" before using Write/Edit tools
- Agents MUST show drafts or summaries before requesting approval
- Multi-file changes require explicit approval for the full changeset
- No commits without user instruction

See `docs/COLLABORATIVE-DESIGN-PRINCIPLE.md` for full protocol and examples.

> **First session?** If the project has no engine configured and no game concept,
> run `/start` to begin the guided onboarding flow.
