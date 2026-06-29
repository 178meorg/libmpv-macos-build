#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

src="$(dep_src ffmpeg)"
build="$(dep_build ffmpeg)"
reset_build_dir "$build"
pushd "$build" >/dev/null
"$src/configure" \
  --prefix="$PREFIX" \
  --cc="$CC" \
  --cxx="$CXX" \
  --pkg-config="$PKG_CONFIG" \
  --extra-cflags="$CFLAGS" \
  --extra-cxxflags="$CXXFLAGS" \
  --extra-ldflags="$LDFLAGS" \
  --arch="$TARGET_ARCH" \
  --target-os=darwin \
  --enable-shared \
  --disable-static \
  --enable-pic \
  --disable-doc \
  --disable-programs \
  --disable-devices \
  --disable-avdevice \
  --disable-encoders \
  --disable-muxers \
  --disable-postproc \
  --disable-gpl \
  --disable-nonfree \
  --enable-zlib \
  --enable-securetransport \
  --enable-videotoolbox \
  --enable-audiotoolbox \
  --enable-libdav1d \
  --install-name-dir='@rpath'
make $MAKEFLAGS
make install
popd >/dev/null
