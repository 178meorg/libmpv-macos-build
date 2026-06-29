#!/usr/bin/env bash
set -euo pipefail

root="${1:-}"
target="${2:-11.0}"
[[ -n "$root" ]] || { echo "usage: $0 <path> <target>" >&2; exit 1; }

version_code() {
  local major minor patch
  IFS=. read -r major minor patch <<< "$1"
  major="${major:-0}"
  minor="${minor:-0}"
  patch="${patch:-0}"
  echo "$((10#$major * 10000 + 10#$minor * 100 + 10#$patch))"
}

target_code="$(version_code "$target")"
failed=0

while IFS= read -r file; do
  if ! file "$file" | grep -q 'Mach-O'; then
    continue
  fi
  minos="$(otool -l "$file" | awk '/LC_BUILD_VERSION/{found=1} found && /minos/{print $2; exit}')"
  if [[ -z "$minos" ]]; then
    minos="$(otool -l "$file" | awk '/LC_VERSION_MIN_MACOSX/{found=1} found && /version/{print $2; exit}')"
  fi
  rel="${file#$root/}"
  echo "$rel: minos ${minos:-unknown}"
  if [[ -z "$minos" ]]; then
    echo "$rel has no macOS min version load command" >&2
    failed=1
  elif [[ "$(version_code "$minos")" -gt "$target_code" ]]; then
    echo "$rel minos $minos is above target $target" >&2
    failed=1
  fi
done < <(find "$root" -type f | sort)

exit "$failed"
