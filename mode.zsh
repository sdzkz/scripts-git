#!/usr/bin/env zsh

MODES_DIR="llm_cli/modes"
CURRENT_MODE=$(readlink mode | xargs basename 2>/dev/null)
echo ""

[[ ! -d "$MODES_DIR" ]] && {
    echo "Error: Modes directory '$MODES_DIR' not found"
    exit 1
}

if [[ "$1" == "--new" ]]; then
    [[ $# -ne 3 ]] && {
        echo "Usage: $0 --new SOURCE_MODE NEW_MODE"
        exit 1
    }
    SOURCE="$MODES_DIR/$2"
    TARGET="$MODES_DIR/$3"
    [[ ! -f "$SOURCE" ]] && {
        echo "Error: Source mode '$2' not found"
        exit 1
    }
    cp "$SOURCE" "$TARGET"
    vi "$TARGET"
    exit 0
fi

[[ $# -eq 0 ]] && {
    for mode in $MODES_DIR/*; do
        mode_name=$(basename "$mode")
        if [[ "$mode_name" == "$CURRENT_MODE" ]]; then
            echo -e "\033[32mvi ${mode}\033[0m"
        else
            echo "vi ${mode}"
        fi
    done
    echo ""
    exit 0
}

MODE_FILE="$MODES_DIR/$1"
[[ ! -f "$MODE_FILE" ]] && {
    echo "Error: Mode '$1' not found in $MODES_DIR"
    echo "Available modes:"
    for mode in $MODES_DIR/*; do
        mode_name=$(basename "$mode")
        if [[ "$mode_name" == "$CURRENT_MODE" ]]; then
            echo -e "\033[32mvi ${mode}\033[0m"
        else
            echo "vi ${mode}"
        fi
    done
    exit 1
}

ln -sf "$MODE_FILE" mode
echo "mode → $1"
echo ""

