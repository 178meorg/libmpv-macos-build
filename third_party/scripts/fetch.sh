#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

STRICT=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --strict) STRICT=1 ;;
    *) die "unknown option: $1" ;;
  esac
  shift
done

require_cmd curl
require_cmd shasum
require_cmd tar

download_dep() {
  local dep="$1"
  local url archive sha
  url="$(dep_var "$dep" URL)"
  sha="$(dep_var "$dep" SHA256)"
  archive="$(dep_archive "$dep")"
  [[ -n "$url" ]] || die "$dep has no URL"

  if [[ ! -f "$archive" ]]; then
    log "download $dep"
    curl -fL --retry 3 --connect-timeout 30 -o "$archive.tmp" "$url"
    mv "$archive.tmp" "$archive"
  fi

  if [[ -z "$sha" || "$sha" == "SKIP" ]]; then
    if [[ "$STRICT" == 1 ]]; then
      die "$dep has no SHA256; set $(upper_name "$dep")_SHA256 or do not use --strict"
    fi
    log "skip checksum for $dep"
  else
    echo "$sha  $archive" | shasum -a 256 -c -
  fi
}

extract_dep() {
  local dep="$1"
  local archive src marker
  archive="$(dep_archive "$dep")"
  src="$(dep_src "$dep")"
  marker="$src/.extract-complete"
  if [[ -f "$marker" ]]; then
    return
  fi
  log "extract $dep"
  rm -rf "$src"
  mkdir -p "$src"
  tar -xf "$archive" -C "$src" --strip-components 1
  touch "$marker"
}

for dep in $DEPS; do
  download_dep "$dep"
  extract_dep "$dep"
done
