#!/usr/bin/env bash
set -euo pipefail

if [[ -z "${THIRD_PARTY_ROOT:-}" ]]; then
  # shellcheck disable=SC1091
  source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
fi

log() {
  printf '[%s] %s\n' "$(date +%H:%M:%S)" "$*"
}

die() {
  echo "error: $*" >&2
  exit 1
}

upper_name() {
  echo "$1" | tr '[:lower:]-' '[:upper:]_'
}

dep_var() {
  local dep="$1"
  local key="$2"
  local var
  var="$(upper_name "$dep")_${key}"
  printf '%s' "${!var:-}"
}

dep_archive() {
  local dep="$1"
  local url
  url="$(dep_var "$dep" URL)"
  [[ -n "$url" ]] || die "missing URL for $dep"
  printf '%s/%s-%s' "$SRC_ARCHIVES" "$dep" "${url##*/}"
}

dep_src() {
  local dep="$1"
  local version
  version="$(dep_var "$dep" VERSION)"
  [[ -n "$version" ]] || die "missing VERSION for $dep"
  printf '%s/%s-%s' "$SRC_EXTRACTED" "$dep" "$version"
}

dep_build() {
  local dep="$1"
  printf '%s/%s' "$BUILD_ROOT" "$dep"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || die "missing required command: $1"
}

run_logged() {
  local name="$1"
  shift
  mkdir -p "$LOG_ROOT"
  log "$name"
  "$@" 2>&1 | tee "$LOG_ROOT/$name.log"
}

reset_build_dir() {
  local dir="$1"
  rm -rf "$dir"
  mkdir -p "$dir"
}

meson_setup() {
  local build_dir="$1"
  local src_dir="$2"
  shift 2
  "$MESON" setup "$build_dir" "$src_dir" \
    --prefix "$PREFIX" \
    --libdir lib \
    --buildtype release \
    "$@"
}

meson_option_args() {
  local src_dir="$1"
  shift
  local opt_file=""
  if [[ -f "$src_dir/meson_options.txt" ]]; then
    opt_file="$src_dir/meson_options.txt"
  elif [[ -f "$src_dir/meson.options" ]]; then
    opt_file="$src_dir/meson.options"
  fi
  [[ -n "$opt_file" ]] || return 0

  local item name
  for item in "$@"; do
    name="${item%%=*}"
    if grep -Eq "option\\(['\"]${name}['\"]" "$opt_file"; then
      printf '%s\n' "-D$item"
    else
      log "skip unsupported Meson option $name for $(basename "$src_dir")" >&2
    fi
  done
}

cmake_setup() {
  local build_dir="$1"
  local src_dir="$2"
  shift 2
  [[ -n "${CMAKE:-}" ]] || die "cmake is required as a host build tool"
  "$CMAKE" -S "$src_dir" -B "$build_dir" \
    -G "$CMAKE_GENERATOR" \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_OSX_ARCHITECTURES="$TARGET_ARCH" \
    -DCMAKE_OSX_DEPLOYMENT_TARGET="$DEPLOYMENT_TARGET" \
    -DCMAKE_OSX_SYSROOT="$SDKROOT" \
    -DCMAKE_PREFIX_PATH="$PREFIX" \
    -DCMAKE_INSTALL_RPATH="@loader_path;@loader_path/../lib;@loader_path/../Frameworks" \
    "$@"
}
