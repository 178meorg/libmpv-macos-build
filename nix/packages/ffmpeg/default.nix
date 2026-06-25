{
  lib,
  stdenv,
  fetchurl,
  meson,
  ninja,
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
    meson
    ninja
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
    cp ${./meson.build} meson.build
    cp ${./meson.options} meson.options
    patchShebangs configure
  '';

  mesonFlags = [
    "-Dvariant=video"
    "-Dflavor=full"
  ];

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
