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
            localPackages = import ./nix/packages {
              inherit pkgs;
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
              libtool
            ] ++ (with localPackages; [
              ffmpeg
              jpeg-turbo
              lcms2
              libarchive
              libass
              libplacebo
              luajit
              rubberband
              uchardet
              zimg
              zlib
            ]);

            shellHook = ''
              export MACOSX_DEPLOYMENT_TARGET="''${MACOSX_DEPLOYMENT_TARGET:-11.0}"
            '';
          };
      });
    };
}
