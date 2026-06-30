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
require_cmd git
require_cmd shasum
require_cmd tar

download_dep() {
  local dep="$1"
  local url archive sha
  if [[ -n "$(dep_var "$dep" GIT_URL)" ]]; then
    return
  fi
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
  local git_url git_ref
  git_url="$(dep_var "$dep" GIT_URL)"
  if [[ -n "$git_url" ]]; then
    git_ref="$(dep_var "$dep" REF)"
    [[ -n "$git_ref" ]] || die "$dep has GIT_URL but no REF"
    src="$(dep_src "$dep")"
    marker="$src/.git-fetch-ref"
    if [[ -d "$src/.git" && -f "$marker" && "$(cat "$marker")" == "$git_ref" ]]; then
      return
    fi
    log "clone $dep@$git_ref"
    rm -rf "$src"
    git clone --branch "$git_ref" --depth 1 "$git_url" "$src"
    git -C "$src" submodule update --init --recursive
    echo "$git_ref" > "$marker"
    return
  fi

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
