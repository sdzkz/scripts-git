#!/bin/zsh

# Quickly go/see favorite directories

dirs() {
    local txt_file=~/.local/share/favorite_dirs.txt

    # Handle --add option
    if [[ "$1" == "--add" ]]; then
        ~/Dev/scripts-git/favorite_dirs.py --add
        return
    fi

    # Handle numeric argument (direct cd)
    if [[ $# -eq 1 && $1 =~ ^[0-9]+$ ]]; then
        local path=$(sed -n "${1}p" "$txt_file")
        if [[ -n "$path" ]]; then
            cd "$path" || return 1
        else
            echo "Invalid line number: $1" >&2
            return 1
        fi
    else
        # Show filtered list
        ~/Dev/scripts-git/favorite_dirs.py "$@"
        
        # Prompt for input
        echo -n ": "
        read user_input
        
        # Handle empty input
        if [[ -z "$user_input" ]]; then
            return 0
        fi
        
        # Validate and process numeric input
        if [[ "$user_input" =~ ^[0-9]+$ ]]; then
            local path=$(sed -n "${user_input}p" "$txt_file")
            if [[ -n "$path" ]]; then
                cd "$path" || return 1
            else
                echo "Invalid line number: $user_input" >&2
                return 1
            fi
        else
            echo "Invalid input. Expected a number." >&2
            return 1
        fi
    fi
}

