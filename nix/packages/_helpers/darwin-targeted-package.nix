{
  lib,
  macosDeploymentTarget ? "11.0",
}:

package:
package.overrideAttrs (old: {
  MACOSX_DEPLOYMENT_TARGET = macosDeploymentTarget;

  NIX_CFLAGS_COMPILE = lib.concatStringsSep " " (
    [ "-mmacosx-version-min=${macosDeploymentTarget}" ]
    ++ lib.optional (old ? NIX_CFLAGS_COMPILE) (toString old.NIX_CFLAGS_COMPILE)
  );

  NIX_LDFLAGS = lib.concatStringsSep " " (
    [ "-mmacosx-version-min=${macosDeploymentTarget}" ]
    ++ lib.optional (old ? NIX_LDFLAGS) (toString old.NIX_LDFLAGS)
  );
})
