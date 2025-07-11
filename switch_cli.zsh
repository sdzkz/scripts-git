#!/usr/bin/env zsh

# Use in LLM dirs only 

SYMLINK="llm_cli"
DEV_TARGET="../llm-cli-git"
STABLE_TARGET="../llm-cli-main"

if [[ ! -L $SYMLINK ]]; then
  ln -sf $DEV_TARGET $SYMLINK
  echo "Created $SYMLINK → dev"
  exit 0
fi

current_target=$(readlink $SYMLINK)
rm $SYMLINK

if [[ $current_target == $DEV_TARGET ]]; then
  ln -sf $STABLE_TARGET $SYMLINK
  echo ""
  echo "$SYMLINK → main"
  echo ""
elif [[ $current_target == $STABLE_TARGET ]]; then
  ln -sf $DEV_TARGET $SYMLINK
  echo ""
  echo "$SYMLINK → dev"
  echo ""
else
  echo "⚠️  Unknown target: $SYMLINK → $current_target"
  echo "Resetting → dev"
  ln -sf $DEV_TARGET $SYMLINK
fi

