#!/bin/zsh

python3 -m venv venv
cat >> "venv/bin/activate" << 'EOF'
export PYTHONPATH="${VIRTUAL_ENV%/*}"
EOF
