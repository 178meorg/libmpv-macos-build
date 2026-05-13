#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCH=""
OUTPUT_DIR=""
WORK_DIR="${RUNNER_TEMP:-${TMPDIR:-/tmp}}"
MPV_VERSION="${MPV_VERSION:-0.38.0}"
IINA_DYLIBS_VERSION="${IINA_DYLIBS_VERSION:-}"

usage() {
  cat <<'EOF'
Usage:
  package_libmpv.sh --arch <arm64|x86_64> --output-dir <dir> [--work-dir <dir>] [--mpv-version <version>] [--iina-dylibs-version <version>]
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

"${SCRIPT_DIR}/download_iina_libs.sh" \
  --arch "$ARCH" \
  --output-dir "$lib_dir" \
  --iina-dylibs-version "$IINA_DYLIBS_VERSION"

mpv_archive="${stage_dir}/mpv-${MPV_VERSION}.tar.gz"
curl -fsSL --retry 5 --retry-delay 2 \
  "https://github.com/mpv-player/mpv/archive/refs/tags/v${MPV_VERSION}.tar.gz" \
  -o "$mpv_archive"

tar -xzf "$mpv_archive" -C "$stage_dir"
mpv_source_dir="$(find "$stage_dir" -maxdepth 1 -mindepth 1 -type d -name 'mpv-*' | head -n 1)"

if [[ -z "$mpv_source_dir" ]]; then
  echo "Failed to locate extracted mpv source directory" >&2
  exit 1
fi

header_source_dir=""
if [[ -d "${mpv_source_dir}/include/mpv" ]]; then
  header_source_dir="${mpv_source_dir}/include/mpv"
elif [[ -d "${mpv_source_dir}/libmpv" ]]; then
  header_source_dir="${mpv_source_dir}/libmpv"
else
  echo "Failed to locate mpv public headers in source archive" >&2
  exit 1
fi

mkdir -p "${include_dir}/mpv"
cp "${header_source_dir}"/*.h "${include_dir}/mpv/"

tar -C "$stage_dir" -czf "$archive_path" "$package_name"

echo "Created ${archive_path}"
