{
  pkgs,
  macosDeploymentTarget ? "11.0",
}:

let
  darwinTargetedPackage = pkgs.callPackage ./_helpers/darwin-targeted-package.nix {
    inherit macosDeploymentTarget;
  };

  callPackage = path: args:
    pkgs.callPackage path ({
      inherit pkgs darwinTargetedPackage;
    } // args);
in
rec {
  brotli = callPackage ./brotli { };
  bzip2 = callPackage ./bzip2 { };
  dav1d = callPackage ./dav1d { };
  expat = callPackage ./expat { };
  ffmpeg = callPackage ./ffmpeg {
    inherit
      dav1d
      libxml2
      mbedtls
      zlib
      ;
  };
  freetype = callPackage ./freetype { };
  fribidi = callPackage ./fribidi { };
  graphite2 = callPackage ./graphite2 { };
  harfbuzz = callPackage ./harfbuzz { };
  jpeg-turbo = callPackage ./jpeg-turbo { };
  lcms2 = callPackage ./lcms2 { };
  libarchive = callPackage ./libarchive { };
  libass = callPackage ./libass { };
  libpng = callPackage ./libpng { };
  libplacebo = callPackage ./libplacebo {
    inherit
      lcms2
      shaderc
      vulkan-headers
      vulkan-loader
      ;
  };
  libsamplerate = callPackage ./libsamplerate { };
  libunibreak = callPackage ./libunibreak { };
  libxml2 = callPackage ./libxml2 { };
  lz4 = callPackage ./lz4 { };
  luajit = callPackage ./luajit { };
  mbedtls = callPackage ./mbedtls { };
  mujs = callPackage ./mujs { };
  rubberband = callPackage ./rubberband { };
  shaderc = callPackage ./shaderc { };
  uchardet = callPackage ./uchardet {
    inherit macosDeploymentTarget;
  };
  vulkan-headers = callPackage ./vulkan-headers { };
  vulkan-loader = callPackage ./vulkan-loader { };
  xz = callPackage ./xz { };
  zimg = callPackage ./zimg { };
  zlib = callPackage ./zlib { };
  zstd = callPackage ./zstd { };
}
