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
    "-Dflavor=default"
  ];

  MACOSX_DEPLOYMENT_TARGET = macosDeploymentTarget;
}
