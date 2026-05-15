#!/usr/bin/env bash

set -euo pipefail

ARCH=""
OUTPUT_DIR=""
WORK_DIR="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"
MPV_VERSION="${MPV_VERSION:-}"
INSTALL_PREFIX=""
SOURCE_DIR=""

usage() {
  cat <<'EOF'
Usage:
  package_libmpv.sh --arch <arm64|x86_64> --install-prefix <dir> --output-dir <dir> [--source-dir <dir>] [--work-dir <dir>] [--version <version>]
EOF
}

detect_version() {
  local source_dir="$1"
  local version=""
  local version_file=""

  version_file="$(find "$source_dir" -path '*/common/version.h' -type f | head -n 1)"
  if [[ -n "$version_file" ]]; then
    version="$(grep VERSION "$version_file" | cut -d'"' -f2)"
  fi

  if [[ -z "$version" && -f "${source_dir}/MPV_VERSION" ]]; then
    version="$(tr -d '\r\n' < "${source_dir}/MPV_VERSION")"
  fi

  printf '%s' "$version"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --arch)
      ARCH="${2:-}"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="${2:-}"
      shift 2
      ;;
    --install-prefix)
      INSTALL_PREFIX="${2:-}"
      shift 2
      ;;
    --work-dir)
      WORK_DIR="${2:-}"
      shift 2
      ;;
    --source-dir)
      SOURCE_DIR="${2:-}"
      shift 2
      ;;
    --version)
      MPV_VERSION="${2:-}"
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

if [[ -z "$OUTPUT_DIR" ]]; then
  echo "--output-dir is required" >&2
  exit 1
fi

if [[ -z "$INSTALL_PREFIX" ]]; then
  echo "--install-prefix is required" >&2
  exit 1
fi

if [[ -z "$MPV_VERSION" && -n "$SOURCE_DIR" ]]; then
  MPV_VERSION="$(detect_version "$SOURCE_DIR")"
fi

if [[ -z "$MPV_VERSION" ]]; then
  echo "Unable to determine mpv version, pass --version or --source-dir" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR" "$WORK_DIR"

stage_dir="$(mktemp -d "${WORK_DIR%/}/libmpv-${ARCH}.XXXXXX")"
package_name="libmpv-${MPV_VERSION}-macos-${ARCH}"
package_root="${stage_dir}/${package_name}"
lib_dir="${package_root}/lib"
include_dir="${package_root}/include"
archive_path="${OUTPUT_DIR%/}/${package_name}.tar.gz"

mkdir -p "$lib_dir" "$include_dir"

if [[ ! -d "${INSTALL_PREFIX}/include/mpv" ]]; then
  echo "Failed to locate mpv headers directory at ${INSTALL_PREFIX}/include/mpv" >&2
  exit 1
fi

shopt -s nullglob
dylibs=("${INSTALL_PREFIX}/lib"/libmpv*.dylib)
shopt -u nullglob

if [[ "${#dylibs[@]}" -eq 0 ]]; then
  echo "Failed to locate libmpv dylibs in ${INSTALL_PREFIX}/lib" >&2
  exit 1
fi

mkdir -p "${include_dir}/mpv"
cp "${INSTALL_PREFIX}/include/mpv/"*.h "${include_dir}/mpv/"
cp -P "${dylibs[@]}" "$lib_dir/"

if [[ -f "${INSTALL_PREFIX}/lib/pkgconfig/mpv.pc" ]]; then
  mkdir -p "${lib_dir}/pkgconfig"
  cp "${INSTALL_PREFIX}/lib/pkgconfig/mpv.pc" "${lib_dir}/pkgconfig/"
fi

tar -C "$stage_dir" -czf "$archive_path" "$package_name"

echo "Created ${archive_path}"
