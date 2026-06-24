project('ffmpeg', 'c', 'cpp', 'objc', meson_version: '>=1.1.0')

mod = import('unstable-external_project')

c = meson.get_compiler('c')
cpp = meson.get_compiler('cpp')
objc = meson.get_compiler('objc')
nm = find_program('nm')
ar = find_program('ar')
strip = find_program('strip')
pkg_config = find_program('pkg-config')

c_args = get_option('c_args')
cpp_args = get_option('cpp_args')
objc_args = get_option('objc_args')
c_link_args = get_option('c_link_args')

variant = get_option('variant')
flavor = get_option('flavor')

disable_all_options = [
  '--disable-autodetect',
  '--disable-all',
  '--disable-x86asm',
  '--disable-runtime-cpudetect',
  '--disable-debug',
  '--disable-stripping',
  '--disable-optimizations',
  '--disable-static',
  '--disable-shared',
  '--disable-pthreads',
  '--disable-safe-bitstream-reader',
]

common_options = [
  '--prefix=' + get_option('prefix'),
  '--enable-small',
  '--enable-optimizations',
  '--enable-shared',
  '--enable-network',
  '--enable-pthreads',
  '--enable-pic',
  '--enable-mbedtls',
  '--enable-version3',
  '--enable-safe-bitstream-reader',
  '--enable-stripping',
  '--enable-avcodec',
  '--enable-avformat',
  '--enable-swresample',
  '--enable-swscale',
  '--enable-avfilter',
]

audio_common_options = [
  '--enable-zlib',
  '--enable-audiotoolbox',
]

video_common_options = [
  '--enable-libxml2',
  '--enable-videotoolbox',
  '--enable-libdav1d',
]

if host_machine.cpu_family() == 'aarch64'
  video_common_options += ['--enable-neon']
endif

audio_default_options = [
  '--enable-decoder=aac*',
  '--enable-decoder=ac3',
  '--enable-decoder=alac',
  '--enable-decoder=als',
  '--enable-decoder=ape',
  '--enable-decoder=atrac*',
  '--enable-decoder=eac3',
  '--enable-decoder=flac',
  '--enable-decoder=gsm*',
  '--enable-decoder=mp1*',
  '--enable-decoder=mp2*',
  '--enable-decoder=mp3*',
  '--enable-decoder=mpc*',
  '--enable-decoder=opus',
  '--enable-decoder=ra*',
  '--enable-decoder=ralf',
  '--enable-decoder=shorten',
  '--enable-decoder=tak',
  '--enable-decoder=tta',
  '--enable-decoder=vorbis',
  '--enable-decoder=wavpack',
  '--enable-decoder=wma*',
  '--enable-decoder=pcm*',
  '--enable-decoder=dsd*',
  '--enable-decoder=dca',
  '--enable-parser=aac*',
  '--enable-parser=ac3',
  '--enable-parser=cook',
  '--enable-parser=dca',
  '--enable-parser=flac',
  '--enable-parser=gsm',
  '--enable-parser=mpegaudio',
  '--enable-parser=tak',
  '--enable-parser=vorbis',
  '--enable-demuxer=aac',
  '--enable-demuxer=ac3',
  '--enable-demuxer=aiff',
  '--enable-demuxer=ape',
  '--enable-demuxer=asf',
  '--enable-demuxer=au',
  '--enable-demuxer=avi',
  '--enable-demuxer=flac',
  '--enable-demuxer=flv',
  '--enable-demuxer=matroska',
  '--enable-demuxer=mov',
  '--enable-demuxer=m4v',
  '--enable-demuxer=mp3',
  '--enable-demuxer=mpc*',
  '--enable-demuxer=ogg',
  '--enable-demuxer=pcm*',
  '--enable-demuxer=rm',
  '--enable-demuxer=shorten',
  '--enable-demuxer=tak',
  '--enable-demuxer=tta',
  '--enable-demuxer=wav',
  '--enable-demuxer=wv',
  '--enable-demuxer=xwma',
  '--enable-demuxer=dsf',
  '--enable-demuxer=dts',
  '--enable-demuxer=truehd',
  '--enable-protocol=async',
  '--enable-protocol=cache',
  '--enable-protocol=crypto',
  '--enable-protocol=data',
  '--enable-protocol=ffrtmphttp',
  '--enable-protocol=file',
  '--enable-protocol=ftp',
  '--enable-protocol=hls',
  '--enable-protocol=http',
  '--enable-protocol=httpproxy',
  '--enable-protocol=https',
  '--enable-protocol=pipe',
  '--enable-protocol=rtmp',
  '--enable-protocol=rtmps',
  '--enable-protocol=rtmpt',
  '--enable-protocol=rtmpts',
  '--enable-protocol=rtp',
  '--enable-protocol=subfile',
  '--enable-protocol=tcp',
  '--enable-protocol=tls',
  '--enable-filter=overlay',
  '--enable-filter=equalizer',
]

