#!/usr/bin/env bash
set -euo pipefail

root="${1:-}"
[[ -n "$root" ]] || { echo "usage: $0 <path>" >&2; exit 1; }

pattern='/opt/homebrew|/usr/local/|/nix/store|/usr/lib/swift'
failed=0

while IFS= read -r file; do
  if ! file "$file" | grep -q 'Mach-O'; then
    continue
  fi
  if otool -L "$file" | tail -n +2 | grep -E "$pattern" >/dev/null; then
    echo "${file#$root/} contains forbidden dependency path:" >&2
    otool -L "$file" >&2
    failed=1
  fi
done < <(find "$root" -type f | sort)

exit "$failed"
