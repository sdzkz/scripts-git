#!/bin/zsh

GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

CLAUDE="$HOME/.claude"
CLAUDE_JSON="$HOME/.claude.json"

PERSONAL="dotfiles/.claude-personal"
WORK="dotfiles/.claude-work"
PERSONAL_JSON="dotfiles/.claude-personal.json"
WORK_JSON="dotfiles/.claude-work.json"

CREDS_PERSONAL="$HOME/dotfiles/.claude-creds-personal"
CREDS_WORK="$HOME/dotfiles/.claude-creds-work"

KEYCHAIN_SERVICE="Claude Code-credentials"

if [[ -L "$CLAUDE" ]]; then
    CURRENT=$(readlink "$CLAUDE")
else
    CURRENT=""
fi

if [[ "$CURRENT" == *"personal"* ]]; then
    NEW="$WORK"
    NEW_JSON="$WORK_JSON"
    NEW_NAME="work"
    OLD_CREDS="$CREDS_PERSONAL"
    NEW_CREDS="$CREDS_WORK"
else
    NEW="$PERSONAL"
    NEW_JSON="$PERSONAL_JSON"
    NEW_NAME="personal"
    OLD_CREDS="$CREDS_PERSONAL"
    NEW_CREDS="$CREDS_PERSONAL"
    [[ "$CURRENT" == *"work"* ]] && OLD_CREDS="$CREDS_WORK"
fi

# Save current keychain credential for the outgoing profile
CURRENT_CRED=$(security find-generic-password -s "$KEYCHAIN_SERVICE" -w 2>/dev/null)
if [[ -n "$CURRENT_CRED" ]]; then
    echo "$CURRENT_CRED" > "$OLD_CREDS"
    chmod 600 "$OLD_CREDS"
fi

# Swap symlinks
[[ -L "$CLAUDE" ]] && rm "$CLAUDE"
[[ -L "$CLAUDE_JSON" ]] && rm "$CLAUDE_JSON"
rm -f "$HOME"/.claude.json.backup.*(N) 2>/dev/null

ln -s "$NEW" "$CLAUDE"
ln -s "$NEW_JSON" "$CLAUDE_JSON"

# Restore keychain credential for the incoming profile
if [[ -f "$NEW_CREDS" ]]; then
    RESTORE_CRED=$(cat "$NEW_CREDS")
    security delete-generic-password -s "$KEYCHAIN_SERVICE" 2>/dev/null
    security add-generic-password -s "$KEYCHAIN_SERVICE" -a "$KEYCHAIN_SERVICE" -w "$RESTORE_CRED"
    printf "%-13s ${BLUE}->${NC} ${GREEN}%s (cached)${NC}\n" "credentials" "$NEW_NAME"
else
    security delete-generic-password -s "$KEYCHAIN_SERVICE" 2>/dev/null
    printf "%-13s ${BLUE}->${NC} ${RED}%s (run: claude login)${NC}\n" "credentials" "$NEW_NAME"
fi

printf "%-13s ${BLUE}->${NC} ${GREEN}%s${NC}\n" ".claude" "$NEW"
printf "%-13s ${BLUE}->${NC} ${GREEN}%s${NC}\n" ".claude.json" "$NEW_JSON"
