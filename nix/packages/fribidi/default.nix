{
  pkgs,
  fetchurl,
  darwinTargetedPackage,
  ...
}:

let
  packageLock = (import ../../../packages.lock.nix).fribidi;
in

darwinTargetedPackage (pkgs.fribidi.overrideAttrs (_old: {
  inherit (packageLock) version;
  doCheck = false;

  src = fetchurl {
    inherit (packageLock) url sha256;
  };
}))
