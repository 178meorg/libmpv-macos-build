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
  local urls url archive sha
  if [[ -n "$(dep_var "$dep" GIT_URL)" ]]; then
    return
  fi
  urls="$(dep_var "$dep" URLS)"
  if [[ -z "$urls" ]]; then
    urls="$(dep_var "$dep" URL)"
  fi
  sha="$(dep_var "$dep" SHA256)"
  archive="$(dep_archive "$dep")"
  [[ -n "$urls" ]] || die "$dep has no URL"

  if [[ ! -f "$archive" ]]; then
    log "download $dep"
    for url in $urls; do
      rm -f "$archive.tmp"
      if curl -fL --retry 2 --connect-timeout 15 --max-time 60 -o "$archive.tmp" "$url"; then
        mv "$archive.tmp" "$archive"
        break
      fi
      log "download failed for $dep from $url"
    done
    [[ -f "$archive" ]] || die "failed to download $dep"
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
  local git_url git_ref clone_ref
  git_url="$(dep_var "$dep" GIT_URL)"
  if [[ -n "$git_url" ]]; then
    git_ref="$(dep_var "$dep" REF)"
    [[ -n "$git_ref" ]] || die "$dep has GIT_URL but no REF"
    clone_ref="$git_ref"
    if [[ "$dep" == "mpv" ]]; then
      clone_ref="$(dep_var "$dep" SOURCE_REF)"
      [[ -n "$clone_ref" ]] || clone_ref="master"
    fi
    src="$(dep_src "$dep")"
    marker="$src/.git-fetch-ref"
    if [[ -d "$src/.git" && -f "$marker" && "$(cat "$marker")" == "$clone_ref" ]]; then
      return
    fi
    log "clone $dep@$clone_ref"
    rm -rf "$src"
    git clone --branch "$clone_ref" --depth 1 "$git_url" "$src"
    git -C "$src" submodule update --init --recursive
    echo "$clone_ref" > "$marker"
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
