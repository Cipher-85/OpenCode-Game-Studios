#!/usr/bin/env bash
# release.sh — OpenCode Game Studios release tool
#
# Usage:
#   bash .opencode/release.sh current                  # print current version
#   bash .opencode/release.sh bump patch|minor|major   # bump version
#   bash .opencode/release.sh check                    # validate release readiness
#   bash .opencode/release.sh publish [--dry-run]      # create GitHub release
set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
root="$(cd "$script_dir/.." && pwd -P)"
version_file="$script_dir/VERSION"
changelog="$root/CHANGELOG.md"
tag_prefix="opencode-v"

get_current_version() {
  cat "$version_file"
}

get_latest_tag() {
  git -C "$root" tag -l "${tag_prefix}*" --sort=-v:refname 2>/dev/null | head -1
}

bump_version() {
  local current="$1" part="$2"
  local major minor patch
  IFS='.' read -r major minor patch <<< "$current"
  case "$part" in
    major) major=$((major + 1)); minor=0; patch=0 ;;
    minor) minor=$((minor + 1)); patch=0 ;;
    patch) patch=$((patch + 1)) ;;
    *) printf 'Invalid bump type: %s\n' "$part" >&2; exit 2 ;;
  esac
  printf '%d.%d.%d\n' "$major" "$minor" "$patch"
}

cmd_current() {
  printf '%s\n' "$(get_current_version)"
}

cmd_bump() {
  local part="${1:-}"
  [ -z "$part" ] && { printf 'Usage: release.sh bump patch|minor|major|X.Y.Z\n' >&2; exit 2; }

  local current new_version
  current="$(get_current_version)"

  if echo "$part" | grep -qE '^[0-]+\.[0-]+\.[0-]+$'; then
    new_version="$part"
  else
    new_version="$(bump_version "$current" "$part")"
  fi

  printf '%s\n' "$new_version" > "$version_file"
  printf 'Version: %s → %s\n' "$current" "$new_version"
  printf 'Update CHANGELOG.md with a new ## v%s section.\n' "$new_version"
}

