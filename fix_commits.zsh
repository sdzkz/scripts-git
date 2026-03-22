source "$(dirname "$0")/.env"

echo "Which account?"
echo "1) $PERSONAL_GIT_NAME (personal)"
echo "2) $WORK_GIT_NAME (work)"
read "choice?> "

case $choice in
  1)
    NAME="$PERSONAL_GIT_NAME"
    EMAIL="$PERSONAL_GIT_EMAIL"
    ;;
  2)
    NAME="$WORK_GIT_NAME"
    EMAIL="$WORK_GIT_EMAIL"
    ;;
  *)
    echo "Invalid choice"
    exit 1
    ;;
esac

git filter-branch -f --env-filter '
    N="'"$NAME"'"
    E="'"$EMAIL"'"
    export GIT_AUTHOR_NAME="$N" GIT_COMMITTER_NAME="$N"
    export GIT_AUTHOR_EMAIL="$E" GIT_COMMITTER_EMAIL="$E"
' --tag-name-filter cat -- --branches --tags
