#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

src="$(dep_src dav1d)"
build="$(dep_build dav1d)"
reset_build_dir "$build"
opts=(-Ddefault_library=shared)
while IFS= read -r opt; do opts+=("$opt"); done < <(meson_option_args "$src" \
  enable_tools=false \
  enable_tests=false)
meson_setup "$build" "$src" "${opts[@]}"
"$MESON" compile -C "$build"
"$MESON" install -C "$build"
