{
  macosDeploymentTarget ? "11.0",
}:

package:
package.overrideAttrs (old: {
  MACOSX_DEPLOYMENT_TARGET = macosDeploymentTarget;
})
