{
  lib,
  stdenv,
  fetchurl,
  pkg-config,
  nasm,
  yasm,
  perl,
  darwin,
  dav1d,
  libxml2,
  mbedtls,
  zlib,
  macosDeploymentTarget ? "11.0",
  ...
}:

let
  packageLock = (import ../../../packages.lock.nix).ffmpeg;
  inherit (packageLock) version;
in

stdenv.mkDerivation {
  pname = "ffmpeg";
  inherit version;

  src = fetchurl {
    inherit (packageLock) url sha256;
  };

  nativeBuildInputs = [
    pkg-config
    nasm
    yasm
    perl
  ];

  buildInputs = [
    dav1d
    libxml2
    mbedtls
    zlib
  ] ++ lib.optionals stdenv.isDarwin (with darwin.apple_sdk.frameworks; [
    AudioToolbox
    CoreFoundation
    CoreMedia
    CoreVideo
    VideoToolbox
  ]);

  postPatch = ''
    patchShebangs configure
  '';

  configurePhase = ''
    runHook preConfigure

    : "''${CC:=cc}"
    : "''${CXX:=c++}"
    : "''${AR:=ar}"
    : "''${NM:=nm}"
    : "''${RANLIB:=ranlib}"
    : "''${STRIP:=strip}"

    configure_flags=(
      --prefix="$out"
      --cc="$CC"
      --cxx="$CXX"
      --host-cc="$CC"
      --ld="$CC"
      --ar="$AR"
      --nm="$NM"
      --ranlib="$RANLIB"
      --strip="$STRIP"
      --disable-autodetect
      --disable-all
      --disable-x86asm
      --disable-runtime-cpudetect
      --disable-debug
      --disable-stripping
      --disable-optimizations
      --disable-static
      --disable-shared
      --disable-pthreads
      --disable-safe-bitstream-reader
      --enable-small
      --enable-optimizations
      --enable-shared
      --enable-network
      --enable-pthreads
      --enable-pic
      --enable-mbedtls
      --enable-version3
      --enable-safe-bitstream-reader
      --enable-stripping
      --enable-avcodec
      --enable-avformat
      --enable-swresample
      --enable-swscale
      --enable-avfilter
      --enable-zlib
      --enable-audiotoolbox
      --enable-libxml2
      --enable-videotoolbox
      --enable-libdav1d
      --enable-decoders
      --enable-hwaccels
      --enable-parsers
      --enable-demuxers
      --enable-protocols
      --enable-bsfs
      --enable-filter=overlay
      --enable-filter=equalizer
      --disable-decoder=h264
      --enable-decoder=h264
    )

    ${lib.optionalString stdenv.isDarwin ''
      configure_flags+=(
        --target-os=darwin
        --arch=${stdenv.hostPlatform.parsed.cpu.name}
      )
    ''}

    if [[ "${stdenv.hostPlatform.parsed.cpu.name}" == "aarch64" ]]; then
      configure_flags+=(--enable-neon)
    fi

    ./configure "''${configure_flags[@]}" || {
      if [[ -f ffbuild/config.log ]]; then
        echo "FFmpeg configure failed; ffbuild/config.log follows:" >&2
        cat ffbuild/config.log >&2
      fi
      exit 1
    }

    runHook postConfigure
  '';

  enableParallelBuilding = true;

  postInstall = ''
    pkgconfig_dir="$out/lib/pkgconfig"
    mkdir -p "$pkgconfig_dir"

    for pc in \
      libavcodec \
      libavfilter \
      libavformat \
      libavutil \
      libswresample \
      libswscale
    do
      if [[ ! -f "$pkgconfig_dir/$pc.pc" ]]; then
        generated_pc="$(find . -name "$pc.pc" -type f -print -quit)"
        if [[ -n "$generated_pc" ]]; then
          install -Dm644 "$generated_pc" "$pkgconfig_dir/$pc.pc"
        fi
      fi

      if [[ ! -f "$pkgconfig_dir/$pc.pc" ]]; then
        echo "Missing FFmpeg pkg-config file: $pc.pc" >&2
        exit 1
      fi
    done
  '';

  MACOSX_DEPLOYMENT_TARGET = macosDeploymentTarget;
}
