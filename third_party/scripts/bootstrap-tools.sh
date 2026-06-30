#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

build_configure_tool() {
  local dep="$1"
  local exe="$2"
  local build_mode="${3:-out-of-tree}"
  local src build
  src="$(dep_src "$dep")"
  build="$(dep_build "$dep")"
  if [[ -x "$TOOLS_PREFIX/bin/$exe" ]]; then
    return
  fi
  reset_build_dir "$build"
  if [[ ! -x "$src/configure" && -x "$src/autogen.sh" ]]; then
    pushd "$src" >/dev/null
    ./autogen.sh
    popd >/dev/null
  fi
  if [[ "$build_mode" == "in-source" ]]; then
    build="$src"
  fi
  pushd "$build" >/dev/null
  if [[ "$build_mode" == "in-source" ]]; then
    ./configure --prefix="$TOOLS_PREFIX"
  else
    "$src/configure" --prefix="$TOOLS_PREFIX"
  fi
  make $MAKEFLAGS
  make install
  popd >/dev/null
}

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

build_configure_tool m4 m4
build_configure_tool autoconf autoreconf
build_configure_tool automake automake
build_configure_tool libtool libtoolize
build_configure_tool nasm nasm in-source
build_pkgconf
build_ninja
install_meson

"$TOOLS_PREFIX/bin/m4" --version | head -n 1
"$TOOLS_PREFIX/bin/autoreconf" --version | head -n 1
"$TOOLS_PREFIX/bin/automake" --version | head -n 1
"$TOOLS_PREFIX/bin/nasm" --version
"$TOOLS_PREFIX/bin/pkgconf" --version
"$TOOLS_PREFIX/bin/ninja" --version
"$TOOLS_PREFIX/bin/meson" --version
