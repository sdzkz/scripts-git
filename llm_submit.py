#!/usr/bin/env python3
"""
LLM Provider Selector Script

This script allows you to choose which LLM provider to use from the
available provider directories, then runs that provider's submit_prompt.py
script. It automatically activates the provider's virtual environment
and sets up the proper Python path.

Usage:
    ./llm_submit.py "My test prompt"    # Prompt as string
    ./llm_submit.py my_prompt.txt       # Prompt from file
    ./llm_submit.py --list              # List all providers
    ./llm_submit.py --help              # Show this help

Arguments:
    prompt: Either a quoted prompt string or path to a prompt file

The script will interactively ask you to select a provider from the list.

Examples:
    ./llm_submit.py "Hello, write me a poem"   # Interactive provider selection
    ./llm_submit.py prompt.txt                 # Use prompt from file
    ./llm_submit.py --list                     # List all providers
"""

import os
import sys
import subprocess
import re
import tempfile
import shutil


def find_provider_dirs(base_path=None):
    """Find all provider directories by looking for provider_config.py."""
    if base_path is None:
        # Default to script's directory
        base_path = os.path.dirname(os.path.abspath(__file__))
    
    providers = []
    for item in os.listdir(base_path):
        item_path = os.path.join(base_path, item)
        if os.path.isdir(item_path):
            config_path = os.path.join(item_path, "provider_config.py")
            if os.path.exists(config_path):
                providers.append(item)
    return sorted(providers)


def get_provider_name_from_config(dir_path):
    """Extract PROVIDER_NAME from provider_config.py."""
    config_path = os.path.join(dir_path, "provider_config.py")
    try:
        with open(config_path, 'r') as f:
            content = f.read()
            # Simple regex to find PROVIDER_NAME = "..."
            match = re.search(r'PROVIDER_NAME\s*=\s*[\'"]([^\'"]+)[\'"]', content)
            if match:
                return match.group(1)
    except Exception:
        pass
    return os.path.basename(dir_path).title()


def display_menu(providers):
    """Display numbered menu of providers."""
    print()
    for i, provider_dir in enumerate(providers, 1):
        provider_name = get_provider_name_from_config(provider_dir)
        print(f"  {i:2} - {provider_name}")
    print()


def select_provider_interactive(providers):
    """Interactive provider selection."""
    while True:
        try:
            choice = input(": ").strip()
            if not choice:
                continue
            
            # Check if numeric choice
            if choice.isdigit():
                idx = int(choice) - 1
                if 0 <= idx < len(providers):
                    return providers[idx]
                else:
                    print(f"Invalid number. Please choose 1-{len(providers)}.")
            else:
                # Try to match by directory name
                matched = [p for p in providers if p.lower() == choice.lower()]
                if matched:
                    return matched[0]
                # Try to match by provider name
                for p in providers:
                    if get_provider_name_from_config(p).lower() == choice.lower():
                        return p
                print(f"Provider '{choice}' not found.")
        except KeyboardInterrupt:
            print("\nCancelled.")
            sys.exit(0)
        except Exception as e:
            print(f"Error: {e}")


def find_python_executable(provider_dir):
    """Find the appropriate Python executable for the provider."""
    # Try venv python first
    venv_python = os.path.join(provider_dir, "venv", "bin", "python")
    if os.path.exists(venv_python):
        return venv_python
    
    # Warn if no venv found
    print(f"Warning: No venv found in {provider_dir}/venv/bin/python")
    print("Falling back to system Python. Dependencies may be missing.")
    
    # Fall back to system python
    return sys.executable


