#!/bin/zsh

setopt localoptions no_sh_word_split

app_output=$(osascript <<'APPLESCRIPT'
tell application "System Events"
    set appList to name of every application process whose visible is true
    set AppleScript's text item delimiters to linefeed
    return appList as text
end tell
APPLESCRIPT
)
exit_code=$?

print ""

if (( exit_code != 0 )); then
    print "Unable to read visible apps from System Events."
    exit $exit_code
fi

apps=("${(@f)$(print -r -- "$app_output" | sort -f)}")

if (( ${#apps[@]} == 0 )); then
    print "No visible GUI apps found."
    exit 0
fi

for i in {1..${#apps[@]}}; do
    display_name=$(print -r -- "${apps[$i]}" | perl -pe 's/^([[:alpha:]])/\U$1/')
    print "$i - $display_name"
done

print -n "\n: "
read selection

if [[ ! "$selection" =~ ^[0-9]+$ ]]; then
    print ""
    exit 1
fi

if (( selection < 1 || selection > ${#apps[@]} )); then
    print "Selection out of range."
    exit 1
fi

app_name="${apps[$selection]}"

osascript - "$app_name" <<'APPLESCRIPT'
on run argv
    tell application (item 1 of argv) to quit
end run
APPLESCRIPT

print -P -- "\n$app_name %F{cyan}Quit%f\n"
