#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_ARCH=""
DEPLOYMENT_TARGET="11.0"
BUILD_PROFILE="enhanced-lgpl"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --arch) TARGET_ARCH="$2"; shift ;;
    --target) DEPLOYMENT_TARGET="$2"; shift ;;
    --profile) BUILD_PROFILE="$2"; shift ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

[[ -n "$TARGET_ARCH" ]] || TARGET_ARCH="$(uname -m)"
export TARGET_ARCH DEPLOYMENT_TARGET BUILD_PROFILE

# shellcheck disable=SC1091
source "$SCRIPT_DIR/env.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

[[ "$BUILD_PROFILE" == "enhanced-lgpl" ]] || die "unsupported profile: $BUILD_PROFILE"

rm -rf "$PREFIX"
mkdir -p "$PREFIX"

"$SCRIPT_DIR/bootstrap-tools.sh"

build_order=(
  zlib
  freetype
  fribidi
  harfbuzz
  libass
  lcms2
  dav1d
  zimg
  uchardet
  lua
  libarchive
  libplacebo
  ffmpeg
  mpv
)

for dep in "${build_order[@]}"; do
  log "build $dep for $HOST_TAG"
  "$SCRIPT_DIR/build-$dep.sh"
done

"$SCRIPT_DIR/fix-install-names.sh"
