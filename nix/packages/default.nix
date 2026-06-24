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
      inherit pkgs darwinTargetedPackage macosDeploymentTarget;
    } // args);
in
{
  ffmpeg = callPackage ./ffmpeg { };
  brotli = callPackage ./brotli { };
  bzip2 = callPackage ./bzip2 { };
  expat = callPackage ./expat { };
  freetype = callPackage ./freetype { };
  fribidi = callPackage ./fribidi { };
  gettext = callPackage ./gettext { };
  glib = callPackage ./glib { };
  graphite2 = callPackage ./graphite2 { };
  harfbuzz = callPackage ./harfbuzz { };
  jpeg-turbo = callPackage ./jpeg-turbo { };
  lcms2 = callPackage ./lcms2 { };
  libarchive = callPackage ./libarchive { };
  libass = callPackage ./libass { };
  libpng = callPackage ./libpng { };
  libplacebo = callPackage ./libplacebo { };
  libsamplerate = callPackage ./libsamplerate { };
  libunibreak = callPackage ./libunibreak { };
  lz4 = callPackage ./lz4 { };
  luajit = callPackage ./luajit { };
  mujs = callPackage ./mujs { };
  pcre2 = callPackage ./pcre2 { };
  rubberband = callPackage ./rubberband { };
  shaderc = callPackage ./shaderc { };
  uchardet = callPackage ./uchardet { };
  vulkan-headers = callPackage ./vulkan-headers { };
  vulkan-loader = callPackage ./vulkan-loader { };
  xz = callPackage ./xz { };
  zimg = callPackage ./zimg { };
  zlib = callPackage ./zlib { };
  zstd = callPackage ./zstd { };
}
