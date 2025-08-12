#!/usr/bin/env python3

import subprocess
import os

ICLOUD_BACKUP_DIR = "/Users/billp/Library/Mobile Documents/com~apple~CloudDocs/2020-M1"

PATHS_TO_BACKUP = [
    "/Users/billp/.config",
    "/Users/billp/.gitconfig",
    "/Users/billp/.local",
    "/Users/billp/.python_history",
    "/Users/billp/.sqlite_history",
    "/Users/billp/.sqliterc",
    "/Users/billp/.ssh",
    "/Users/billp/.tidyrc",
    "/Users/billp/.vim",
    "/Users/billp/.vimrc",
    "/Users/billp/.zprofile",
    "/Users/billp/.zsh_history", 
    "/Users/billp/.zsh_sessions",
    "/Users/billp/.zshrc"
]

def sync_to_icloud(dry_run=True):
    rsync_options = [
        "-a", "--delete", "-H", "--stats", "--relative", "--itemize-changes"
    ]
    
    if dry_run:
        rsync_options.append("-n")

    print()

    for src_path in PATHS_TO_BACKUP:
        if not os.path.exists(src_path):
            print(f"{src_path}: Does not exist")
            continue
        
        cmd = ["rsync"] + rsync_options + [src_path, ICLOUD_BACKUP_DIR]
        result = subprocess.run(cmd, capture_output=True, text=True)
      
        print(f"{src_path:40}")

    print()

if __name__ == "__main__":
    sync_to_icloud(dry_run=False)
