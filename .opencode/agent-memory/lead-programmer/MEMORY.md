# Lead Programmer — Agent Memory

## Skill Authoring Conventions

### Frontmatter
- Fields: `name`, `description`, `argument-hint`, `user-invocable`, `allowed-tools`
- `agent:` delegates the skill to a named subagent (20 skills use this)
- ~~`context: fork`~~ — **DEAD CODE**: no skill uses `context: fork`; the `skill-test`
  linter check for it is a dead check, not a real schema field. Do not add it to new skills.
- `AskUserQuestion` is a usage pattern described in skill body text — it is NOT listed
  in `allowed-tools` frontmatter (no existing skill does this)

### File Layout
- Skills live in `.opencode/skills/<name>/SKILL.md` (subdirectory per skill, never flat .md)
- Section headers use `##` for phases, `###` for sub-sections
- Phase names follow "Phase N: Verb Noun" pattern (e.g., "Phase 1: Find the Story")
- Output format templates go in fenced code blocks

### Known Canonical Paths (verify before referencing in new skills)
- Tech debt register: `docs/tech-debt-register.md` (NOT `production/tech-debt.md`)
- Sprint files: `production/sprints/`
- Epic story files: `production/epics/[epic-slug]/story-[NNN]-[slug].md`
- Control manifest: `docs/architecture/control-manifest.md`
- Session state: `production/session-state/active.md`
- Systems index: `design/gdd/systems-index.md`
- Engine reference: `docs/engine-reference/[engine]/VERSION.md`

### Skills Completed
- `story-done` — end-of-story completion handshake (Phase 1-8, writes story file)
