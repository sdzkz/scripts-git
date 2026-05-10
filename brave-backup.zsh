#!/usr/bin/env zsh

# Brave Browser Backup Script
# Usage: ./brave_backup.zsh [--dry-run]

set -euo pipefail

# Configuration
BRAVE_USER_DATA_PATH="/Users/$USER/Library/Application Support/BraveSoftware/Brave-Browser"
BACKUP_ROOT="$HOME/Dev/backups/brave"
BACKUP_DIR="$BACKUP_ROOT/brave_backup_$(date +%Y%m%d_%H%M%S)"
DRY_RUN=false

# Parse arguments
if [[ $# -gt 0 && "$1" == "--dry-run" ]]; then
    DRY_RUN=true
fi

# Files and directories to backup
BACKUP_ITEMS=(
    "Preferences"
    "Bookmarks" 
    "History"
    "Login Data"
    "Web Data"
    "Extensions"
    "Local Extension Settings"
    "Secure Preferences"
    "Top Sites"
    "Favicons"
)

# Check if Brave directory exists
if [[ ! -d "$BRAVE_USER_DATA_PATH" ]]; then
    echo "ERROR: Brave browser directory not found: $BRAVE_USER_DATA_PATH" >&2
    exit 1
fi

# Collect all regular Brave profile directories
PROFILE_DIRS=()

if [[ -d "$BRAVE_USER_DATA_PATH/Default" ]]; then
    PROFILE_DIRS+=("$BRAVE_USER_DATA_PATH/Default")
fi

for profile_dir in "$BRAVE_USER_DATA_PATH"/Profile\ *(N); do
    [[ -d "$profile_dir" ]] && PROFILE_DIRS+=("$profile_dir")
done

if (( ${#PROFILE_DIRS[@]} == 0 )); then
    echo "ERROR: No Brave profiles found under: $BRAVE_USER_DATA_PATH" >&2
    exit 1
fi

echo "Brave Browser Backup Script"
echo "Source: $BRAVE_USER_DATA_PATH"

if pgrep -xq "Brave Browser" 2>/dev/null; then
    echo "WARNING: Brave appears to be running. Quit Brave first for the most consistent backup of SQLite files."
fi

echo "Profiles:"
for profile_dir in "${PROFILE_DIRS[@]}"; do
    echo "  - $(basename "$profile_dir")"
done

if $DRY_RUN; then
    echo -e "\nDRY RUN - Calculating backup size..."
    echo "Backup destination: $BACKUP_DIR"
    
    total_size=0
    
    for profile_dir in "${PROFILE_DIRS[@]}"; do
        profile_name=$(basename "$profile_dir")
        echo -e "\nItems to backup for $profile_name:"

        for item in "${BACKUP_ITEMS[@]}"; do
            item_path="$profile_dir/$item"
            if [[ -e "$item_path" ]]; then
                # Use consistent byte calculation method
                if [[ -d "$item_path" ]]; then
                    # Calculate directory size using find + stat
                    size_bytes=$(find "$item_path" -type f -exec stat -f%z {} \; 2>/dev/null | awk '{s+=$1} END {print s}')
                    size_human=$(du -sh "$item_path" | awk '{print $1}')
                    echo "  DIR  $item/ - $size_human"
                else
                    size_bytes=$(stat -f%z "$item_path" 2>/dev/null || echo 0)
                    size_human=$(du -sh "$item_path" | awk '{print $1}')
                    echo "  FILE $item - $size_human"
                fi
                total_size=$((total_size + size_bytes))
            else
                echo "  WARN $item - not found"
            fi
        done
    done
    
    # Convert total size to human readable
    if (( total_size > 1073741824 )); then
        total_human=$(echo "scale=1; $total_size / 1073741824" | bc)"G"
    elif (( total_size > 1048576 )); then
        total_human=$(echo "scale=1; $total_size / 1048576" | bc)"M"
    elif (( total_size > 1024 )); then
        total_human=$(echo "scale=1; $total_size / 1024" | bc)"K"
    else
        total_human="${total_size}B"
    fi
    
    echo -e "\nTotal backup size: $total_human"
    echo -e "\nTo perform the actual backup, run without --dry-run"
    
else
    echo "Backup destination: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    echo -e "\nCreating backup..."
    
    backed_up=0
    for profile_dir in "${PROFILE_DIRS[@]}"; do
        profile_name=$(basename "$profile_dir")
        profile_backup_dir="$BACKUP_DIR/$profile_name"
        mkdir -p "$profile_backup_dir"

        echo -e "\n[$profile_name]"

        for item in "${BACKUP_ITEMS[@]}"; do
            item_path="$profile_dir/$item"
            dest_path="$profile_backup_dir/$item"
            
            if [[ -e "$item_path" ]]; then
                if [[ -d "$item_path" ]]; then
                    cp -R "$item_path" "$dest_path"
                else
                    cp "$item_path" "$dest_path"
                fi
                (( ++backed_up ))
                echo "  OK   $item"
            else
                echo "  WARN $item - not found, skipping"
            fi
        done
    done
    
    echo -e "\nBackup completed. $backed_up items backed up to: $BACKUP_DIR"
fi
