{
  pkgs,
  fetchurl,
  darwinTargetedPackage,
  zlib,
  ...
}:

let
  packageLock = (import ../../../packages.lock.nix).libpng;
  base = pkgs.libpng.override {
    apngSupport = false;
    inherit zlib;
  };
in

darwinTargetedPackage (base.overrideAttrs (_old: {
  pname = "libpng";
  inherit (packageLock) version;

  src = fetchurl {
    inherit (packageLock) url sha256;
  };
}))
