#!/usr/bin/env python3

from __future__ import annotations

import argparse
import re
from pathlib import Path


TIME_RANGE_MARKER = "-->"
LEADING_DASH_RE = re.compile(r"^\s*-+\s*")
LEADING_BRACKET_GROUPS_RE = re.compile(r"^(?:\[[^]]+\]\s*)+")


def clean_text_line(line: str) -> str | None:
    stripped = line.strip()
    dash_match = LEADING_DASH_RE.match(stripped)
    prefix = dash_match.group(0) if dash_match else ""
    remainder = stripped[dash_match.end() :] if dash_match else stripped

    bracket_match = LEADING_BRACKET_GROUPS_RE.match(remainder)
    if bracket_match is None:
        return line

    remainder = remainder[bracket_match.end() :].lstrip()
    if not remainder:
        return None

    if prefix and not prefix.endswith(" "):
        prefix = f"{prefix} "

    return f"{prefix}{remainder}"


def parse_cue(block: str) -> tuple[str, list[str]] | None:
    lines = [line.rstrip("\r") for line in block.splitlines()]
    if len(lines) < 2:
        return None

    if TIME_RANGE_MARKER in lines[0]:
        timestamp = lines[0]
        text_lines = lines[1:]
    elif TIME_RANGE_MARKER in lines[1]:
        timestamp = lines[1]
        text_lines = lines[2:]
    else:
        return None

    cleaned_text_lines = []
    for line in text_lines:
        cleaned_line = clean_text_line(line)
        if cleaned_line is not None:
            cleaned_text_lines.append(cleaned_line)

    if not cleaned_text_lines:
        return None

    return timestamp, cleaned_text_lines


def clean_srt(content: str) -> str:
    normalized = content.replace("\r\n", "\n").replace("\r", "\n").strip()
    if not normalized:
        return ""

    blocks = re.split(r"\n\s*\n+", normalized)
    cleaned_cues: list[str] = []

    for block in blocks:
        parsed = parse_cue(block)
        if parsed is None:
            continue

        timestamp, text_lines = parsed
        cue_number = len(cleaned_cues) + 1
        cue = "\n".join([str(cue_number), timestamp, *text_lines])
        cleaned_cues.append(cue)

    return "\n\n".join(cleaned_cues) + ("\n" if cleaned_cues else "")


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Remove subtitle lines that are only bracketed stage directions, "
            "then renumber cues so the output remains a valid SRT."
        )
    )
    parser.add_argument(
        "input",
        metavar="INPUT",
        type=Path,
        help="Input SRT file. The cleaned file is written next to it as *.cleaned.srt.",
    )
    return parser


def main() -> int:
    args = build_parser().parse_args()
    input_path = args.input.resolve()
    if input_path.suffix.lower() != ".srt":
        raise SystemExit("Input file must have a .srt extension")

    output_path = input_path.with_name(f"{input_path.stem}.cleaned.srt")

    content = input_path.read_text(encoding="utf-8-sig")
    cleaned = clean_srt(content)
    output_path.write_text(cleaned, encoding="utf-8", newline="\n")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
