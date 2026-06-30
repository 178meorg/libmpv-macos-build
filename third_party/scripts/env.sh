#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
export THIRD_PARTY_ROOT="$PROJECT_ROOT/third_party"
export DEPS_MANIFEST="$THIRD_PARTY_ROOT/manifest/deps.env"

if [[ -f "$DEPS_MANIFEST" ]]; then
  # shellcheck disable=SC1090
  source "$DEPS_MANIFEST"
fi

export TARGET_ARCH="${TARGET_ARCH:-$(uname -m)}"
export DEPLOYMENT_TARGET="${DEPLOYMENT_TARGET:-${MACOSX_DEPLOYMENT_TARGET:-11.0}}"
export BUILD_PROFILE="${BUILD_PROFILE:-enhanced-lgpl}"
export HOST_TAG="macos-${TARGET_ARCH}"

export SRC_ARCHIVES="$THIRD_PARTY_ROOT/src/archives"
export SRC_EXTRACTED="$THIRD_PARTY_ROOT/src/extracted"
export BUILD_ROOT="$THIRD_PARTY_ROOT/build/$HOST_TAG"
export PREFIX="$THIRD_PARTY_ROOT/install/$HOST_TAG"
export TOOLS_PREFIX="$THIRD_PARTY_ROOT/tools/$HOST_TAG"
export LOG_ROOT="$THIRD_PARTY_ROOT/logs/$HOST_TAG"

mkdir -p "$SRC_ARCHIVES" "$SRC_EXTRACTED" "$BUILD_ROOT" "$PREFIX" "$TOOLS_PREFIX" "$LOG_ROOT"

if [[ "$(uname -s)" != "Darwin" ]]; then
  echo "This build target must run on macOS." >&2
  exit 1
fi

export SDKROOT="${SDKROOT:-$(xcrun --sdk macosx --show-sdk-path)}"
export MACOSX_DEPLOYMENT_TARGET="$DEPLOYMENT_TARGET"
export CC="${CC:-$(xcrun -f clang)}"
export CXX="${CXX:-$(xcrun -f clang++)}"
export AR="${AR:-$(xcrun -f ar)}"
export RANLIB="${RANLIB:-$(xcrun -f ranlib)}"
export STRIP="${STRIP:-$(xcrun -f strip)}"
export CMAKE="${CMAKE:-$(command -v cmake || true)}"
export PYTHON3="${PYTHON3:-$(command -v python3 || true)}"

export PATH="$TOOLS_PREFIX/bin:/usr/bin:/bin:/usr/sbin:/sbin"
export PKG_CONFIG="${PKG_CONFIG:-$TOOLS_PREFIX/bin/pkgconf}"
export PKG_CONFIG_LIBDIR="$PREFIX/lib/pkgconfig:$PREFIX/share/pkgconfig"
unset PKG_CONFIG_PATH

COMMON_MIN_FLAGS="-arch $TARGET_ARCH -isysroot $SDKROOT -mmacosx-version-min=$DEPLOYMENT_TARGET"
export CFLAGS="${CFLAGS:-$COMMON_MIN_FLAGS -O2 -fPIC}"
export CXXFLAGS="${CXXFLAGS:-$COMMON_MIN_FLAGS -O2 -fPIC -stdlib=libc++}"
export CPPFLAGS="${CPPFLAGS:-$COMMON_MIN_FLAGS -I$PREFIX/include}"
export LDFLAGS="${LDFLAGS:-$COMMON_MIN_FLAGS -L$PREFIX/lib -Wl,-rpath,@loader_path -Wl,-rpath,@loader_path/../lib -Wl,-rpath,@loader_path/../Frameworks}"

export CMAKE_GENERATOR="${CMAKE_GENERATOR:-Unix Makefiles}"
export MAKEFLAGS="${MAKEFLAGS:--j$(sysctl -n hw.logicalcpu)}"
export MESON="${MESON:-$TOOLS_PREFIX/bin/meson}"
export NINJA="${NINJA:-$TOOLS_PREFIX/bin/ninja}"
