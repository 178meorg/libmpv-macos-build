{ pkgs, darwinTargetedPackage }:

darwinTargetedPackage (pkgs.libarchive.overrideAttrs (_old: {
  doCheck = false;
}))
