#!/usr/bin/env zsh

find . -mindepth 1 -maxdepth 1 -type d -exec du -sk {} + 2> >(grep -v 'Operation not permitted' >&2) |
  sort -nr |
  awk '{size=$1; sub(/^[0-9]+[[:space:]]+/, ""); printf "%10.2f GB  %s\n", size/1048576, $0}'
