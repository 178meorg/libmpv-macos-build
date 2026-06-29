#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

src="$(dep_src lua)"
version="$(dep_var lua VERSION)"
major_minor="${version%.*}"

pushd "$src" >/dev/null
make clean >/dev/null 2>&1 || true
make macosx \
  CC="$CC" \
  AR="$AR rcu" \
  RANLIB="$RANLIB" \
  MYCFLAGS="$CFLAGS -DLUA_USE_MACOSX" \
  MYLDFLAGS="$LDFLAGS"

mkdir -p "$PREFIX/include/lua$major_minor" "$PREFIX/lib/pkgconfig" "$PREFIX/bin" "$PREFIX/lib"
cp src/lua src/luac "$PREFIX/bin/"
cp src/liblua.a "$PREFIX/lib/liblua.a"
cp src/lua.h src/luaconf.h src/lauxlib.h src/lualib.h "$PREFIX/include/lua$major_minor/"
cat > "$PREFIX/lib/pkgconfig/lua.pc" <<EOF
prefix=$PREFIX
exec_prefix=\${prefix}
libdir=\${prefix}/lib
includedir=\${prefix}/include/lua$major_minor

Name: Lua
Description: Lua language engine
Version: $version
Libs: -L\${libdir} -llua
Libs.private: -lm
Cflags: -I\${includedir}
EOF
ln -sf lua.pc "$PREFIX/lib/pkgconfig/lua$major_minor.pc"
popd >/dev/null
