brew deps --tree $(brew outdated --formula -q) 2>/dev/null | awk '
/^[a-zA-Z]/ {
  if (pkg != "" && deps == 0) printf "\033[33m%s\033[0m\n", pkg
  pkg = $0; deps = 0; printed = 0
}
/^[├└│]/ && !/^│   / && !/^    / {
  deps++
  if (!printed) { print pkg; printed = 1 }
  print $0
}
END {
  if (pkg != "" && deps == 0) printf "\033[33m%s\033[0m\n", pkg
}'
