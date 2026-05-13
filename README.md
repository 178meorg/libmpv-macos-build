# libmpv macOS Release Workflow

This repository packages macOS `libmpv` release bundles from two inputs:

- IINA prebuilt dylibs
- mpv `0.38.0` source headers

Each GitHub Release publishes two archives:

- `libmpv-0.38.0-macos-arm64.tar.gz`
- `libmpv-0.38.0-macos-x86_64.tar.gz`

After extraction, each archive has this layout:

```text
libmpv-0.38.0-macos-<arch>/
  include/
    mpv/
      *.h
  lib/
    *.dylib
```

## Trigger behavior

Any `push` triggers `.github/workflows/release.yml`.

- Branch push: build both archives and upload them as GitHub Actions artifacts
- Tag push: build both archives, upload artifacts, and publish a GitHub Release

The GitHub Release name and version are both the pushed tag name.

## Workflow behavior

The workflow is split into six visible stages:

1. `Prepare mpv headers`
2. `Download arm64 dylibs`
3. `Download x86_64 dylibs`
4. `Package arm64 bundle`
5. `Package x86_64 bundle`
6. `Publish GitHub Release` on tag pushes only

Packaging jobs:

1. Download mpv headers once as a shared artifact
2. Download IINA dylibs separately for each architecture
3. Reuse headers and dylib artifacts when assembling the final bundles
4. Pack headers and dylibs into a `.tar.gz`
5. Upload branch artifacts or release assets

## Configurable variables

Workflow defaults:

- `MPV_VERSION=0.38.0`
- `IINA_DYLIBS_VERSION=""`

`IINA_DYLIBS_VERSION` is optional. Leave it empty for the current IINA dylib path, or set it if you need an older versioned path such as `1.2.0`.

## Local usage

```bash
chmod +x scripts/*.sh
./scripts/fetch_mpv_headers.sh --output-dir ./dist/headers
./scripts/download_iina_libs.sh --arch arm64 --output-dir ./dist/arm64-libs
./scripts/download_iina_libs.sh --arch x86_64 --output-dir ./dist/x86_64-libs
./scripts/package_libmpv.sh --arch arm64 --headers-dir ./dist/headers --libs-dir ./dist/arm64-libs --output-dir ./dist
./scripts/package_libmpv.sh --arch x86_64 --headers-dir ./dist/headers --libs-dir ./dist/x86_64-libs --output-dir ./dist
```
