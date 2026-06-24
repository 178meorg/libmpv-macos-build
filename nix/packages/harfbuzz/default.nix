{
  pkgs,
  fetchurl,
  darwinTargetedPackage,
  freetype,
  graphite2,
  ...
}:

let
  packageLock = (import ../../../packages.lock.nix).harfbuzz;
  base = pkgs.harfbuzz.override {
    inherit
      freetype
      graphite2
      ;
    withGraphite2 = true;
    withIcu = false;
    withIntrospection = false;
  };
in

darwinTargetedPackage (base.overrideAttrs (_old: {
  inherit (packageLock) version;

  src = fetchurl {
    inherit (packageLock) url sha256;
  };
}))
