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

For each architecture (`arm64`, `x86_64`) the workflow:

1. Downloads IINA dylibs from `https://iina.io/dylibs/...`
2. Downloads the mpv `v0.38.0` source archive
3. Copies `include/mpv/*.h`
4. Packs headers and dylibs into a `.tar.gz`
5. Uploads both archives to the GitHub Release for that tag

## Configurable variables

Workflow defaults:

- `MPV_VERSION=0.38.0`
- `IINA_DYLIBS_VERSION=""`

`IINA_DYLIBS_VERSION` is optional. Leave it empty for the current IINA dylib path, or set it if you need an older versioned path such as `1.2.0`.

## Local usage

```bash
chmod +x scripts/*.sh
./scripts/package_libmpv.sh --arch arm64 --output-dir ./dist
./scripts/package_libmpv.sh --arch x86_64 --output-dir ./dist
```
