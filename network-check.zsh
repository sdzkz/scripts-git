#!/bin/bash

# Network Diagnostic Script for macOS
# Writes Markdown-formatted network status to file

set -e

FAST_MODE=false
if [[ "${1:-}" == "--fast" ]]; then
    FAST_MODE=true
fi

# Determine output filename
DATE=$(date +%Y-%m-%d)
BASE="Network-Check-$DATE"
OUTFILE="$BASE.md"

if [[ -f "$OUTFILE" ]]; then
    i=2
    while [[ -f "$BASE-$i.md" ]]; do
        ((i++))
    done
    OUTFILE="$BASE-$i.md"
fi

# Resolve the hardware port that backs Wi-Fi instead of assuming en0.
WIFI_IFACE=$(
    networksetup -listallhardwareports 2>/dev/null |
        awk '/Hardware Port: Wi-Fi/{getline; sub(/^Device: /, ""); print; exit}'
)

if [[ -z "$WIFI_IFACE" ]]; then
    WIFI_IFACE="en0"
fi

# Write report to file
{
echo "# Network Diagnostic Report"
echo ""
echo "**Date:** $(date)"
echo "**Hostname:** $(hostname)"

# WiFi Interface Info
echo ""
echo "## WiFi Interface ($WIFI_IFACE)"
echo ""
echo '```'
ifconfig "$WIFI_IFACE" 2>/dev/null | grep -E "inet |ether |status:" || echo "$WIFI_IFACE not found or down"
echo '```'

# WiFi Connection Details
echo ""
echo "## WiFi Connection"
echo ""
SSID=$(
    networksetup -getairportnetwork "$WIFI_IFACE" 2>/dev/null |
        sed 's/Current Wi-Fi Network: //' ||
        true
)
if [[ -z "$SSID" || "$SSID" == "You are not associated with an AirPort network." || "$SSID" == AuthorizationCreate\(\)\ failed:* ]]; then
    SSID="Unknown"
fi
echo "**SSID:** $SSID"
echo ""
echo '```'
if [[ "$FAST_MODE" == "true" ]]; then
    echo "Skipped in fast mode"
else
    system_profiler SPAirPortDataType 2>/dev/null | grep -E "PHY Mode:|Channel:|Network Type:|Security:|Signal / Noise:|Transmit Rate:|MCS Index:" | sed 's/^[ ]*//' | head -10
fi
echo '```'

# IP Configuration
echo ""
echo "## IP Configuration"
echo ""
echo "| Setting | Value |"
echo "|---------|-------|"
echo "| Local IP | $(ipconfig getifaddr "$WIFI_IFACE" 2>/dev/null || echo 'No IP') |"
echo "| Gateway | $(netstat -rn | grep default | head -1 | awk '{print $2}') |"
echo "| Subnet Mask | $(ipconfig getoption "$WIFI_IFACE" subnet_mask 2>/dev/null || echo 'Unknown') |"

# DNS Configuration
echo ""
echo "## DNS Servers"
echo ""
echo '```'
scutil --dns | grep "nameserver\[[0-9]*\]" | head -10 | sed 's/^[ ]*//'
echo '```'

# DHCP Info
echo ""
echo "## DHCP Lease"
echo ""
echo '```'
ipconfig getpacket "$WIFI_IFACE" 2>/dev/null | grep -E "yiaddr|server_identifier|lease_time|router|domain_name" || echo "No DHCP info available"
echo '```'

# Connectivity Tests
echo ""
echo "## Connectivity Tests"
echo ""
GATEWAY=$(netstat -rn | grep default | head -1 | awk '{print $2}')

ping_test() {
    local target=$1
    local label=$2
    if ping -c 1 -W 2 "$target" &>/dev/null; then
        local time=$(ping -c 1 -W 2 "$target" 2>/dev/null | grep "time=" | sed 's/.*time=//')
        echo "| $label | $target | OK | $time |"
    else
        echo "| $label | $target | FAILED | - |"
    fi
}

echo "| Test | Target | Status | Latency |"
echo "|------|--------|--------|---------|"
ping_test "$GATEWAY" "Gateway"
ping_test "8.8.8.8" "Google DNS"
ping_test "1.1.1.1" "Cloudflare"

# DNS Resolution Tests
echo ""
echo "## DNS Resolution"
echo ""
echo "| Domain | Status | Result |"
echo "|--------|--------|--------|"

for domain in google.com apple.com; do
    if host -W 2 "$domain" &>/dev/null; then
        result=$(host -W 2 "$domain" 2>/dev/null | head -1 | sed 's/.*has address //')
        echo "| $domain | OK | $result |"
    else
        echo "| $domain | FAILED | - |"
    fi
done

# HTTP connectivity
echo ""
echo "## HTTP Connectivity"
echo ""
echo "| Test | Status | Notes |"
echo "|------|--------|-------|"

CAPTIVE=$(curl -s -m 5 http://captive.apple.com 2>/dev/null || true)
if [[ "$CAPTIVE" == *"Success"* ]]; then
    echo "| Captive Portal Check | OK | No captive portal |"
elif [[ -n "$CAPTIVE" ]]; then
    echo "| Captive Portal Check | WARN | Captive portal detected |"
else
    echo "| Captive Portal Check | FAILED | No response |"
fi

if curl -s -m 5 -o /dev/null -w "%{http_code}" https://www.google.com 2>/dev/null | grep -q "200"; then
    echo "| HTTPS (google.com) | OK | HTTP 200 |"
else
    echo "| HTTPS (google.com) | FAILED | - |"
fi

# Routing table
echo ""
echo "## Default Routes"
echo ""
echo '```'
netstat -rn | grep -E "^default" | head -3
echo '```'

# Network Quality
echo ""
echo "## Network Quality"
echo ""
if [[ "$FAST_MODE" == "true" ]]; then
    echo "_Skipped in fast mode_"
elif command -v networkQuality &>/dev/null; then
    echo '```'
    networkQuality -s 2>/dev/null || echo "Network quality test failed"
    echo '```'
else
    echo "_networkQuality not available (requires macOS 12+)_"
fi

# Recent WiFi logs
echo ""
echo "## Recent WiFi Log Entries"
echo ""
echo '```'
if [[ "$FAST_MODE" == "true" ]]; then
    echo "Skipped in fast mode"
else
    log show --predicate 'subsystem == "com.apple.wifi"' --last 2m --style compact 2>/dev/null | tail -15 || echo "Could not read WiFi logs"
fi
echo '```'

# Interface statistics
echo ""
echo "## Interface Statistics ($WIFI_IFACE)"
echo ""
echo '```'
netstat -I "$WIFI_IFACE" | head -2
echo '```'

# VPN interfaces
echo ""
echo "## VPN/Tunnel Interfaces"
echo ""
VPN_FOUND=false
while IFS= read -r iface; do
    if [[ -n "$iface" ]]; then
        VPN_FOUND=true
        ip=$(ifconfig "$iface" 2>/dev/null | grep "inet " | awk '{print $2}')
        echo "- **$iface**: $ip"
    fi
done < <(ifconfig | grep -E "^utun|^ipsec|^ppp" | awk -F: '{print $1}')

if [[ "$VPN_FOUND" == "false" ]]; then
    echo "_No VPN interfaces detected_"
fi

# Firewall status
echo ""
echo "## Firewall"
echo ""
FW_STATE=$(/usr/libexec/ApplicationFirewall/socketfilterfw --getglobalstate 2>/dev/null || echo "Unknown")
echo "**Status:** $FW_STATE"

echo ""
echo "---"
if [[ "$FAST_MODE" == "true" ]]; then
    echo "_Mode: fast_"
else
    echo "_Mode: full_"
fi
echo ""
echo "_Report generated at $(date)_"
} >"$OUTFILE"

echo "Wrote network diagnostic report to $OUTFILE"
