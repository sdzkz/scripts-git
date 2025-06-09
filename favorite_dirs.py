#!/usr/bin/env python3

'''
Quickly go/see favorite directories
'''

import os
import argparse
from pathlib import Path

parser = argparse.ArgumentParser()
parser.add_argument('--add', action='store_true')
parser.add_argument('filter', nargs='?', type=str)
args = parser.parse_args()

txt_file = Path.home() / '.local/share/favorite_dirs.txt'

if args.add:
    new_path = os.getcwd()
    with open(txt_file, 'a+') as f:
        f.seek(0)
        lines = f.readlines()
        if f"{new_path}\n" not in lines:
            lines.append(f"{new_path}\n")
            lines.sort()
            f.seek(0)
            f.truncate()
            f.writelines(lines)
    exit()

with open(txt_file, 'r') as f:
    print("\n")
    for i, line in enumerate(f, 1):
        path = line.strip()
        base = os.path.basename(path)
        
        # Apply filter if provided
        if args.filter and not base.startswith(args.filter):
            continue
            
        # Format output
        if i % 2 == 1:
            print(f"\033[1m{i}: {path}\033[0m")  # Bold
        else:
            print(f"{i}: {path}")
    print("\n")
