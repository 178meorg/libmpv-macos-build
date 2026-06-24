{
  lib,
  stdenv,
  fetchurl,
  cmake,
  ninja,
  pkg-config,
  macosDeploymentTarget ? "11.0",
  ...
}:

stdenv.mkDerivation rec {
  pname = "uchardet";
  version = "0.0.8";

  src = fetchurl {
    url = "https://www.freedesktop.org/software/uchardet/releases/uchardet-${version}.tar.xz";
    sha256 = "e97a60cfc00a1c147a674b097bb1422abd9fa78a2d9ce3f3fdcc2e78a34ac5f0";
  };

  nativeBuildInputs = [
    cmake
    ninja
    pkg-config
  ];

  cmakeFlags = [
    "-DBUILD_SHARED_LIBS=ON"
    "-DBUILD_STATIC=OFF"
    "-DBUILD_BINARY=OFF"
    "-DCMAKE_BUILD_TYPE=Release"
  ] ++ lib.optionals stdenv.isDarwin [
    "-DCMAKE_OSX_DEPLOYMENT_TARGET=${macosDeploymentTarget}"
  ];
}
