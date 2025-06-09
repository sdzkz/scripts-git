#!/bin/zsh

# Quickly go/see favorite directories

dirs() {
    local txt_file=~/.local/share/favorite_dirs.txt
    if [[ $# -eq 1 && $1 =~ ^[0-9]+$ ]]; then
        local path=$(sed -n "${1}p" "$txt_file")
        if [[ -n "$path" ]]; then
            cd "$path" || return 1
        else
            echo "Invalid line number: $1" >&2
            return 1
        fi
    else
        ~/Dev/scripts-git/favorite_dirs.py "$@"
    fi
}
