#!/bin/zsh

gh_user=$(git config user.name)

choose_owner() {
  local account="$1"
  local use_org choice
  local -a orgs

  orgs=("${(@f)$(gh api user/orgs --jq '.[].login' 2>/dev/null | sort -u)}")
  selected_owner="$account"

  if (( ${#orgs[@]} == 0 )); then
    return
  fi

  echo ""
  read "use_org?Use org? (y/N) "
  case "${use_org:l}" in
    y|yes)
      if (( ${#orgs[@]} == 1 )); then
        selected_owner="${orgs[1]}"
        return
      fi
      ;;
    ""|n|no) return ;;
    *)
      echo "Invalid selection"
      exit 1
      ;;
  esac

  echo "Organizations:"
  for i in {1..${#orgs[@]}}; do
    echo "  $i) ${orgs[$i]}"
  done
  echo ""
  read "choice?Organization: "
  if [[ -z "${orgs[$choice]}" ]]; then
    echo "Invalid organization selection"
    exit 1
  fi

  selected_owner="${orgs[$choice]}"
}

visibility="--private"
for arg in "$@"; do
  case "$arg" in
    --public) visibility="--public" ;;
    --existing) ;; # handled below
  esac
done

gh auth switch --user "$gh_user"
choose_owner "$gh_user"

if [[ " $* " == *" --existing "* ]]; then
  all_repos=("${(@f)$(gh repo list "$selected_owner" --limit 1000 --json name -q '[.[].name] | sort | .[]')}")
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
  echo "Connecting to ${selected_owner}/${repo_name}"
  read "confirm?Confirm? (y/n) "
  [[ "$confirm" != "y" ]] && exit 0

  git remote remove origin 2>/dev/null
  git remote add origin "https://github.com/${selected_owner}/${repo_name}.git"
  git push -u origin main
else
  read "repo_name?Repo name: "
  label=${visibility#--}
  echo "Creating ${label} repo ${selected_owner}/${repo_name}"
  read "confirm?Confirm? (y/n) "
  [[ "$confirm" != "y" ]] && exit 0

  gh repo create "${selected_owner}/${repo_name}" --source=. $visibility --push
fi
