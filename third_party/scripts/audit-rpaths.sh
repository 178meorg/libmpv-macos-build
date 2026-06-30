#!/usr/bin/env bash
set -euo pipefail

root="${1:-}"
[[ -n "$root" ]] || { echo "usage: $0 <path>" >&2; exit 1; }

failed=0
while IFS= read -r file; do
  if ! file "$file" | grep -q 'Mach-O'; then
    continue
  fi
  rel="${file#$root/}"
  if otool -L "$file" | tail -n +2 | grep -E "$root|/Users/runner|/private/var/folders|/tmp/" >/dev/null; then
    echo "$rel contains non-relocatable install names:" >&2
    otool -L "$file" >&2
    failed=1
  fi
  if otool -l "$file" | awk '/LC_RPATH/{show=1} show && /path /{print $2; show=0}' | grep -E "$root|/Users/runner|/private/var/folders|/tmp/" >/dev/null; then
    echo "$rel contains non-relocatable LC_RPATH:" >&2
    otool -l "$file" >&2
    failed=1
  fi
done < <(find "$root" -type f | sort)

exit "$failed"
