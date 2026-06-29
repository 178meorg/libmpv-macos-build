#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

src="$(dep_src libass)"
build="$(dep_build libass)"
reset_build_dir "$build"
pushd "$build" >/dev/null
"$src/configure" \
  --prefix="$PREFIX" \
  --enable-shared \
  --disable-static \
  --disable-fontconfig \
  --enable-coretext \
  --disable-require-system-font-provider
make $MAKEFLAGS
make install
popd >/dev/null
