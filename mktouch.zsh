#!/usr/bin/env zsh

emulate -L zsh
setopt errexit nounset pipefail

if (( $# == 0 )); then
  print -u2 "usage: ${0:t} PATH [PATH ...]"
  exit 1
fi

for target in "$@"; do
  /bin/mkdir -p -- "${target:h}"
  /usr/bin/touch -- "$target"
done
