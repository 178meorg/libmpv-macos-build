#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

src="$(dep_src zlib)"
build="$(dep_build zlib)"
reset_build_dir "$build"
pushd "$build" >/dev/null
"$src/configure" --prefix="$PREFIX" --shared
make $MAKEFLAGS
make install
popd >/dev/null
