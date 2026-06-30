#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

src="$(dep_src uchardet)"
build="$(dep_build uchardet)"
reset_build_dir "$build"
cmake_setup "$build" "$src" \
  -DBUILD_SHARED_LIBS=ON \
  -DBUILD_BINARY=OFF
"$CMAKE" --build "$build" --parallel
"$CMAKE" --install "$build"
