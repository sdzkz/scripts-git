#!/usr/bin/env zsh
set -euo pipefail

SCRIPT_DIR="${0:a:h}"
PROMPT_FILE="${SCRIPT_DIR}/GIT_COMMIT_PROMPT.txt"
COMMIT_DIFF_FILE="${SCRIPT_DIR}/COMMITDIFF.txt"
SUBMIT_SCRIPT="${SCRIPT_DIR}/submit.py"
BUFFER_FILE="$(mktemp "${TMPDIR:-/tmp}/commit-buffer.XXXXXX")"

cleanup() {
  rm -f "$BUFFER_FILE"
}
trap cleanup EXIT

if [[ ! -f "$PROMPT_FILE" ]]; then
  print -u2 "Missing prompt file: $PROMPT_FILE"
  exit 1
fi

if [[ ! -x "$SUBMIT_SCRIPT" ]]; then
  print -u2 "Missing executable submit script: $SUBMIT_SCRIPT"
  exit 1
fi

vim "$BUFFER_FILE"

if [[ ! -s "$BUFFER_FILE" ]]; then
  print -u2 "Buffer was empty; not submitting."
  exit 1
fi

{
  cat "$PROMPT_FILE"
  printf '\n'
  cat "$BUFFER_FILE"
} > "$COMMIT_DIFF_FILE"

cd "$SCRIPT_DIR"
./submit.py COMMITDIFF.txt
