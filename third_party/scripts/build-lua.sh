#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

src="$(dep_src lua)"
build="$(dep_build lua)"
version="$(dep_var lua VERSION)"
major_minor="${version%.*}"
lua_cflags="-arch $TARGET_ARCH -isysroot $SDKROOT -mmacosx-version-min=$DEPLOYMENT_TARGET -O2 -fPIC -DLUA_USE_MACOSX"

reset_build_dir "$build"
case "$major_minor" in
  5.2)
    lua_sources=(
      lapi.c lcode.c lctype.c ldebug.c ldo.c ldump.c lfunc.c lgc.c llex.c
      lmem.c lobject.c lopcodes.c lparser.c lstate.c lstring.c ltable.c
      ltm.c lundump.c lvm.c lzio.c
      lauxlib.c lbaselib.c lbitlib.c lcorolib.c ldblib.c liolib.c lmathlib.c
      loadlib.c loslib.c lstrlib.c ltablib.c linit.c
    )
    ;;
  5.4)
    lua_sources=(
      lapi.c lcode.c lctype.c ldebug.c ldo.c ldump.c lfunc.c lgc.c llex.c
      lmem.c lobject.c lopcodes.c lparser.c lstate.c lstring.c ltable.c
      ltm.c lundump.c lvm.c lzio.c
      lauxlib.c lbaselib.c lcorolib.c ldblib.c liolib.c lmathlib.c loadlib.c
      loslib.c lstrlib.c ltablib.c lutf8lib.c linit.c
    )
    ;;
  *)
    die "unsupported Lua version for manual build: $version"
    ;;
esac

objects=()
for c_file in "${lua_sources[@]}"; do
  obj="$build/${c_file%.c}.o"
  "$CC" $lua_cflags -I"$src/src" -c "$src/src/$c_file" -o "$obj"
  objects+=("$obj")
done

mkdir -p "$PREFIX/include/lua$major_minor" "$PREFIX/lib/pkgconfig" "$PREFIX/lib"
"$AR" rcs "$PREFIX/lib/liblua.a" "${objects[@]}"
"$RANLIB" "$PREFIX/lib/liblua.a"
cp "$src/src/lua.h" "$src/src/luaconf.h" "$src/src/lauxlib.h" "$src/src/lualib.h" "$PREFIX/include/lua$major_minor/"
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
