# Attribution

OpenCode Game Studios is an unofficial OpenCode-native port of
[Donchitos/Claude-Code-Game-Studios](https://github.com/Donchitos/Claude-Code-Game-Studios).

The port is pinned to upstream commit
`984023ddac0d5e27624f2baacde6105e45de375f` for mapping, attribution, and
verification evidence.

The upstream project is distributed under the MIT License. This source
distribution keeps the original license text and copyright notice in the root
`LICENSE` file.

This port is **truly model-agnostic** — unlike the upstream (hardcoded
`opus`/`sonnet`/`haiku`) and the Codex port (hardcoded `gpt-5.5`/`gpt-5.4`/
`gpt-5.4-mini`), no models are pre-built into the configuration. Users choose
their models per tier at install time via `.opencode/install.sh`.

Runtime coexistence constraints:

- OpenCode-owned files do not modify `.claude/`.
- OpenCode-owned files do not require or modify `CLAUDE.md`.
- Shared neutral project state remains available to both toolchains.
