#!/bin/bash
set -euo pipefail
source ./config.env

# 编译单架构入口
build_arch() {
    ARCH=$1
    echo "==== Build macOS ${ARCH} ===="
    
    ROOT_DIR="$(pwd)"
    LAME_PREFIX="${ROOT_DIR}/build_out/macos_${ARCH}/lame"
    FFMPEG_OUT="${ROOT_DIR}/build_out/macos_${ARCH}/ffmpeg"
    
    export CFLAGS="-arch ${ARCH}"
    export CXXFLAGS="-arch ${ARCH}"
    export LDFLAGS="-arch ${ARCH}"
    
    rm -rf "build_out/macos_${ARCH}"
    mkdir -p "${LAME_PREFIX}"
    mkdir -p "${FFMPEG_OUT}"
    
    # 1. 编译 LAME (使用独立的架构目录以免交叉污染)
    rm -rf "lame-src-${ARCH}"
    cp -r lame-src "lame-src-${ARCH}"
    cd "lame-src-${ARCH}"
    
    ./configure \
    --host=$(if [ "$ARCH" = "arm64" ]; then echo "arm-apple-darwin"; else echo "x86_64-apple-darwin"; fi) \
    --enable-static \
    --disable-shared \
    --disable-frontend \
    --disable-x86asm \
    --prefix="${LAME_PREFIX}"
    
    make -j$(sysctl -n hw.ncpu)
    make install
    cd "${ROOT_DIR}"
    rm -rf "lame-src-${ARCH}"
    
    # 2. 编译 FFmpeg (分离源码目录，彻底解决 cputype 冲突问题)
    rm -rf "ffmpeg-src-${ARCH}"
    cp -r ffmpeg-src "ffmpeg-src-${ARCH}"
    cd "ffmpeg-src-${ARCH}"
    
    export PKG_CONFIG=/usr/bin/false
    
    ./configure \
    "${FFMPEG_CONFIG_FLAGS[@]}" \
    --arch="${ARCH}" \
    --target-os=darwin \
    --extra-cflags="-I${LAME_PREFIX}/include" \
    --extra-ldflags="-L${LAME_PREFIX}/lib" \
    --extra-libs="-lm"
    
    make -j$(sysctl -n hw.ncpu)
    cp ffmpeg "${FFMPEG_OUT}/"
    cd "${ROOT_DIR}"
    rm -rf "ffmpeg-src-${ARCH}"
    
    # 复制单架构二进制文件到 dist 目录并签名
    mkdir -p "${DIST_ROOT}"
    cp "${FFMPEG_OUT}/ffmpeg" "${DIST_ROOT}/ffmpeg-macos-${ARCH}"
    codesign --force --deep --sign - "${DIST_ROOT}/ffmpeg-macos-${ARCH}"
}

# 1. 分别清洁编译双架构
build_arch arm64
build_arch x86_64

# 2. 使用 lipo 合并生成通用二进制 (Universal Binary)
echo "==== Creating macOS Universal Binary ===="
lipo -create \
    "${DIST_ROOT}/ffmpeg-macos-arm64" \
    "${DIST_ROOT}/ffmpeg-macos-x86_64" \
    -output "${DIST_ROOT}/ffmpeg-macos-universal"

# 对通用二进制进行自签名
codesign --force --deep --sign - "${DIST_ROOT}/ffmpeg-macos-universal"
