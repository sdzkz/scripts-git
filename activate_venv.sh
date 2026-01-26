# Run in python project root to activate venv

env_dir="venv"

if [ -f "$env_dir/bin/activate" ]; then
    source "$env_dir/bin/activate"
else
    echo "Activation script not found at $env_dir/bin/activate"
fi
