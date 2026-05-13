#!/usr/bin/env bash

set -euo pipefail

ARCH="universal"
OUTPUT_DIR=""
IINA_DYLIBS_VERSION="${IINA_DYLIBS_VERSION:-}"

usage() {
  cat <<'EOF'
Usage:
  download_iina_libs.sh --arch <universal|arm64|x86_64> --output-dir <dir> [--iina-dylibs-version <version>]

Options:
  --arch                  IINA dylib architecture to download.
  --output-dir            Destination directory for downloaded dylibs.
  --iina-dylibs-version   Optional IINA dylib version path segment.
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
  universal|arm64|x86_64)
    ;;
  *)
    echo "Unsupported arch: $ARCH" >&2
    exit 1
    ;;
esac

if [[ -z "$OUTPUT_DIR" ]]; then
  echo "--output-dir is required" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"

base_url="https://iina.io/dylibs"
if [[ -n "$IINA_DYLIBS_VERSION" ]]; then
  base_url="${base_url}/${IINA_DYLIBS_VERSION}"
fi
base_url="${base_url}/${ARCH}"

manifest_file="$(mktemp)"
cleanup() {
  rm -f "$manifest_file"
}
trap cleanup EXIT

fetch_manifest() {
  local url="$1"
  curl -fsSL --retry 5 --retry-delay 2 "$url" -o "$manifest_file"
}

if ! fetch_manifest "${base_url}/filelist.txt"; then
  fetch_manifest "${base_url}/fileList.txt"
fi

downloaded=0
while IFS= read -r line; do
  line="${line#"${line%%[![:space:]]*}"}"
  line="${line%"${line##*[![:space:]]}"}"

  if [[ -z "$line" || "${line:0:1}" == "#" ]]; then
    continue
  fi

  entry="${line%%[[:space:]]*}"
  if [[ "$entry" != *.dylib ]]; then
    continue
  fi

  if [[ "$entry" =~ ^https?:// ]]; then
    file_url="$entry"
    file_name="${entry##*/}"
  else
    file_url="${base_url}/${entry}"
    file_name="${entry##*/}"
  fi

  curl -fsSL --retry 5 --retry-delay 2 "$file_url" -o "${OUTPUT_DIR}/${file_name}"
  downloaded=$((downloaded + 1))
done < "$manifest_file"

if [[ "$downloaded" -eq 0 ]]; then
  echo "No dylibs downloaded from ${base_url}" >&2
  exit 1
fi

echo "Downloaded ${downloaded} dylib(s) to ${OUTPUT_DIR}"
