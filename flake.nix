{
  description = "macOS libmpv build dependencies";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-24.11-darwin";
  };

  outputs = { nixpkgs, ... }:
    let
      eachDarwinSystem = f:
        nixpkgs.lib.genAttrs [ "aarch64-darwin" "x86_64-darwin" ] (system:
          f {
            inherit system;
            pkgs = import nixpkgs {
              inherit system;
            };
          });
    in
    {
      devShells = eachDarwinSystem ({ pkgs, ... }: {
        libmpv-macos =
          let
            uchardet = pkgs.callPackage ./nix/packages/uchardet {
              macosDeploymentTarget = "11.0";
            };
          in
          pkgs.mkShell {
            packages = with pkgs; [
              autoconf
              automake
              cmake
              meson
              nasm
              ninja
              pkg-config
              python3

              ffmpeg
              freetype
              fribidi
              harfbuzz
              lcms2
              libarchive
              libass
              libjpeg
              libtool
              luajit
              mujs
              rubberband
              zimg
            ] ++ [
              uchardet
            ];

            shellHook = ''
              export MACOSX_DEPLOYMENT_TARGET="''${MACOSX_DEPLOYMENT_TARGET:-11.0}"
            '';
          };
      });
    };
}
