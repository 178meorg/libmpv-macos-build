#!/usr/bin/env bash

set -euo pipefail

SOURCE_DIR="${1:-}"

if [[ -z "$SOURCE_DIR" ]]; then
  echo "Usage: build_macos_libmpv_qt.sh <mpv-source-dir>" >&2
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
: "${MACOSX_DEPLOYMENT_TARGET:=11.0}"
export CFLAGS CXXFLAGS CPPFLAGS LDFLAGS MACOSX_DEPLOYMENT_TARGET

. ./ci/build-common.sh

MPV_INSTALL_PREFIX="${HOME}/out/mpv"
MPV_VARIANT="${TRAVIS_OS_NAME:-local}"

filtered_common_args=()
read -r -a common_args_words <<< "$common_args"
for arg in "${common_args_words[@]}"; do
  if [[ "$arg" == "--werror" ]]; then
    continue
  fi

  filtered_common_args+=("$arg")
done

if [[ -d "./build/${MPV_VARIANT}" ]]; then
  rm -rf "./build/${MPV_VARIANT}"
fi

# mpv v0.41.0 compiles the macOS clipboard backend whenever Cocoa is enabled,
# but that backend includes the Swift-generated osdep/mac/swift.h header. Keep
# Cocoa/GL-Cocoa for VideoToolbox OpenGL interop while removing this Swift-only
# clipboard backend from the libmpv-oriented build.
perl -0pi -e "s/,\\s*'player\\/clipboard\\/clipboard-mac\\.m'//g" meson.build
perl -0pi -e 's/#if HAVE_COCOA\s*\n\s*&clipboard_backend_mac,/#if HAVE_COCOA \&\& HAVE_SWIFT_BUILD\n    \&clipboard_backend_mac,/g' \
  player/clipboard/clipboard.c
if grep -q "player/clipboard/clipboard-mac.m" meson.build; then
  echo "Failed to remove Swift-backed macOS clipboard source from meson.build" >&2
  exit 1
fi
if ! grep -q "HAVE_COCOA && HAVE_SWIFT_BUILD" player/clipboard/clipboard.c; then
  echo "Failed to guard macOS clipboard backend behind HAVE_SWIFT_BUILD" >&2
  exit 1
fi

meson_args=(
  -Dprefix="${MPV_INSTALL_PREFIX}"
  -Dwerror=false
  -Dcplayer=false
  -Dlibmpv=true
  -Dtests=false
  -Dobjc_args="-Wno-error=deprecated -Wno-error=deprecated-declarations"
  -Dgl=enabled
  -Diconv=enabled
  -Dcaca=disabled
  -Dlcms2=enabled
  -Dlibarchive=enabled
  -Dlibavdevice=disabled
  -Dlua=enabled
  -Djpeg=enabled
  -Dplain-gl=enabled
  -Drubberband=enabled
  -Dzimg=enabled
  -Dzlib=enabled
  -Dcocoa=enabled
  -Dcoreaudio=enabled
  -Dgl-cocoa=enabled
  -Dvideotoolbox-gl=enabled
  -Dvideotoolbox-pl=enabled
  -Dvulkan=enabled
  -Dmacos-cocoa-cb=disabled
  -Dmacos-media-player=disabled
  -Dmacos-touchbar=disabled
  -Dswift-build=disabled
  -Dcdda=disabled
  -Ddvdnav=disabled
  -Dlibbluray=disabled
)

PKG_CONFIG_PATH="$(brew --prefix libarchive)/lib/pkgconfig/" CC="${CC:-cc}" CXX="${CXX:-c++}" \
  meson setup build "${filtered_common_args[@]}" "${meson_args[@]}"

meson compile -C build -j4
meson install -C build

popd >/dev/null
