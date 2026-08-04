#!/bin/bash
set -euo pipefail
source ./config.env

# 编译单架构入口
build_arch() {
    ARCH=$1
    echo "==== Build macOS ${ARCH} ===="
    
    # 1. 锁定绝对路径，防止 cd 切换目录后相对路径失效
    ROOT_DIR="$(pwd)"
    LAME_PREFIX="${ROOT_DIR}/build_out/macos_${ARCH}/lame"
    FFMPEG_OUT="${ROOT_DIR}/build_out/macos_${ARCH}/ffmpeg"
    
    export CFLAGS="-arch ${ARCH}"
    export CXXFLAGS="-arch ${ARCH}"
    export LDFLAGS="-arch ${ARCH}"
    
    rm -rf "build_out/macos_${ARCH}"
    mkdir -p "${LAME_PREFIX}"
    mkdir -p "${FFMPEG_OUT}"
    
    # build lame static
    cd lame-src
    ./configure \
    --host=$(if [ "$ARCH" = "arm64" ]; then echo "arm-apple-darwin"; else echo "x86_64-apple-darwin"; fi) \
    --enable-static \
    --disable-shared \
    --disable-frontend \
    --disable-x86asm \
    --prefix="${LAME_PREFIX}"
    
    make -j$(sysctl -n hw.ncpu)
    make install
    cd "${ROOT_DIR}" # 安全返回根目录
    
    # build ffmpeg
    cd ffmpeg-src
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
    cd "${ROOT_DIR}" # 安全返回根目录
}


# 分别编译双架构
build_arch arm64
build_arch x86_64

# lipo 合并通用二进制
mkdir -p "${DIST_ROOT}"
lipo -create \
"${BUILD_ROOT}/macos_arm64/ffmpeg" \
"${BUILD_ROOT}/macos_x86_64/ffmpeg" \
-output "${DIST_ROOT}/ffmpeg-macos-universal"

# 自签名，绕过mac隔离
codesign --force --deep --sign - "${DIST_ROOT}/ffmpeg-macos-universal"