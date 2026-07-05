#!/usr/bin/env bash
# uninstall.sh — Remove OpenCode Game Studios
#
# Coexistence-aware removal:
# - Strips model/variant from agents
# - Removes only OpenCode-owned files (preserves shared paths in coexistence mode)
# - Removes marker block from AGENTS.md (preserves user content)
# - Backs up modified files before removal
# - Cleans .gitignore allowlist
#
# Usage:
#   bash .opencode/uninstall.sh                # uninstall from current dir
#   bash .opencode/uninstall.sh --dry-run      # preview only
#   bash .opencode/uninstall.sh /path/to/target
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
source "$script_dir/lib/models.sh"
source "$script_dir/lib/coexistence.sh"

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
source_root="$(cd "$script_dir/.." && pwd -P)"

# ── Detect mode ──────────────────────────────────────────────────
install_mode="$(ccgs_detect_mode)"
printf '── OpenCode Game Studios Uninstall ──\n\n'
ccgs_print_mode_summary "$install_mode"

# ── Read install state for file list ─────────────────────────────
state_file="$target_root/.opencode/install-state.json"
manifest="$source_root/.opencode/manifest/installed-files.json"

# Get paths we created (from install state or manifest fallback)
paths_file="$(mktemp "${TMPDIR:-/tmp}/ccgs-uninstall-paths.XXXXXX")"
trap 'rm -f "$paths_file"' EXIT

if [ -f "$state_file" ]; then
  # Read file hashes from install-state (exact list of what we deployed)
  python3 -c "
import json, sys
with open('$state_file') as f:
    state = json.load(f)
for path in sorted(state.get('installed_file_hashes', {}).keys()):
    print(path)
" > "$paths_file" 2>/dev/null
elif [ -f "$manifest" ]; then
  # Fallback: use manifest
  python3 -c "
import json
with open('$manifest') as f:
    data = json.load(f)
for entry in data.get('files', []):
    print(entry['path'])
" > "$paths_file" 2>/dev/null
fi

if [ ! -s "$paths_file" ]; then
  printf 'No install state or manifest found — stripping models only.\n'
  # Still strip models + remove generated files
  if [ "$dry_run" -eq 0 ]; then
    ccgs_strip_all_agents "$target_root"
    ccgs_remove_primary_model "$target_root"
    for f in .opencode/models.json .opencode/install-state.json; do
      [ -f "$target_root/$f" ] && rm "$target_root/$f"
    done
  fi
  printf 'Done (models stripped, no file list to remove).\n'
  exit 0
fi

# ── Read shared-path tracking from install state ─────────────────
preserved_by_us=""
if [ -f "$state_file" ]; then
  preserved_by_us="$(python3 -c "
import json
with open('$state_file') as f:
    state = json.load(f)
for p in state.get('shared_paths_created', []):
    print(p)
" 2>/dev/null)"
fi

# ── Dry-run summary ──────────────────────────────────────────────
if [ "$dry_run" -eq 1 ]; then
  printf '\nDRY RUN — no changes will be made.\n\n'
  total=$(wc -l < "$paths_file" | tr -d ' ')
  printf 'Would process %s files:\n' "$total"
  printf '  - Strip model/variant from agents\n'
  printf '  - Remove OpenCode-owned files (preserve shared in coexistence)\n'
  printf '  - Remove marker block from AGENTS.md\n'
  printf '  - Clean .gitignore allowlist\n'
  printf '  - Remove install-state.json, models.json\n'
  exit 0
fi

# ── Strip models from agents ─────────────────────────────────────
printf '\nStripping model configuration from agents...\n'
ccgs_strip_all_agents "$target_root"

# ── Remove primary model from opencode.json ──────────────────────
printf 'Removing primary model from opencode.json...\n'
ccgs_remove_primary_model "$target_root"

# ── Remove deployed files (coexistence-aware) ────────────────────
printf 'Removing deployed files...\n'

is_coexist() {
  case "$install_mode" in
    claude_ccgs_coexist|codex_ccgs_coexist|multi_runtime) return 0 ;;
    *) return 1 ;;
  esac
}

# Check if we created this shared path (from install state)
we_created() {
  local path="$1"
  if [ -n "$preserved_by_us" ]; then
    echo "$preserved_by_us" | grep -qxF "$path"
    return $?
  fi
  return 1  # assume we didn't create it if no state
}

removed=0
preserved=0

# Process files in reverse order (deepest first for dir pruning)
while IFS= read -r path; do
  ccgs_refuse_foreign_path "$path"

  target_file="$target_root/$path"
  [ -e "$target_file" ] || continue

  # Coexistence: preserve shared paths we didn't create
  if is_coexist && ccgs_is_shared_path "$path" && ! we_created "$path"; then
    preserved=$((preserved + 1))
    continue
  fi

  case "$path" in
    AGENTS.md|*/AGENTS.md)
      # Remove marker block, preserve rest of file
      ccgs_remove_marker_block "$target_file" 2>/dev/null || true
      # If file is now empty or just a stub, remove it
      if [ -f "$target_file" ]; then
        local_content="$(tr -d '\n\r\t ' < "$target_file" 2>/dev/null || true)"
        [ -z "$local_content" ] && rm -f "$target_file"
      fi
      ;;
    opencode.json)
      # Don't remove opencode.json (user may have other config)
      ;;
    *)
      # Backup if modified from source before removal
      source_file="$source_root/$path"
      if [ -f "$source_file" ] && ! cmp -s "$source_file" "$target_file"; then
        ccgs_backup_file "$path" "$target_root"
      fi
      rm -f "$target_file"
      ;;
  esac
  removed=$((removed + 1))
done < <(sort -r "$paths_file")

printf '  Removed: %d | Preserved (shared): %d\n' "$removed" "$preserved"

# ── Remove generated files ───────────────────────────────────────
for f in .opencode/models.json .opencode/install-state.json; do
  if [ -f "$target_root/$f" ]; then
    rm "$target_root/$f"
    printf '  Removed %s\n' "$f"
  fi
done

# ── Clean .gitignore allowlist ───────────────────────────────────
ccgs_remove_gitignore_allowlist "$target_root" 2>/dev/null || true

# ── Prune empty OpenCode-owned directories ───────────────────────
if is_coexist; then
  # Only prune .opencode/ in coexistence mode (leave shared dirs alone)
  find "$target_root/.opencode" -depth -type d -empty -delete 2>/dev/null || true
else
  # Full prune of all framework dirs
  for dir in .opencode "CCGS Skill Testing Framework" assets design docs production prototypes src tests tools; do
    [ -d "$target_root/$dir" ] || continue
    find "$target_root/$dir" -depth -type d -empty -delete 2>/dev/null || true
  done
fi

printf '\nDone. OpenCode Game Studios removed.\n'
if [ "$preserved" -gt 0 ]; then
  printf '%d shared paths preserved (coexistence mode).\n' "$preserved"
fi
