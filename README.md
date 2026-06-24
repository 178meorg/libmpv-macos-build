# macOS Qt libmpv Build Workflow

This repository builds macOS `libmpv` directly from upstream `mpv-player/mpv` using the official macOS CI dependency setup, with a Qt-oriented macOS build profile for `libmpv` consumers.

Each run builds two architectures:

- `arm64` on `macos-15`
- `x86_64` on `macos-15-intel`

Each build produces one archive:

- `libmpv-<version>-macos-<arch>.tar.gz`

The `libmpv` archive has this layout:

```text
libmpv-<version>-macos-<arch>/
  dependency-report.txt
  include/
    mpv/
      *.h
  lib/
    libmpv.dylib
    *.dylib
    pkgconfig/
      mpv.pc
```

The `lib/` directory also includes the non-system dylib dependencies needed by `libmpv.dylib`, with their install names rewritten to `@loader_path/<name>`.

`dependency-report.txt` records the packaged `mpv` dylib, detected FFmpeg dylibs, other packaged third-party dylibs, and the system libraries referenced by the closure.

## Trigger behavior

`.github/workflows/build.yml` runs on:

- any `push`
- manual `workflow_dispatch`

Branch pushes upload build artifacts to GitHub Actions.

Tag pushes:

- use the pushed tag name as the upstream mpv ref
- upload build artifacts
- publish a GitHub Release in this repository

The tag must match a valid upstream `mpv-player/mpv` ref such as `v0.41.0`.

## Workflow behavior

Each matrix job:

1. checks out this packaging repository
2. checks out upstream `mpv-player/mpv`
3. installs the same Homebrew dependencies as upstream macOS CI
4. runs a Qt/libmpv-oriented macOS build script based on upstream `ci/build-macos.sh`, with mpv CLI/player app, tests, and macOS Swift UI features disabled while keeping VideoToolbox OpenGL support
5. packages `libmpv` from `$HOME/out/mpv`

The release job downloads both architecture artifacts and uploads the generated `libmpv` `.tar.gz` files to the GitHub Release.

## Configurable variables

Workflow defaults:

- `MPV_DEFAULT_REF=master`
- `MPV_REPOSITORY=mpv-player/mpv`

Manual runs can override the upstream ref with the `mpv_ref` input.

## Local usage

Install the same dependencies used by this workflow, clone upstream `mpv`, and run the Qt/libmpv macOS build script:

```bash
brew update
brew install autoconf automake pkgconf libtool python freetype fribidi little-cms2 \
  luajit libass ffmpeg meson rust uchardet mujs libplacebo molten-vk vulkan-loader vulkan-headers \
  libarchive rubberband zimg

git clone https://github.com/mpv-player/mpv.git
cd mpv
TRAVIS_OS_NAME=local /path/to/this/repo/scripts/build_macos_libmpv_qt.sh "$PWD"
```

To package `libmpv` from the official install prefix:

```bash
/path/to/this/repo/scripts/package_libmpv.sh \
  --arch arm64 \
  --install-prefix "$HOME/out/mpv" \
  --source-dir /path/to/mpv \
  --output-dir ./dist
```
