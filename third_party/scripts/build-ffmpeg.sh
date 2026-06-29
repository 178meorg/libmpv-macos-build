#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

src="$(dep_src ffmpeg)"
build="$(dep_build ffmpeg)"
arch_options=()
if [[ "$TARGET_ARCH" == "arm64" ]]; then
  arch_options+=(--enable-neon)
fi

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
  --disable-autodetect \
  --enable-shared \
  --disable-static \
  --enable-pic \
  --enable-small \
  --enable-optimizations \
  --enable-network \
  --enable-pthreads \
  --enable-safe-bitstream-reader \
  --disable-debug \
  --disable-stripping \
  --disable-doc \
  --disable-programs \
  --disable-devices \
  --disable-avdevice \
  --disable-encoders \
  --disable-muxers \
  --disable-gpl \
  --disable-nonfree \
  --enable-zlib \
  --enable-securetransport \
  --enable-videotoolbox \
  --enable-audiotoolbox \
  --enable-libdav1d \
  "${arch_options[@]}" \
  --install-name-dir='@rpath'
make $MAKEFLAGS
make install
popd >/dev/null
