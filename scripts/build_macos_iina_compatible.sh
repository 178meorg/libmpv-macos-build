#!/usr/bin/env bash

set -euo pipefail

SOURCE_DIR="${1:-}"

if [[ -z "$SOURCE_DIR" ]]; then
  echo "Usage: build_macos_iina_compatible.sh <mpv-source-dir>" >&2
  exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
  echo "Failed to locate mpv source directory at ${SOURCE_DIR}" >&2
  exit 1
fi

pushd "$SOURCE_DIR" >/dev/null

# Upstream ci/build-common.sh appends to these variables directly, which
# trips set -u if the caller did not define them in the environment.
: "${CFLAGS:=}"
: "${CXXFLAGS:=}"
: "${CPPFLAGS:=}"
: "${LDFLAGS:=}"
export CFLAGS CXXFLAGS CPPFLAGS LDFLAGS

. ./ci/build-common.sh

MPV_INSTALL_PREFIX="${HOME}/out/mpv"
MPV_VARIANT="${TRAVIS_OS_NAME:-local}"

if [[ -d "./build/${MPV_VARIANT}" ]]; then
  rm -rf "./build/${MPV_VARIANT}"
fi

PKG_CONFIG_PATH="$(brew --prefix libarchive)/lib/pkgconfig/" CC="${CC:-cc}" CXX="${CXX:-c++}" \
meson setup build $common_args \
  -Dprefix="${MPV_INSTALL_PREFIX}" \
  -Dobjc_args="-Wno-error=deprecated -Wno-error=deprecated-declarations" \
  -D{dvdnav,gl,iconv,lcms2,libarchive,libbluray,lua,jpeg}=enabled \
  -D{plain-gl,rubberband,zimg,zlib}=enabled \
  -D{cocoa,coreaudio,gl-cocoa,videotoolbox-gl,videotoolbox-pl}=enabled \
  -D{swift-build,macos-cocoa-cb,macos-media-player,macos-touchbar,vulkan}=enabled \
  -D{caca,cdda}=disabled \
  -Dswift-flags="${SWIFT_FLAGS:-}"

meson compile -C build -j4
meson install -C build
./build/mpv -v --no-config

popd >/dev/null
