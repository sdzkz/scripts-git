#!/usr/bin/env zsh

# Brave Browser Backup Script
# Usage: ./brave_backup.zsh [--dry-run]

set -euo pipefail

# Configuration
BRAVE_DEFAULT_PATH="/Users/$USER/Library/Application Support/BraveSoftware/Brave-Browser/Default"
BACKUP_DIR="$HOME/Dev/backups/brave_backup_$(date +%Y%m%d_%H%M%S)"
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
if [[ ! -d "$BRAVE_DEFAULT_PATH" ]]; then
    echo "❌ Brave browser directory not found: $BRAVE_DEFAULT_PATH" >&2
    exit 1
fi

echo "🦁 Brave Browser Backup Script"
echo "Source: $BRAVE_DEFAULT_PATH"

if $DRY_RUN; then
    echo -e "\n🔍 DRY RUN - Calculating backup size..."
    echo "Backup destination: $BACKUP_DIR"
    echo -e "\nItems to backup:"
    
    total_size=0
    
    for item in "${BACKUP_ITEMS[@]}"; do
        item_path="$BRAVE_DEFAULT_PATH/$item"
        if [[ -e "$item_path" ]]; then
            # Use consistent byte calculation method
            if [[ -d "$item_path" ]]; then
                # Calculate directory size using find + stat
                size_bytes=$(find "$item_path" -type f -exec stat -f%z {} \; 2>/dev/null | awk '{s+=$1} END {print s}')
                size_human=$(du -sh "$item_path" | awk '{print $1}')
                echo "  📁 $item/ - $size_human"
            else
                size_bytes=$(stat -f%z "$item_path" 2>/dev/null || echo 0)
                size_human=$(du -sh "$item_path" | awk '{print $1}')
                echo "  📄 $item - $size_human"
            fi
            total_size=$((total_size + size_bytes))
        else
            echo "  ⚠️  $item - not found"
        fi
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
    
    echo -e "\n📊 Total backup size: $total_human"
    echo -e "\nTo perform the actual backup, run without --dry-run"
    
else
    echo "Backup destination: $BACKUP_DIR"
    mkdir -p "$BACKUP_DIR"
    echo -e "\n📦 Creating backup..."
    
    backed_up=0
    for item in "${BACKUP_ITEMS[@]}"; do
        item_path="$BRAVE_DEFAULT_PATH/$item"
        dest_path="$BACKUP_DIR/$item"
        
        if [[ -e "$item_path" ]]; then
            if [[ -d "$item_path" ]]; then
                cp -R "$item_path" "$dest_path"
            else
                cp "$item_path" "$dest_path"
            fi
            (( backed_up++ ))
            echo "  ✅ $item"
        else
            echo "  ⚠️  $item - not found, skipping"
        fi
    done
    
    echo -e "\n✅ Backup completed! $backed_up items backed up to: $BACKUP_DIR"
fi

