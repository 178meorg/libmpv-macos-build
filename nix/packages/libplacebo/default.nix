{
  pkgs,
  fetchurl,
  darwinTargetedPackage,
  lcms2,
  ...
}:

let
  packageLock = (import ../../../packages.lock.nix).libplacebo;
  base = pkgs.libplacebo.override {
    inherit lcms2;
    vulkanSupport = false;
  };
in

darwinTargetedPackage (base.overrideAttrs (_old: {
  inherit (packageLock) version;

  src = fetchurl {
    inherit (packageLock) url sha256;
  };

  mesonFlags = [
    (pkgs.lib.mesonBool "demos" false)
    (pkgs.lib.mesonEnable "d3d11" false)
    (pkgs.lib.mesonEnable "vulkan" false)
    (pkgs.lib.mesonEnable "vk-proc-addr" false)
    (pkgs.lib.mesonEnable "glslang" false)
    (pkgs.lib.mesonEnable "shaderc" false)
    (pkgs.lib.mesonEnable "opengl" true)
    (pkgs.lib.mesonEnable "lcms" true)
    (pkgs.lib.mesonEnable "dovi" false)
    (pkgs.lib.mesonEnable "libdovi" false)
  ] ++ pkgs.lib.optionals pkgs.stdenv.hostPlatform.isDarwin [
    (pkgs.lib.mesonEnable "unwind" false)
  ];
}))
