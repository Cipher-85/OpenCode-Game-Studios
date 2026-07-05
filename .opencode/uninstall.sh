#!/usr/bin/env bash
# uninstall.sh — Remove OpenCode Game Studios model configuration
#
# Restores model-agnostic state: strips injected model: fields from agents,
# removes primary model from opencode.json, removes models.json and install-state.json.
#
# Usage:
#   bash .opencode/uninstall.sh                # restore model-agnostic state
#   bash .opencode/uninstall.sh --dry-run      # preview only
#   bash .opencode/uninstall.sh /path/to/target
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "$script_dir/lib/models.sh"

dry_run=0
target_arg=""

while [ "$#" -gt 0 ]; do
  case "$1" in
    --dry-run) dry_run=1; shift ;;
    -*) printf 'uninstall: unknown option: %s\n' "$1" >&2; exit 2 ;;
    *) target_arg="$1"; shift ;;
  esac
done

target_root="$(cd "${target_arg:-$PWD}" && pwd -P)"

printf '── OpenCode Game Studios Uninstall ──\n\n'

if [ "$dry_run" -eq 1 ]; then
  printf 'DRY RUN — no changes will be made.\n\n'
  printf 'Would:\n'
  printf '  - Strip model: from all 49 agent files\n'
  printf '  - Remove model from opencode.json\n'
  printf '  - Remove .opencode/models.json\n'
  printf '  - Remove .opencode/install-state.json\n'
  exit 0
fi

# Strip models from agents
printf 'Stripping model configuration from agents...\n'
ccgs_strip_all_agents "$target_root"

# Remove primary model from opencode.json
printf 'Removing primary model from opencode.json...\n'
ccgs_remove_primary_model "$target_root"

# Remove generated files
for f in .opencode/models.json .opencode/install-state.json; do
  if [ -f "$target_root/$f" ]; then
    rm "$target_root/$f"
    printf '  Removed %s\n' "$f"
  fi
done

printf '\nDone. All agents restored to model-agnostic state.\n'
