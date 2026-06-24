#!/usr/bin/env bash

set -euo pipefail

TARGET="${MACOSX_DEPLOYMENT_TARGET:-11.0}"
ARCH=""

usage() {
  cat <<'EOF'
Usage:
  build_macos_libmpv_deps.sh --arch <arm64|x86_64> [--target <macos-version>]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --arch)
      ARCH="${2:-}"
      shift 2
      ;;
    --target)
      TARGET="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

case "$ARCH" in
  arm64|x86_64)
    ;;
  *)
    echo "--arch must be arm64 or x86_64" >&2
    exit 1
    ;;
esac

version_code() {
  local version="$1"
  local major=0
  local minor=0
  local patch=0

  IFS=. read -r major minor patch <<< "$version"
  major="${major:-0}"
  minor="${minor:-0}"
  patch="${patch:-0}"

  printf '%d\n' "$((10#$major * 10000 + 10#$minor * 100 + 10#$patch))"
}

dylib_minos() {
  local dylib="$1"
  local minos=""

  minos="$(otool -l "$dylib" | awk '/LC_BUILD_VERSION/{found=1} found && /minos/{print $2; exit}')"
  if [[ -z "$minos" ]]; then
    minos="$(otool -l "$dylib" | awk '/LC_VERSION_MIN_MACOSX/{found=1} found && /version/{print $2; exit}')"
  fi

  printf '%s\n' "$minos"
}

export MACOSX_DEPLOYMENT_TARGET="$TARGET"
export HOMEBREW_BUILD_FROM_SOURCE=1
export HOMEBREW_NO_INSTALL_FROM_API=1
export HOMEBREW_NO_INSTALLED_DEPENDENTS_CHECK=1
export HOMEBREW_NO_ANALYTICS=1

runtime_formulae=(
  ffmpeg
  freetype
  fribidi
  harfbuzz
  jpeg-turbo
  lcms2
  libarchive
  libass
  luajit
  mujs
  rubberband
  uchardet
  zimg
)

build_tool_formulae=(
  autoconf
  automake
  cmake
  libtool
  meson
  nasm
  ninja
  pkgconf
  python
  rust
)

array_contains() {
  local needle="$1"
  shift

  local item
  for item in "$@"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done

  return 1
}

echo "Building runtime dependencies from source for ${ARCH}, target macOS ${TARGET}"
mapfile -t dependency_formulae < <(
  {
    brew deps --formula --topological "${runtime_formulae[@]}"
    printf '%s\n' "${runtime_formulae[@]}"
  } | awk '!seen[$0]++'
)

for formula in "${dependency_formulae[@]}"; do
  if array_contains "$formula" "${build_tool_formulae[@]}"; then
    continue
  fi

  if brew list --versions "$formula" >/dev/null 2>&1; then
    brew reinstall --build-from-source "$formula"
  else
    brew install --build-from-source "$formula"
  fi
done

target_code="$(version_code "$TARGET")"
bad=0

echo "Verifying Homebrew-built runtime dylib deployment targets"
for formula in "${dependency_formulae[@]}"; do
  if array_contains "$formula" "${build_tool_formulae[@]}"; then
    continue
  fi

  prefix="$(brew --prefix "$formula" 2>/dev/null || true)"
  [[ -n "$prefix" && -d "$prefix/lib" ]] || continue

  while IFS= read -r dylib; do
    minos="$(dylib_minos "$dylib")"
    echo "${formula}: ${dylib#$prefix/}: minos ${minos:-unknown}"

    if [[ -z "$minos" ]]; then
      continue
    fi

    if [[ "$(version_code "$minos")" -gt "$target_code" ]]; then
      echo "Dependency ${dylib} was built for macOS ${minos}, above target ${TARGET}" >&2
      bad=1
    fi
  done < <(find "$prefix/lib" -maxdepth 1 -type f -name '*.dylib' | sort)
done

if [[ "$bad" -ne 0 ]]; then
  echo "One or more runtime dependencies are not compatible with macOS ${TARGET}" >&2
  exit 1
fi
