#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

src="$(dep_src libarchive)"
build="$(dep_build libarchive)"
reset_build_dir "$build"
cmake_setup "$build" "$src" \
  -DBUILD_SHARED_LIBS=ON \
  -DENABLE_TEST=OFF \
  -DENABLE_TAR=OFF \
  -DENABLE_CPIO=OFF \
  -DENABLE_CAT=OFF \
  -DENABLE_OPENSSL=OFF \
  -DENABLE_MBEDTLS=OFF \
  -DENABLE_NETTLE=OFF \
  -DENABLE_BZip2=OFF \
  -DENABLE_LZMA=OFF \
  -DENABLE_LZ4=OFF \
  -DENABLE_ZSTD=OFF \
  -DENABLE_EXPAT=OFF \
  -DENABLE_LIBXML2=OFF \
  -DENABLE_PCREPOSIX=OFF
"$CMAKE" --build "$build" --parallel
"$CMAKE" --install "$build"