cmd_check() {
  local errors=0
  local version current_tag

  version="$(get_current_version)"
  current_tag="${tag_prefix}${version}"

  printf '── Release Check ──\n'
  printf 'Version: %s\n' "$version"
  printf 'Expected tag: %s\n' "$current_tag"

  # Check CHANGELOG has the section
  if rg -q "^## v${version}" "$changelog" 2>/dev/null; then
    printf '  ✓ CHANGELOG has v%s section\n' "$version"
  else
    printf '  ✗ CHANGELOG missing v%s section\n' "$version" >&2
    errors=$((errors + 1))
  fi

  # Check clean worktree
  if git -C "$root" diff --quiet 2>/dev/null && git -C "$root" diff --cached --quiet 2>/dev/null; then
    printf '  ✓ Clean worktree\n'
  else
    printf '  ✗ Uncommitted changes\n' >&2
    errors=$((errors + 1))
  fi

  # Check no foreign-runtime files staged or tracked
  local foreign=0
  for pattern in '.claude/' 'CLAUDE.md' '.codex/' '.agents/skills/'; do
    if git -C "$root" ls-files --cached -z 2>/dev/null | grep -qz "$pattern"; then
      printf '  ✗ Foreign-runtime file tracked: %s\n' "$pattern" >&2
      foreign=1
    fi
  done
  [ "$foreign" -eq 0 ] && printf '  ✓ No foreign-runtime files tracked\n' || errors=$((errors + 1))

  # Validate manifest freshness: count should match actual files
  local manifest_count actual_count
  manifest_count=$(python3 -c "
import json
with open('$root/.opencode/manifest/installed-files.json') as f:
    print(len(json.load(f).get('files', [])))
" 2>/dev/null || echo 0)
  actual_count=$(find "$root" -type f \
    -not -path '*/.git/*' -not -path '*/node_modules/*' -not -path '*.app/*' \
    -not -name '.DS_Store' -not -path '*/.opencode/node_modules/*' \
    -not -path '*/.opencode/package*' -not -path '*/.opencode/backups/*' \
    -not -path '*/.opencode/install-state.json' \
    -not -name 'oc-vs-codex.md' -not -name 'opencode-plan.md' \
    2>/dev/null | wc -l | tr -d ' ')
  if [ "$manifest_count" -eq "$actual_count" ]; then
    printf '  ✓ Manifest fresh (%s files)\n' "$manifest_count"
  else
    printf '  ⚠ Manifest may be stale: manifest=%s, actual=%s\n' "$manifest_count" "$actual_count" >&2
  fi

  # Check gh auth
  if command -v gh >/dev/null 2>&1 && gh auth status >/dev/null 2>&1; then
    printf '  ✓ gh authenticated\n'
  else
    printf '  ⚠ gh not authenticated (required for publish)\n'
  fi

  # Run audit
  printf '\nRunning audit...\n'
  bash "$script_dir/audit.sh" all || errors=$((errors + 1))

  printf '\n── Result: %d error(s) ──\n' "$errors"
  [ "$errors" -eq 0 ]
}

cmd_publish() {
  local dry_run=0
  [ "${1:-}" = "--dry-run" ] && dry_run=1

  local version current_tag latest_tag
  version="$(get_current_version)"
  current_tag="${tag_prefix}${version}"
  latest_tag="$(get_latest_tag)"

  printf '── Publish ──\n'
  printf 'Version: %s\n' "$version"
  printf 'Tag: %s\n' "$current_tag"

  # Check tag doesn't exist (or matches)
  if git -C "$root" rev-parse "$current_tag" >/dev/null 2>&1; then
    printf '  Tag %s already exists\n' "$current_tag"
  else
    printf '  Tag %s is new\n' "$current_tag"
  fi

  if [ "$dry_run" -eq 1 ]; then
    printf '\nDRY RUN — would create tag %s and GitHub release\n' "$current_tag"
    exit 0
  fi

  # Require clean worktree
  if ! git -C "$root" diff --quiet 2>/dev/null || ! git -C "$root" diff --cached --quiet 2>/dev/null; then
    printf 'ERROR: uncommitted changes. Commit first.\n' >&2
    exit 1
  fi

  # Extract release notes from CHANGELOG
  local notes
  notes="$(python3 -c "
import sys
with open('$changelog') as f:
    txt = f.read()
import re
m = re.search(r'^## v${version}.*?(?=\n^## v|\Z)', txt, re.S | re.M)
if m:
    print(m.group(0))
else:
    print(f'Release {\"$version\"}')
" 2>/dev/null)"

  printf 'Creating tag %s...\n' "$current_tag"
  git -C "$root" tag -a "$current_tag" -m "OpenCode Game Studios v$version"

  printf 'Pushing tag...\n'
  git -C "$root" push origin "$current_tag"

  printf 'Creating GitHub release...\n'
  printf '%s\n' "$notes" | gh release create "$current_tag" \
    --repo "$(git -C "$root" remote get-url origin | sed 's/.*github.com[:/]\(.*\)\.git/\1/;s/.*github.com[:/]\(.*\)/\1/')" \
    --title "OpenCode Game Studios v$version" \
    --notes-file - \
    --latest 2>&1 || true

  printf '\nDone. Release %s created.\n' "$current_tag"
}

# ── Main ──
case "${1:-current}" in
  current) cmd_current ;;
  bump)    shift; cmd_bump "$@" ;;
  check)   cmd_check ;;
  publish) shift; cmd_publish "$@" ;;
  -h|--help)
    printf 'OpenCode Game Studios release tool\n\n'
    printf 'Commands:\n'
    printf '  current              Print current version\n'
    printf '  bump patch|minor|major|X.Y.Z   Bump version\n'
    printf '  check                Validate release readiness\n'
    printf '  publish [--dry-run]  Create tag + GitHub release\n'
    ;;
  *) printf 'Unknown command: %s\n' "$1" >&2; exit 2 ;;
esac
