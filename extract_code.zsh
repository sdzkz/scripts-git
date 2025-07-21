#!/usr/bin/env zsh
# extract_code.zsh — copy the first fenced code block in a Markdown file to the clipboard.

set -euo pipefail

# Determine the file to read
if [[ -n ${1:-} ]]; then
    file=$1
else
    # Pick the newest file whose name ends in "Response.md"
    file=(*Response.md(Nom[1]))  # (N) null-glob, (om) newest first, [1] first match
    [[ -n $file ]] || { echo "Error: no *Response.md file found." >&2; exit 1; }
fi

# Ensure the file exists
[[ -r $file ]] || { echo "Error: '$file' not found or not readable." >&2; exit 1; }

# Extract the first fenced code block (```...```) and copy it
awk '
  /^```/ { in_block = !in_block; next }   # toggle flag on opening/closing ```
  in_block { print }                      # print lines inside the block
' "$file" | pbcopy

echo "First code block copied to clipboard."

