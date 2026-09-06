#!/bin/sh

set -eu

repo_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd -P)

check_commit() {
  commit=$1
  # Older history predates the translation contract.
  if ! git -C "$repo_root" cat-file -e "$commit:docs/AGENTS.ko.md" 2>/dev/null; then
    parent_tree=$(git -C "$repo_root" rev-parse "$commit^" 2>/dev/null || true)
    if [ -z "$parent_tree" ] || ! git -C "$repo_root" cat-file -e "$parent_tree:docs/AGENTS.ko.md" 2>/dev/null; then
      return 0
    fi
  fi
  parent=$(git -C "$repo_root" rev-list --parents -n 1 "$commit")
  case "$parent" in
    *' '*)
      parent=${parent#* }
      parent=${parent%% *}
      changed=$(git -C "$repo_root" diff --name-only "$parent" "$commit" -- AGENTS.md docs/AGENTS.ko.md)
      ;;
    *) changed=$(git -C "$repo_root" diff-tree --root --no-commit-id --name-only -r "$commit" -- AGENTS.md docs/AGENTS.ko.md) ;;
  esac
  agents=false
  korean=false
  for path in $changed; do
    case "$path" in
      AGENTS.md) agents=true ;;
      docs/AGENTS.ko.md) korean=true ;;
    esac
  done
  if [ "$agents" != "$korean" ]; then
    printf '[FAIL] commit %s: AGENTS.md and docs/AGENTS.ko.md must change together\n' "$commit" >&2
    return 1
  fi
}

# Git pre-push supplies every updated ref, including new branches and deletions.
while read -r local_ref local_oid remote_ref remote_oid; do
  case "$local_oid" in ''|*[!0]*) ;; *) continue ;; esac
  case "$remote_oid" in
    *[!0]*) commits=$(git -C "$repo_root" rev-list "$remote_oid..$local_oid") ;;
    *) commits=$(git -C "$repo_root" rev-list "$local_oid" --not --remotes) ;;
  esac
  for commit in $commits; do
    check_commit "$commit"
  done
done
