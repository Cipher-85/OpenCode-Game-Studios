# producer Memory Contract

This file preserves the upstream `project` memory scope as repo-local role
guidance for OpenCode Game Studios. It is not copied historical memory.

The `producer` subagent must read this file before role work and use it to
track durable preferences, project rulings, canonical paths, review gates, and
recurring constraints relevant to its role.

Do not write global memories from installer, hook, or generated runtime code.
User-controlled global memories remain optional and out of scope for this repo.

## Durable Notes

- Add role-specific decisions here as the project evolves.
- Prefer shared neutral project paths for game state and OpenCode-owned paths
  for runtime state.
