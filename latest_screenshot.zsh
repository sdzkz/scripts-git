#!/usr/bin/env zsh

set -euo pipefail

desktop_dir="${HOME}/Desktop"

if [[ ! -d "${desktop_dir}" ]]; then
  print -u2 "Desktop directory not found: ${desktop_dir}"
  exit 1
fi

setopt local_options null_glob

candidates=(
  "${desktop_dir}"/Screen\ Shot\ *.(png|jpg|jpeg|heic|tiff)(N.om[1])
  "${desktop_dir}"/Screenshot\ *.(png|jpg|jpeg|heic|tiff)(N.om[1])
)

if (( ${#candidates} == 0 )); then
  print -u2 "No screenshot files found on ${desktop_dir}"
  exit 1
fi

print -r -- "${candidates[1]:A}"
