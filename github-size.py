#!/usr/bin/env python3

import argparse
import json
import os
import sys
import urllib.error
import urllib.parse
import urllib.request


def parse_github_repo(repo_url):
    parsed = urllib.parse.urlparse(repo_url)

    if parsed.netloc and parsed.netloc.lower() not in {"github.com", "www.github.com"}:
        raise ValueError("URL must be for github.com")

    path = parsed.path if parsed.netloc else repo_url
    parts = [part for part in path.strip("/").split("/") if part]

    if len(parts) < 2:
        raise ValueError("expected a GitHub repo URL like https://github.com/OWNER/REPO")

    owner, repo = parts[0], parts[1]
    if repo.endswith(".git"):
        repo = repo[:-4]

    return owner, repo


def human_size(kib):
    size = float(kib)
    units = ["KB", "MB", "GB"]

    for unit in units:
        if size < 1024 or unit == units[-1]:
            if unit == "KB":
                return f"{int(size):,} {unit}"
            return f"{size:.2f} {unit}"
        size /= 1024


def fetch_repo_size(owner, repo):
    api_url = f"https://api.github.com/repos/{owner}/{repo}"
    headers = {
        "Accept": "application/vnd.github+json",
        "User-Agent": "github-size.py",
    }

    token = os.environ.get("GITHUB_TOKEN")
    if token:
        headers["Authorization"] = f"Bearer {token}"

    request = urllib.request.Request(api_url, headers=headers)

    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            data = json.load(response)
    except urllib.error.HTTPError as error:
        body = error.read().decode("utf-8", errors="replace")
        try:
            message = json.loads(body).get("message", body)
        except json.JSONDecodeError:
            message = body
        raise RuntimeError(f"GitHub API error {error.code}: {message}") from error
    except urllib.error.URLError as error:
        raise RuntimeError(f"Could not reach GitHub API: {error.reason}") from error

    if "size" not in data:
        raise RuntimeError("GitHub API response did not include a size field")

    return data["size"]


def main():
    parser = argparse.ArgumentParser(
        description="Print the repository size reported by the GitHub API."
    )
    parser.add_argument("repo_url", help="GitHub repo URL, e.g. https://github.com/OWNER/REPO")
    args = parser.parse_args()

    try:
        owner, repo = parse_github_repo(args.repo_url)
        size_kib = fetch_repo_size(owner, repo)
    except (RuntimeError, ValueError) as error:
        print(f"Error: {error}", file=sys.stderr)
        return 1

    print(f"\n{human_size(size_kib)}\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
