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

is_system_dependency() {
  case "$1" in
    /usr/lib/*|/System/Library/*)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

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

resolve_dependency_source() {
  local dep="$1"
  local dep_base="${dep##*/}"
  local candidate=""

  if [[ "$dep" == @* ]]; then
    if [[ -e "${INSTALL_PREFIX}/lib/${dep_base}" ]]; then
      printf '%s\n' "${INSTALL_PREFIX}/lib/${dep_base}"
      return 0
    fi

    candidate="$(find "${INSTALL_PREFIX}/lib" -maxdepth 1 \( -type f -o -type l \) -name "$dep_base" | head -n 1)"
    if [[ -n "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  fi

  if [[ -e "$dep" ]]; then
    printf '%s\n' "$dep"
    return 0
  fi

  if [[ -e "${INSTALL_PREFIX}/lib/${dep_base}" ]]; then
    printf '%s\n' "${INSTALL_PREFIX}/lib/${dep_base}"
    return 0
  fi

  candidate="$(find "${INSTALL_PREFIX}/lib" -maxdepth 1 \( -type f -o -type l \) -name "$dep_base" | head -n 1)"
  if [[ -n "$candidate" ]]; then
    printf '%s\n' "$candidate"
    return 0
  fi

  return 1
}

collect_dylib_closure() {
  local root="$1"
  local queue=("$root")
  local processed=()
  local index=0

  while [[ "$index" -lt "${#queue[@]}" ]]; do
    local source="${queue[$index]}"
    index=$((index + 1))

    if [[ "${#processed[@]}" -gt 0 ]] && array_contains "$source" "${processed[@]}"; then
      continue
    fi

    processed+=("$source")

    local dest="${lib_dir}/$(basename "$source")"
    if [[ -e "$dest" ]]; then
      if ! cmp -s "$source" "$dest"; then
        echo "Dependency basename collision at ${dest}" >&2
        exit 1
      fi
    else
      cp -L "$source" "$dest"
    fi

    while IFS= read -r dep; do
      [[ -z "$dep" ]] && continue

      if is_system_dependency "$dep"; then
        continue
      fi

      if resolved="$(resolve_dependency_source "$dep")"; then
        if ! array_contains "$resolved" "${processed[@]}" && ! array_contains "$resolved" "${queue[@]}"; then
          queue+=("$resolved")
        fi
      else
        echo "Warning: unable to resolve dependency ${dep} referenced by ${source}" >&2
      fi
    done < <(otool -L "$source" | tail -n +2 | awk '{print $1}')
  done

  local source dest base dep resolved dep_base
  for source in "${processed[@]}"; do
    base="$(basename "$source")"
    dest="${lib_dir}/${base}"

    install_name_tool -id "@loader_path/${base}" "$dest"

    while IFS= read -r dep; do
      [[ -z "$dep" ]] && continue

      if is_system_dependency "$dep"; then
        continue
      fi

      if ! resolved="$(resolve_dependency_source "$dep")"; then
        continue
      fi

      dep_base="$(basename "$resolved")"
      install_name_tool -change "$dep" "@loader_path/${dep_base}" "$dest"
    done < <(otool -L "$source" | tail -n +2 | awk '{print $1}')
  done
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

if [[ ! -e "${INSTALL_PREFIX}/lib/libmpv.dylib" ]]; then
  echo "Failed to locate ${INSTALL_PREFIX}/lib/libmpv.dylib" >&2
  exit 1
fi

mkdir -p "${include_dir}/mpv"
cp "${INSTALL_PREFIX}/include/mpv/"*.h "${include_dir}/mpv/"

collect_dylib_closure "${INSTALL_PREFIX}/lib/libmpv.dylib"

if [[ -f "${INSTALL_PREFIX}/lib/pkgconfig/mpv.pc" ]]; then
  mkdir -p "${lib_dir}/pkgconfig"
  cp "${INSTALL_PREFIX}/lib/pkgconfig/mpv.pc" "${lib_dir}/pkgconfig/"
fi

tar -C "$stage_dir" -czf "$archive_path" "$package_name"

echo "Created ${archive_path}"
