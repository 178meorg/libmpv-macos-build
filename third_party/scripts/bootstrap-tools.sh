#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

build_pkgconf() {
  local src build
  src="$(dep_src pkgconf)"
  build="$(dep_build pkgconf)"
  if [[ -x "$TOOLS_PREFIX/bin/pkgconf" ]]; then
    return
  fi
  reset_build_dir "$build"
  pushd "$build" >/dev/null
  "$src/configure" \
    --prefix="$TOOLS_PREFIX" \
    --with-system-libdir="$PREFIX/lib" \
    --with-system-includedir="$PREFIX/include"
  make $MAKEFLAGS
  make install
  popd >/dev/null
}

build_ninja() {
  local src
  src="$(dep_src ninja)"
  if [[ -x "$TOOLS_PREFIX/bin/ninja" ]]; then
    return
  fi
  [[ -n "$PYTHON3" ]] || die "python3 is required as a host build tool"
  pushd "$src" >/dev/null
  "$PYTHON3" configure.py --bootstrap
  mkdir -p "$TOOLS_PREFIX/bin"
  cp ninja "$TOOLS_PREFIX/bin/ninja"
  popd >/dev/null
}

install_meson() {
  local src wrapper
  src="$(dep_src meson)"
  wrapper="$TOOLS_PREFIX/bin/meson"
  if [[ -x "$wrapper" ]]; then
    return
  fi
  mkdir -p "$TOOLS_PREFIX/bin"
  cat > "$wrapper" <<EOF
#!/usr/bin/env bash
exec "$PYTHON3" "$src/meson.py" "\$@"
EOF
  chmod +x "$wrapper"
}

build_pkgconf
build_ninja
install_meson

"$TOOLS_PREFIX/bin/pkgconf" --version
"$TOOLS_PREFIX/bin/ninja" --version
"$TOOLS_PREFIX/bin/meson" --version
