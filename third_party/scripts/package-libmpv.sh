#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_ARCH=""
DEPLOYMENT_TARGET="11.0"
BUILD_PROFILE="enhanced-lgpl"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --arch) TARGET_ARCH="$2"; shift ;;
    --target) DEPLOYMENT_TARGET="$2"; shift ;;
    --profile) BUILD_PROFILE="$2"; shift ;;
    *) echo "unknown option: $1" >&2; exit 1 ;;
  esac
  shift
done

[[ -n "$TARGET_ARCH" ]] || TARGET_ARCH="$(uname -m)"
export TARGET_ARCH DEPLOYMENT_TARGET BUILD_PROFILE

# shellcheck disable=SC1091
source "$SCRIPT_DIR/env.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

[[ "$BUILD_PROFILE" == "enhanced-lgpl" ]] || die "unsupported profile: $BUILD_PROFILE"
[[ -d "$PREFIX/lib" ]] || die "missing install prefix: $PREFIX"
[[ -e "$PREFIX/lib/libmpv.dylib" || -L "$PREFIX/lib/libmpv.dylib" ]] || die "missing libmpv.dylib in $PREFIX/lib"

safe_ref="${MPV_REF:-v$MPV_VERSION}"
safe_ref="${safe_ref//\//-}"
pkg_name="libmpv-${safe_ref}-macos-${TARGET_ARCH}"
stage="$THIRD_PARTY_ROOT/build/package/$pkg_name"
out_dir="$PROJECT_ROOT/dist"

rm -rf "$stage"
mkdir -p "$stage" "$out_dir"

mkdir -p "$stage/lib" "$stage/include" "$stage/lib/pkgconfig" "$stage/licenses"

resolve_prefix_dylib() {
  local dep="$1"
  local base
  case "$dep" in
    "$PREFIX"/lib/*.dylib)
      printf '%s\n' "$dep"
      ;;
    @rpath/*.dylib|@loader_path/*.dylib|@loader_path/../lib/*.dylib|@loader_path/../Frameworks/*.dylib)
      base="$(basename "$dep")"
      if [[ -e "$PREFIX/lib/$base" || -L "$PREFIX/lib/$base" ]]; then
        printf '%s\n' "$PREFIX/lib/$base"
      fi
      ;;
  esac
}

copy_dylib_closure() {
  local queue=("$PREFIX/lib/libmpv.dylib")
  if [[ -e "$PREFIX/lib/libmpv.2.dylib" || -L "$PREFIX/lib/libmpv.2.dylib" ]]; then
    queue+=("$PREFIX/lib/libmpv.2.dylib")
  fi

  local seen="|"
  local idx=0
  local dylib dep resolved target
  while [[ "$idx" -lt "${#queue[@]}" ]]; do
    dylib="${queue[$idx]}"
    idx=$((idx + 1))
    [[ -e "$dylib" || -L "$dylib" ]] || continue
    case "$seen" in
      *"|$dylib|"*) continue ;;
    esac
    seen="$seen$dylib|"

    cp -P "$dylib" "$stage/lib/"
    if [[ -L "$dylib" ]]; then
      target="$(readlink "$dylib")"
      [[ "$target" = /* ]] || target="$(dirname "$dylib")/$target"
      queue+=("$target")
    fi

    while IFS= read -r dep; do
      resolved="$(resolve_prefix_dylib "$dep")"
      [[ -n "$resolved" ]] && queue+=("$resolved")
    done < <(otool -L "$dylib" | tail -n +2 | awk '{print $1}')
  done
}

copy_dylib_closure
if [[ -d "$PREFIX/include" ]]; then
  cp -R "$PREFIX/include/." "$stage/include/"
fi
if [[ -d "$PREFIX/lib/pkgconfig" ]]; then
  cp -R "$PREFIX/lib/pkgconfig/." "$stage/lib/pkgconfig/"
fi

for dep in $DEPS; do
  src="$(dep_src "$dep")"
  [[ -d "$src" ]] || continue
  license_file="$(find "$src" -maxdepth 2 -type f \( -iname 'LICENSE*' -o -iname 'COPYING*' -o -iname 'COPYRIGHT*' \) | head -n 1 || true)"
  if [[ -n "$license_file" ]]; then
    cp "$license_file" "$stage/licenses/${dep}-${license_file##*/}"
  fi
done

cat > "$stage/build-info.json" <<EOF
{
  "mpv_ref": "${MPV_REF:-v$MPV_VERSION}",
  "profile": "$BUILD_PROFILE",
  "arch": "$TARGET_ARCH",
  "deployment_target": "$DEPLOYMENT_TARGET",
  "sdkroot": "$SDKROOT",
  "cc": "$CC",
  "prefix": "third_party/install/$HOST_TAG",
  "dependencies": {
    "ffmpeg": "$FFMPEG_VERSION",
    "libplacebo": "$LIBPLACEBO_VERSION",
    "libass": "$LIBASS_VERSION",
    "freetype": "$FREETYPE_VERSION",
    "harfbuzz": "$HARFBUZZ_VERSION",
    "fribidi": "$FRIBIDI_VERSION",
    "zimg": "$ZIMG_VERSION",
    "lua": "$LUA_VERSION",
    "libarchive": "$LIBARCHIVE_VERSION"
  }
}
EOF

cat > "$stage/README-runtime.md" <<EOF
# $pkg_name

This bundle contains a macOS $TARGET_ARCH libmpv runtime/development package
built for macOS $DEPLOYMENT_TARGET or newer.

Use \`include/\` and \`lib/pkgconfig/mpv.pc\` to link a Qt application. Ship the
dylibs from \`lib/\` inside your app bundle's \`Contents/Frameworks\` directory
or another location covered by your executable's rpath.
EOF

tar -C "$THIRD_PARTY_ROOT/build/package" -czf "$out_dir/$pkg_name.tar.gz" "$pkg_name"
echo "$out_dir/$pkg_name.tar.gz"
