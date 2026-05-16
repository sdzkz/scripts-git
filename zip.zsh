#!/usr/bin/env zsh

set -u
set -o pipefail

script_name="${0:t}"

usage() {
  print -u2 "Usage: ${script_name} (--compress|--decompress) PATH"
  print -u2 ""
  print -u2 "Compress:"
  print -u2 "  ${script_name} --compress ./dir      -> ./dir.tar.zst"
  print -u2 "  ${script_name} --compress ./file     -> ./file.zst"
  print -u2 ""
  print -u2 "Decompress:"
  print -u2 "  ${script_name} --decompress ./dir.tar.zst"
  print -u2 "  ${script_name} --decompress ./file.zst"
}

die() {
  print -u2 "${script_name}: $*"
  exit 1
}

need_command() {
  command -v "$1" >/dev/null 2>&1 || die "required command not found: $1"
}

compress_path() {
  local input="$1"

  [[ -e "$input" ]] || die "input does not exist: $input"
  need_command zstd

  local input_abs="${input:a}"
  local name="${input_abs:t}"

  if [[ -d "$input_abs" ]]; then
    need_command tar

    local parent="${input_abs:h}"
    local out="${PWD}/${name}.tar.zst"
    local tmpdir
    local tmp

    [[ ! -e "$out" ]] || die "output already exists: $out"

    tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/archive.zsh.XXXXXXXXXX")" || die "could not create temporary directory"
    tmp="${tmpdir}/${name}.tar.zst"
    trap '[[ -n "${tmp:-}" && -e "$tmp" ]] && rm -f "$tmp"; [[ -n "${tmpdir:-}" && -d "$tmpdir" ]] && rmdir "$tmpdir" 2>/dev/null' EXIT INT TERM

    tar -C "$parent" -cf - "$name" | zstd -q -T0 -o "$tmp" || die "compression failed"
    mv "$tmp" "$out" || die "could not move archive into working directory"
    rmdir "$tmpdir" 2>/dev/null
    trap - EXIT INT TERM

    print "$out"
  elif [[ -f "$input_abs" ]]; then
    local out="${PWD}/${name}.zst"

    [[ ! -e "$out" ]] || die "output already exists: $out"
    zstd -q -T0 -k -o "$out" "$input_abs" || die "compression failed"
    print "$out"
  else
    die "input must be a regular file or directory: $input"
  fi
}

decompress_path() {
  local input="$1"

  [[ -f "$input" ]] || die "archive must be a file: $input"
  need_command zstd

  local input_abs="${input:a}"
  local name="${input_abs:t}"

  case "$name" in
    *.tar.zst|*.tzst)
      need_command tar
      zstd -q -dc "$input_abs" | tar -C "$PWD" -xkf - || die "decompression failed"
      ;;
    *.zst)
      local out="${PWD}/${name%.zst}"

      [[ ! -e "$out" ]] || die "output already exists: $out"
      zstd -q -d -k -o "$out" "$input_abs" || die "decompression failed"
      print "$out"
      ;;
    *)
      die "unsupported archive type: expected .zst, .tar.zst, or .tzst"
      ;;
  esac
}

if [[ "$#" -eq 1 && ( "$1" == "-h" || "$1" == "--help" ) ]]; then
  usage
  exit 0
fi

if [[ "$#" -ne 2 ]]; then
  usage
  exit 2
fi

case "$1" in
  -c|--compress)
    compress_path "$2"
    ;;
  -d|--decompress)
    decompress_path "$2"
    ;;
  *)
    usage
    exit 2
    ;;
esac
