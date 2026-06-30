#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

require_cmd install_name_tool
require_cmd otool

if [[ ! -d "$PREFIX/lib" ]]; then
  exit 0
fi

while IFS= read -r dylib; do
  base="$(basename "$dylib")"
  log "fix install name $base"
  install_name_tool -id "@rpath/$base" "$dylib" || true
done < <(find "$PREFIX/lib" -maxdepth 1 -type f -name '*.dylib' | sort)

while IFS= read -r mach; do
  while IFS= read -r dep; do
    case "$dep" in
      "$PREFIX"/lib/*.dylib)
        install_name_tool -change "$dep" "@rpath/$(basename "$dep")" "$mach" || true
        ;;
    esac
  done < <(otool -L "$mach" | tail -n +2 | awk '{print $1}')
done < <(find "$PREFIX" -type f | while IFS= read -r file; do
  if file "$file" | grep -q 'Mach-O'; then
    echo "$file"
  fi
done)
