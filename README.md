# libmpv macOS source build

This repository builds a relocatable macOS `libmpv.dylib` bundle for a Qt 6
player without using Homebrew, Nix, or prebuilt third-party runtime libraries.

## Targets

- Minimum runtime: macOS 11.0
- Architectures: `arm64` and `x86_64`
- Primary artifact: per-architecture `libmpv` runtime/development tarballs
- License profile: LGPL-oriented player build

## Quick start

```sh
third_party/scripts/fetch.sh
third_party/scripts/build-all.sh --arch arm64 --target 11.0 --profile enhanced-lgpl
third_party/scripts/package-libmpv.sh --arch arm64 --profile enhanced-lgpl
```

The install prefix is `third_party/install/macos-<arch>`. Artifacts are written
to `dist/`.

## What is built

The enhanced LGPL profile enables FFmpeg, libass subtitles, libplacebo rendering,
VideoToolbox, Lua scripts, zimg, libarchive, and uchardet. It disables GPL and
nonfree codec dependencies, rubberband, JavaScript, DVD/CD support, and Swift
runtime integration.

## CI

`.github/workflows/build.yml` builds both macOS architectures on GitHub Actions,
audits the resulting dylibs, uploads artifacts for every run, and publishes the
two tarballs when a tag is pushed.
