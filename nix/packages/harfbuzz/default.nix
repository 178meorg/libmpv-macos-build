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

  mesonFlags = [
    (pkgs.lib.mesonEnable "cairo" false)
    (pkgs.lib.mesonEnable "chafa" false)
    (pkgs.lib.mesonEnable "coretext" false)
    (pkgs.lib.mesonEnable "gpu" false)
    (pkgs.lib.mesonEnable "gpu_demo" false)
    (pkgs.lib.mesonEnable "introspection" false)
    (pkgs.lib.mesonEnable "tests" false)
    (pkgs.lib.mesonEnable "docs" false)
    (pkgs.lib.mesonEnable "utilities" false)
    (pkgs.lib.mesonOption "cmakepackagedir" "${placeholder "dev"}/lib/cmake")
  ];
}))