def run_submit_prompt(provider_dir, prompt_file=None):
    """Run the submit_prompt.py script in the provider directory.
    
    Args:
        provider_dir: Provider directory path
        prompt_file: Optional path to prompt file (relative to current directory)
    """
    # Convert to absolute path
    abs_provider_dir = os.path.abspath(provider_dir)
    script_path = os.path.join(abs_provider_dir, "scripts", "submit_prompt.py")
    if not os.path.exists(script_path):
        print(f"Error: {script_path} not found.")
        return False
    
    # Resolve prompt file path
    resolved_prompt_file = None
    if prompt_file:
        if os.path.isabs(prompt_file):
            resolved_prompt_file = prompt_file
        else:
            # Resolve relative to original current directory
            original_cwd = os.getcwd()
            resolved_prompt_file = os.path.join(original_cwd, prompt_file)
        
        if not os.path.exists(resolved_prompt_file):
            print(f"Error: Prompt file not found: {resolved_prompt_file}")
            return False
    
    # Change to provider directory
    original_cwd = os.getcwd()
    os.chdir(abs_provider_dir)
    
    try:
        # Find Python executable
        python_exec = find_python_executable(abs_provider_dir)
        
        # Set PYTHONPATH to include provider directory so llm_cli can be found
        env = os.environ.copy()
        if 'PYTHONPATH' in env:
            env['PYTHONPATH'] = os.pathsep.join([abs_provider_dir, env['PYTHONPATH']])
        else:
            env['PYTHONPATH'] = abs_provider_dir
        
        # Build command
        cmd = [python_exec, "scripts/submit_prompt.py"]
        if resolved_prompt_file:
            cmd.append(resolved_prompt_file)
        
        # Run the script
        # print(f"Running {script_path} in {abs_provider_dir}/")
        result = subprocess.run(cmd, env=env, capture_output=False)
        return result.returncode == 0
    finally:
        os.chdir(original_cwd)


def main():
    # Find available providers
    providers = find_provider_dirs()
    
    if not providers:
        print("No provider directories found (looking for provider_config.py).")
        sys.exit(1)
    
    # Parse command line arguments
    args = sys.argv[1:]
    prompt_arg = None
    temp_dir = None
    
    # Handle flags
    for arg in args:
        if arg in ["--help", "-h"]:
            print(__doc__)
            sys.exit(0)
        elif arg in ["--list", "-l"]:
            print("\nAvailable LLM Providers:")
            for j, provider_dir in enumerate(providers, 1):
                provider_name = get_provider_name_from_config(provider_dir)
                print(f"  {j:2}. {provider_name} ({provider_dir}/)")
            sys.exit(0)
    
    # Check for prompt argument
    if len(args) == 0:
        print("Error: A prompt argument is required.")
        print("Usage: ./llm_submit.py \"My test prompt\"")
        print("   or: ./llm_submit.py my_prompt.txt")
        print("   or: ./llm_submit.py --list")
        print("   or: ./llm_submit.py --help")
        sys.exit(1)
    
    # Join all remaining arguments as the prompt (allows multi-word prompts without quotes)
    prompt_arg = ' '.join(args)
    if not prompt_arg.strip():
        print("Error: Prompt cannot be empty.")
        sys.exit(1)
    
    # Interactive provider selection
    display_menu(providers)
    selected = select_provider_interactive(providers)
    
    # Confirm selection
    provider_name = get_provider_name_from_config(selected)
    # print(f"\nSelected: {provider_name} ({selected}/)")
    
    # Check if prompt_arg is a file that exists
    prompt_file = None
    if os.path.exists(prompt_arg):
        prompt_file = prompt_arg
        # print(f"Using prompt file: {prompt_file}")
    else:
        # Create a temporary file with the prompt text
        temp_dir = tempfile.mkdtemp()
        prompt_file = os.path.join(temp_dir, "prompt.txt")
        with open(prompt_file, 'w') as f:
            f.write(prompt_arg)
        # print(f"Created temporary prompt file: {prompt_file}")
    
    try:
        # Run the submit script
        success = run_submit_prompt(selected, prompt_file)
        
        if not success:
            sys.exit(1)
    finally:
        # Clean up temporary directory if created
        if temp_dir and os.path.exists(temp_dir):
            shutil.rmtree(temp_dir)


if __name__ == "__main__":
    main()
