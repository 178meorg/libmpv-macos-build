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

let
  packageLock = (import ../../../packages.lock.nix).uchardet;
  inherit (packageLock) version;
in

stdenv.mkDerivation rec {
  pname = "uchardet";
  inherit version;

  src = fetchurl {
    inherit (packageLock) url sha256;
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
