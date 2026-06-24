{
  pkgs,
  fetchurl,
  darwinTargetedPackage,
  freetype,
  fribidi,
  harfbuzz,
  ...
}:

let
  packageLock = (import ../../../packages.lock.nix).libass;
  base = pkgs.libass.override {
    inherit
      freetype
      fribidi
      harfbuzz
      ;
    fontconfigSupport = false;
  };
in

darwinTargetedPackage (base.overrideAttrs (_old: {
  inherit (packageLock) version;

  src = fetchurl {
    inherit (packageLock) url sha256;
  };
}))
