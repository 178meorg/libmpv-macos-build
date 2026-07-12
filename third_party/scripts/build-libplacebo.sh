#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

src="$(dep_src libplacebo)"
build="$(dep_build libplacebo)"
reset_build_dir "$build"
opts=(-Ddefault_library=shared)
while IFS= read -r opt; do opts+=("$opt"); done < <(meson_option_args "$src" \
  demos=false \
  tests=false \
  vulkan=disabled \
  opengl=enabled \
  d3d11=disabled \
  shaderc=disabled \
  glslang=disabled \
  lcms=enabled \
  dovi=enabled)
meson_setup "$build" "$src" "${opts[@]}"
"$MESON" compile -C "$build"
"$MESON" install -C "$build"
