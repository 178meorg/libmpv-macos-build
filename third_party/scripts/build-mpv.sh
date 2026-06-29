#!/usr/bin/env bash
set -euo pipefail

# shellcheck disable=SC1091
source "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/env.sh"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/lib.sh"

src="$(dep_src mpv)"
build="$(dep_build mpv)"
reset_build_dir "$build"

opts=(
  -Ddefault_library=shared # 构建动态库，产出 libmpv.dylib 及动态依赖。
)

mpv_options=(
  libmpv=true # 构建 libmpv 库，供 Qt 程序链接和嵌入。
  cplayer=false # 不构建 mpv 命令行播放器，只保留库形态。
  gpl=false # 禁用 GPL-only 功能，降低闭源 Qt 播放器分发复杂度。
  build-date=false # 不写入构建时间，提升构建可复现性。
  tests=false # 不构建 mpv 单元测试，缩短 CI 时间。
  ta-leak-report=false # 关闭开发期内存泄漏报告，发布构建不需要。

  cdda=disabled # 关闭 Audio CD 输入支持，播放器常规文件/网络播放不需要。
  cplugins=disabled # 关闭 C 插件加载，减少扩展面和 ABI 风险。
  dvbin=disabled # 关闭 DVB 电视输入模块，macOS Qt 播放器不需要。
  dvdnav=disabled # 关闭 DVD 菜单/导航支持，避免 libdvdnav 依赖。
  javascript=disabled # 关闭 MuJS JavaScript 脚本后端，保留 Lua 即可。
  libavdevice=disabled # 关闭 FFmpeg 设备采集库，摄像头/采集卡才需要。
  libbluray=disabled # 关闭蓝光盘支持，避免 libbluray 依赖。
  pthread-debug=disabled # 关闭 pthread 调试包装，开发诊断才需要。
  rubberband=disabled # 关闭变速不变调音频处理，避免额外依赖和许可证复杂度。
  sdl2=disabled # 关闭 SDL2 通用支持，Qt 程序不需要 SDL。
  sdl2-gamepad=disabled # 关闭 SDL2 手柄输入支持，当前播放器不需要。
  vapoursynth=disabled # 关闭 VapourSynth 滤镜桥，视频后处理脚本场景才需要。
  uwp=disabled # 关闭 Windows UWP 支持，macOS 不需要。

  iconv=enabled # 启用字符集转换，用于字幕/元数据编码处理。
  zlib=enabled # 启用 zlib，支持压缩数据和相关封装辅助能力。
  gl=enabled # 启用 OpenGL 支持，是 Qt OpenGL 嵌入路径基础。
  gl-cocoa=enabled # 启用 macOS Cocoa OpenGL 后端。
  plain-gl=enabled # 启用无平台窗口绑定的 OpenGL，libmpv render API 需要。
  coreaudio=enabled # 启用 macOS CoreAudio 音频输出。
  cocoa=enabled # 启用 macOS Cocoa 基础支持，macOS 后端需要。
  lcms2=enabled # 启用 LittleCMS，用于 ICC 色彩管理。
  lua=enabled # 启用 Lua 脚本支持，保留 mpv 脚本生态能力。
  zimg=enabled # 启用 zimg，高质量软件缩放和色彩转换。
  uchardet=enabled # 启用字幕/文本编码自动探测。
  libarchive=enabled # 启用压缩包/归档读取支持，例如 zip 内字幕。

  caca=disabled # 关闭 libcaca 字符画视频输出。
  d3d11=disabled # 关闭 Direct3D 11 输出，Windows 专用。
  direct3d=disabled # 关闭旧 Direct3D 支持，Windows 专用。
  drm=disabled # 关闭 Linux DRM/KMS 输出。
  egl=disabled # 关闭通用 EGL 支持，当前 macOS OpenGL 路线不用。
  egl-android=disabled # 关闭 Android EGL 后端。
  egl-angle=disabled # 关闭 ANGLE EGL 头文件支持。
  egl-angle-lib=disabled # 关闭 ANGLE EGL 库支持。
  egl-angle-win32=disabled # 关闭 Windows ANGLE EGL 后端。
  egl-drm=disabled # 关闭 Linux DRM EGL 后端。
  egl-wayland=disabled # 关闭 Wayland EGL 后端。
  egl-x11=disabled # 关闭 X11 EGL 后端。
  gbm=disabled # 关闭 Linux GBM 支持。
  jpeg=disabled # 关闭 JPEG 输出/辅助支持，播放器核心不需要。
  rpi=disabled # 关闭树莓派视频输出支持。
  sdl2-video=disabled # 关闭 SDL2 视频输出，Qt 程序不需要。
  shaderc=disabled # 关闭 Vulkan/SPIR-V shaderc 编译器依赖。
  sixel=disabled # 关闭终端 Sixel 图像输出。
  spirv-cross=disabled # 关闭 SPIRV-Cross，当前不走 Vulkan shader 转换。
  vdpau=disabled # 关闭 Linux VDPAU 硬解/输出支持。
  vdpau-gl-x11=disabled # 关闭 X11 下 VDPAU/OpenGL 互操作。
  vaapi=disabled # 关闭 Linux VAAPI 硬解支持。
  vaapi-drm=disabled # 关闭 DRM 下 VAAPI 支持。
  vaapi-wayland=disabled # 关闭 Wayland 下 VAAPI 支持。
  vaapi-x11=disabled # 关闭 X11 下 VAAPI 支持。
  vaapi-x-egl=disabled # 关闭 X11/EGL 下 VAAPI 支持。
  vulkan=disabled # 关闭 Vulkan 后端，当前不引入 MoltenVK/Vulkan SDK。
  wayland=disabled # 关闭 Wayland 窗口系统支持。
  x11=disabled # 关闭 X11 窗口系统支持。
  xv=disabled # 关闭 XVideo 输出，Linux/X11 老接口。

  android-media-ndk=disabled # 关闭 Android Media NDK 硬解。
  cuda-hwaccel=disabled # 关闭 NVIDIA CUDA 硬解。
  cuda-interop=disabled # 关闭 CUDA 图形互操作。
  d3d-hwaccel=disabled # 关闭 D3D11VA 硬解，Windows 专用。
  d3d9-hwaccel=disabled # 关闭 DXVA2/D3D9 硬解，Windows 专用。
  gl-dxinterop=disabled # 关闭 OpenGL/DirectX 互操作，Windows 专用。
  gl-dxinterop-d3d9=disabled # 关闭 D3D9 版 OpenGL/DirectX 互操作。
  ios-gl=disabled # 关闭 iOS OpenGL ES 硬解互操作。
  rpi-mmal=disabled # 关闭树莓派 MMAL 硬解。
  videotoolbox-gl=enabled # 启用 macOS VideoToolbox 与 OpenGL 互操作。
  videotoolbox-pl=disabled # 关闭 VideoToolbox/libplacebo 路径，当前缺 Vulkan/CV Metal。

  macos-cocoa-cb=disabled # 关闭旧 macOS cocoa-cb libmpv 后端。
  macos-media-player=disabled # 关闭 macOS 系统媒体控制集成。
  macos-touchbar=disabled # 关闭 Touch Bar 支持。
  swift-build=disabled # 关闭 Swift 构建路径，避免 Swift runtime 依赖。

  html-build=disabled # 不生成 HTML 手册。
  manpage-build=disabled # 不生成 manpage。
  pdf-build=disabled # 不生成 PDF 手册。
)

while IFS= read -r opt; do opts+=("$opt"); done < <(meson_option_args "$src" "${mpv_options[@]}")

meson_setup "$build" "$src" "${opts[@]}"
"$MESON" compile -C "$build"
"$MESON" install -C "$build"
