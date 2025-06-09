#!/bin/zsh

# Create python venv 

if [ $# -ne 1 ]; then
    echo "Usage: $0 ENV_NAME"
    exit 1
fi

python3 -m venv "$1"
echo "export PYTHONPATH=\$PWD" >> "$1/bin/activate"
