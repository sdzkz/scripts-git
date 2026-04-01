#!/bin/zsh

gh_user=$(git config user.name)

visibility="--private"
for arg in "$@"; do
  case "$arg" in
    --public) visibility="--public" ;;
    --existing) ;; # handled below
  esac
done

if [[ " $* " == *" --existing "* ]]; then
  gh auth switch --user "$gh_user"
  all_repos=("${(@f)$(gh repo list "$gh_user" --limit 1000 --json name -q '[.[].name] | sort | .[]')}")
  read "search?Search: "
  repos=()
  for repo in "${all_repos[@]}"; do
    if [[ -z "$search" || "${repo:l}" == *"${search:l}"* ]]; then
      repos+=("$repo")
    fi
  done

  echo "\nRepos:"
  if [[ ${#repos[@]} -eq 0 ]]; then
    echo "  No repos matched \"$search\""
    exit 1
  fi
  for i in {1..${#repos[@]}}; do
    echo "  $i) ${repos[$i]}"
  done
  echo ""
  read "choice?> "
  repo_name="${repos[$choice]}"
  echo "Connecting to ${gh_user}/${repo_name}"
  read "confirm?Confirm? (y/n) "
  [[ "$confirm" != "y" ]] && exit 0

  git remote remove origin 2>/dev/null
  git remote add origin "https://github.com/${gh_user}/${repo_name}.git"
  git push -u origin main
else
  read "repo_name?Repo name: "
  local label=${visibility#--}
  echo "Creating ${label} repo ${gh_user}/${repo_name}"
  read "confirm?Confirm? (y/n) "
  [[ "$confirm" != "y" ]] && exit 0

  gh auth switch --user "$gh_user"
  gh repo create "${gh_user}/${repo_name}" --source=. $visibility --push
fi
