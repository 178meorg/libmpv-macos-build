#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

src="$(dep_src freetype)"
build="$(dep_build freetype)"
reset_build_dir "$build"
cmake_setup "$build" "$src" \
  -DBUILD_SHARED_LIBS=ON \
  -DFT_REQUIRE_ZLIB=TRUE \
  -DFT_DISABLE_BZIP2=TRUE \
  -DFT_DISABLE_PNG=TRUE \
  -DFT_DISABLE_HARFBUZZ=TRUE \
  -DFT_DISABLE_BROTLI=TRUE
"$CMAKE" --build "$build" --parallel
"$CMAKE" --install "$build"
