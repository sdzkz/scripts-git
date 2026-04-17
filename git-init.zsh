#!/bin/zsh
source "$(dirname "$0")/.env"

if [ ! -d ".git" ]; then
  git init
fi

echo "\nWhich?"
echo "1 - $PERSONAL_GIT_NAME"
echo "2 - $WORK_GIT_NAME"
read "choice?\n: "

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
