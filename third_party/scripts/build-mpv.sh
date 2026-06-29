#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

src="$(dep_src mpv)"
build="$(dep_build mpv)"
reset_build_dir "$build"

opts=(
  -Ddefault_library=shared
)
while IFS= read -r opt; do opts+=("$opt"); done < <(meson_option_args "$src" \
  libmpv=true \
  cplayer=false \
  gpl=false \
  build-date=false \
  tests=false \
  gl=enabled \
  plain-gl=enabled \
  libass=enabled \
  lcms2=enabled \
  libplacebo=enabled \
  lua=enabled \
  zimg=enabled \
  uchardet=enabled \
  libarchive=enabled \
  javascript=disabled \
  rubberband=disabled \
  dvdnav=disabled \
  cdda=disabled \
  libavdevice=disabled \
  videotoolbox-gl=enabled \
  videotoolbox-pl=enabled \
  html-build=disabled \
  manpage-build=disabled \
  pdf-build=disabled)

meson_setup "$build" "$src" "${opts[@]}"
"$MESON" compile -C "$build"
"$MESON" install -C "$build"
