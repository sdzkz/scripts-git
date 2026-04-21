#!/usr/bin/env zsh

emulate -L zsh
setopt errexit nounset pipefail

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "Error: not inside a git repository" >&2
  exit 1
fi

repo_user=$(git config --local --get user.name 2>/dev/null || true)
if [[ -z "$repo_user" ]]; then
  echo "Error: local git user.name is not set for this repository" >&2
  exit 1
fi

gh_user=$(gh auth status --active --hostname github.com --json hosts --jq '.hosts["github.com"][0].login' 2>/dev/null || true)
if [[ -z "$gh_user" || "$gh_user" == "null" ]]; then
  echo "Error: could not determine the active GitHub CLI user" >&2
  exit 1
fi

if [[ "$gh_user" != "$repo_user" ]]; then
  gh auth switch --user "$repo_user"
fi

git push "$@"
