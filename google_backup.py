#!/usr/bin/env python3

import datetime
import subprocess

current_time = datetime.datetime.now().strftime('%H:%M:%S')
print(f"\nScript started at {current_time}\n") 

skip_sync = False
drive_root = r"M1\ Backups/"
speed_flags = "--transfers 32 --checkers 16 --fast-list --buffer-size 64M"

directories_to_sync = {
    "/Users/billp/Desktop/":"Desktop/",
    "/Users/billp/Dev/":"Dev/",
    r"/Users/billp/Long\ Term\ Storage/":r"Long\ Term\ Storage/",
    "/Users/billp/Videos/":"Videos/"
}

excluded_patterns = {
    ".DS_Store",
    ".git/**",
    ".history/**",
    ".idea/**",
    "**/__pycache__/**",
    "venv/**",
    "*-env/**"
}

exclude_clause = " ".join(f'--exclude "{pattern}"' for pattern in excluded_patterns)  

for m1_path, drive_path in directories_to_sync.items():
    bash_command = f"rclone sync {speed_flags} {exclude_clause} --delete-excluded {m1_path} drive:{drive_root}{drive_path}"
    print(bash_command)

    if skip_sync:
        continue

    result = subprocess.run(bash_command, shell=True, capture_output=True, text=True)

    if len(result.stdout) > 0:
        print("Output:", result.stdout)

    if result.returncode != 0:
        print("Return code:", result.returncode)


current_time = datetime.datetime.now().strftime('%H:%M:%S')
print(f"\nScript stopped at {current_time}\n") 

