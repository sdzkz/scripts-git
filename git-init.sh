#!/bin/zsh
source "$(dirname "$0")/.env"

if [ ! -d ".git" ]; then
  git init
fi

echo "Which account?"
echo "1) $PERSONAL_GIT_NAME (personal)"
echo "2) $WORK_GIT_NAME (work)"
read "choice?> "

case $choice in
  1)
    git config user.name "$PERSONAL_GIT_NAME"
    git config user.email "$PERSONAL_GIT_EMAIL"
    ;;
  2)
    git config user.name "$WORK_GIT_NAME"
    git config user.email "$WORK_GIT_EMAIL"
    ;;
  *)
    echo "Invalid choice"
    exit 1
    ;;
esac

echo "Git config applied: $(git config user.name)"
