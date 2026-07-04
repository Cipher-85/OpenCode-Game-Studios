# AGENTS.local.md Template

OpenCode does not auto-load a `.local` variant of `AGENTS.md` the way Claude
Code loaded `CLAUDE.local.md`. To get the same effect, copy this template to the
project root as `AGENTS.local.md`, then add it to the `instructions` array in
your **local** `opencode.json` (which is gitignored).

This file is gitignored and will not be committed.

```markdown
# Personal Preferences

## Model Preferences
- Prefer a stronger model for complex design tasks
- Use a faster model for quick lookups and simple edits

## Workflow Preferences
- Always run tests after code changes
- Compact context proactively at 60% usage

## Local Environment
- Python command: python (or py / python3)
- Shell: zsh on macOS

## Communication Style
- Keep responses concise
- Show file paths in all code references
- Explain architectural decisions briefly

## Personal Shortcuts
- When I say "review", run /code-review on the last changed files
- When I say "status", show git status + sprint progress
```

## Setup

1. Copy this template to your project root:
   ```bash
   cp .opencode/docs/AGENTS-local-template.md AGENTS.local.md
   ```
2. Edit `AGENTS.local.md` to match your preferences.
3. Add it to the `instructions` array in your local `opencode.json`:
   ```json
   {
     "instructions": [
       ".opencode/docs/directory-structure.md",
       "AGENTS.local.md"
     ]
   }
   ```
4. Verify `AGENTS.local.md` is in `.gitignore` (it is by default).

> **Alternative:** for global personal overrides across all projects, use
> `~/.config/opencode/opencode.json` — the `instructions` array there is
> merged into every project.