video_default_options = [
  '--enable-decoder=flv',
  '--enable-decoder=h263',
  '--enable-decoder=h263i',
  '--enable-decoder=h263p',
  '--enable-decoder=h264',
  '--enable-decoder=mpeg1video',
  '--enable-decoder=mpeg2video',
  '--enable-decoder=mpeg4',
  '--enable-decoder=vp6',
  '--enable-decoder=vp6a',
  '--enable-decoder=vp6f',
  '--enable-decoder=vp8',
  '--enable-decoder=vp9',
  '--enable-decoder=hevc',
  '--enable-decoder=av1',
  '--enable-decoder=libdav1d',
  '--enable-decoder=theora',
  '--enable-decoder=msmpeg4v1',
  '--enable-decoder=msmpeg4v2',
  '--enable-decoder=msmpeg4v3',
  '--enable-decoder=mjpeg',
  '--enable-decoder=wmv1',
  '--enable-decoder=wmv2',
  '--enable-decoder=wmv3',
  '--enable-decoder=wmv3image',
  '--enable-decoder=ssa',
  '--enable-decoder=ass',
  '--enable-decoder=dvbsub',
  '--enable-decoder=dvdsub',
  '--enable-decoder=srt',
  '--enable-decoder=stl',
  '--enable-decoder=subrip',
  '--enable-decoder=subviewer',
  '--enable-decoder=subviewer1',
  '--enable-decoder=text',
  '--enable-decoder=vplayer',
  '--enable-decoder=webvtt',
  '--enable-decoder=movtext',
  '--enable-parser=h263',
  '--enable-parser=h264',
  '--enable-parser=hevc',
  '--enable-parser=mpeg4video',
  '--enable-parser=mpegvideo',
  '--enable-demuxer=concat',
  '--enable-demuxer=data',
  '--enable-demuxer=flv',
  '--enable-demuxer=hls',
  '--enable-demuxer=live_flv',
  '--enable-demuxer=loas',
  '--enable-demuxer=m4v',
  '--enable-demuxer=mov',
  '--enable-demuxer=mpegps',
  '--enable-demuxer=mpegts',
  '--enable-demuxer=mpegvideo',
  '--enable-demuxer=hevc',
  '--enable-demuxer=rtsp',
  '--enable-demuxer=mjpeg',
  '--enable-demuxer=avi',
  '--enable-demuxer=av1',
  '--enable-demuxer=matroska',
  '--enable-demuxer=dash',
  '--enable-demuxer=webm_dash_manifest',
  '--enable-demuxer=ass',
  '--enable-demuxer=srt',
  '--enable-demuxer=stl',
  '--enable-demuxer=webvtt',
  '--enable-demuxer=subviewer',
  '--enable-demuxer=subviewer1',
  '--enable-demuxer=vplayer',
  '--enable-hwaccel=h263_videotoolbox',
  '--enable-hwaccel=h264_videotoolbox',
  '--enable-hwaccel=hevc_videotoolbox',
  '--enable-hwaccel=mpeg1_videotoolbox',
  '--enable-hwaccel=mpeg2_videotoolbox',
  '--enable-hwaccel=mpeg4_videotoolbox',
  '--enable-hwaccel=vp9_videotoolbox',
]

audio_full_options = [
  '--enable-decoders',
  '--enable-hwaccels',
  '--enable-parsers',
  '--enable-demuxers',
  '--enable-protocols',
  '--enable-bsfs',
  '--enable-filter=overlay',
  '--enable-filter=equalizer',
  '--disable-decoder=h264',
]

video_full_options = [
  '--enable-decoder=h264',
]

audio_encodersgpl_options = [
  '--enable-encoders',
  '--enable-muxers',
  '--enable-filters',
  '--enable-libvorbis',
]

video_encodersgpl_options = [
  '--enable-libvpx',
  '--enable-libx264',
  '--enable-gpl',
]

options = disable_all_options
options += common_options
options += audio_common_options

if variant == 'video'
  options += video_common_options
endif

if flavor == 'default'
  options += audio_default_options
  if variant == 'video'
    options += video_default_options
  endif
elif flavor == 'full'
  options += audio_full_options
  if variant == 'video'
    options += video_full_options
  endif
elif flavor == 'encodersgpl'
  options += audio_full_options
  options += audio_encodersgpl_options
  if variant == 'video'
    options += video_full_options
    options += video_encodersgpl_options
  endif
endif

native_tool_options = [
  '--nm=' + nm.full_path(),
  '--ar=' + ar.full_path(),
  '--as=' + ' '.join(c.cmd_array()),
  '--strip=' + strip.full_path(),
  '--cc=' + ' '.join(c.cmd_array()),
  '--cxx=' + ' '.join(cpp.cmd_array()),
  '--objcc=' + ' '.join(objc.cmd_array()),
  '--ld=' + ' '.join(c.cmd_array()),
  '--pkg-config=' + pkg_config.full_path(),
  '--extra-cflags=' + ' '.join(c_args),
  '--extra-cxxflags=' + ' '.join(cpp_args),
  '--extra-objcflags=' + ' '.join(objc_args),
  '--extra-ldflags=' + ' '.join(c_link_args),
]

p = mod.add_project('configure',
  configure_options: options + native_tool_options,
  verbose: true,
)

meson.override_dependency('libavfilter', p.dependency('avfilter'))
meson.override_dependency('libswscale', p.dependency('swscale'))
meson.override_dependency('libavcodec', p.dependency('avcodec'))
meson.override_dependency('libavformat', p.dependency('avformat'))
meson.override_dependency('libavutil', p.dependency('avutil'))
meson.override_dependency('libswresample', p.dependency('swresample'))
