{
  pkgs,
  fetchurl,
  darwinTargetedPackage,
  brotli,
  bzip2,
  libpng,
  zlib,
  ...
}:

let
  packageLock = (import ../../../packages.lock.nix).freetype;
  base = pkgs.freetype.override {
    inherit
      brotli
      bzip2
      libpng
      zlib
      ;
  };
in

darwinTargetedPackage (base.overrideAttrs (_old: {
  inherit (packageLock) version;

  src = fetchurl {
    inherit (packageLock) url sha256;
  };
}))
