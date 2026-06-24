{
  pkgs,
  fetchurl,
  darwinTargetedPackage,
  lcms2,
  shaderc,
  vulkan-headers,
  vulkan-loader,
  ...
}:

let
  packageLock = (import ../../../packages.lock.nix).libplacebo;
  base = pkgs.libplacebo.override {
    inherit
      lcms2
      shaderc
      vulkan-headers
      vulkan-loader
      ;
  };
in

darwinTargetedPackage (base.overrideAttrs (_old: {
  inherit (packageLock) version;

  src = fetchurl {
    inherit (packageLock) url sha256;
  };
}))
