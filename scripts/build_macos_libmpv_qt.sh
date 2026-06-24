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

meson_args=(
  -Dprefix="${MPV_INSTALL_PREFIX}"
  -Dwerror=false
  -Dcplayer=false
  -Dlibmpv=true
  -Dtests=false
  -Dobjc_args="-Wno-error=deprecated -Wno-error=deprecated-declarations"
  -Dgl=enabled
  -Diconv=enabled
  -Dlcms2=enabled
  -Dlibarchive=enabled
  -Dlua=enabled
  -Djpeg=enabled
  -Dplain-gl=enabled
  -Drubberband=enabled
  -Dzimg=enabled
  -Dzlib=enabled
  -Dcocoa=disabled
  -Dcoreaudio=enabled
  -Dgl-cocoa=disabled
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
