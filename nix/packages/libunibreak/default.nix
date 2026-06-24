{
  pkgs,
  fetchurl,
  darwinTargetedPackage,
  ...
}:

let
  packageLock = (import ../../../packages.lock.nix).libunibreak;
in

darwinTargetedPackage (pkgs.libunibreak.overrideAttrs (_old: {
  inherit (packageLock) version;

  src = fetchurl {
    inherit (packageLock) url sha256;
  };
}))
