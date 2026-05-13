#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCH=""
OUTPUT_DIR=""
WORK_DIR="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"
MPV_VERSION="${MPV_VERSION:-0.38.0}"
IINA_DYLIBS_VERSION="${IINA_DYLIBS_VERSION:-}"
HEADERS_DIR=""
LIBS_DIR=""

usage() {
  cat <<'EOF'
Usage:
  package_libmpv.sh --arch <arm64|x86_64> --output-dir <dir> [--headers-dir <dir>] [--libs-dir <dir>] [--work-dir <dir>] [--mpv-version <version>] [--iina-dylibs-version <version>]
EOF
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
    --headers-dir)
      HEADERS_DIR="${2:-}"
      shift 2
      ;;
    --libs-dir)
      LIBS_DIR="${2:-}"
      shift 2
      ;;
    --work-dir)
      WORK_DIR="${2:-}"
      shift 2
      ;;
    --mpv-version)
      MPV_VERSION="${2:-}"
      shift 2
      ;;
    --iina-dylibs-version)
      IINA_DYLIBS_VERSION="${2:-}"
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

mkdir -p "$OUTPUT_DIR" "$WORK_DIR"

stage_dir="$(mktemp -d "${WORK_DIR%/}/libmpv-${ARCH}.XXXXXX")"
package_name="libmpv-${MPV_VERSION}-macos-${ARCH}"
package_root="${stage_dir}/${package_name}"
lib_dir="${package_root}/lib"
include_dir="${package_root}/include"
archive_path="${OUTPUT_DIR%/}/${package_name}.tar.gz"

mkdir -p "$lib_dir" "$include_dir"

if [[ -z "$LIBS_DIR" ]]; then
  LIBS_DIR="${stage_dir}/libs"
  "${SCRIPT_DIR}/download_iina_libs.sh" \
    --arch "$ARCH" \
    --output-dir "$LIBS_DIR" \
    --iina-dylibs-version "$IINA_DYLIBS_VERSION"
fi

if [[ -z "$HEADERS_DIR" ]]; then
  HEADERS_DIR="${stage_dir}/headers"
  "${SCRIPT_DIR}/fetch_mpv_headers.sh" \
    --output-dir "$HEADERS_DIR" \
    --work-dir "$stage_dir" \
    --mpv-version "$MPV_VERSION"
fi

if [[ ! -d "${HEADERS_DIR}/mpv" ]]; then
  echo "Failed to locate mpv headers directory at ${HEADERS_DIR}/mpv" >&2
  exit 1
fi

if ! find "$LIBS_DIR" -maxdepth 1 -type f -name '*.dylib' | grep -q .; then
  echo "Failed to locate dylibs in ${LIBS_DIR}" >&2
  exit 1
fi

mkdir -p "${include_dir}/mpv"
cp "${HEADERS_DIR}/mpv/"*.h "${include_dir}/mpv/"
cp "${LIBS_DIR}/"*.dylib "$lib_dir/"

tar -C "$stage_dir" -czf "$archive_path" "$package_name"

echo "Created ${archive_path}"
