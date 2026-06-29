#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

src="$(dep_src lcms2)"
build="$(dep_build lcms2)"
reset_build_dir "$build"
pushd "$build" >/dev/null
"$src/configure" --prefix="$PREFIX" --enable-shared --disable-static
make $MAKEFLAGS
make install
popd >/dev/null
