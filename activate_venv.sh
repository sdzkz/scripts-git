# Run in python project root to activate venv


# Find the first directory ending with '-env' in the current working directory
env_dir=$(find . -maxdepth 1 -type d -name "*-env" -print -quit)

if [ -n "$env_dir" ]; then
    # Get the absolute path of the found directory
    absolute_env_dir=$(cd "$env_dir" && pwd -P)
    
    # Check if the activation script exists
    if [ -f "$absolute_env_dir/bin/activate" ]; then
        # Source the activation script
        source "$absolute_env_dir/bin/activate"
    else
        echo "Activation script not found at $absolute_env_dir/bin/activate"
    fi
else
    echo "No directory ending with '-env' found in the current working directory."
fi
