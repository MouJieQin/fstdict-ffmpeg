#!/bin/bash
set -euo pipefail
source ./config.env

TARGET_ARCH="x86_64-linux-musl"
ROOT_DIR="$(pwd)"
LAME_PREFIX="${ROOT_DIR}/${BUILD_ROOT}/linux_${TARGET_ARCH}/lame"
DIST_DIR="${ROOT_DIR}/${DIST_ROOT}"

# 创建目标目录
mkdir -p "${LAME_PREFIX}"
mkdir -p "${DIST_DIR}"

# 1. 编译 LAME (必须指定 musl 编译器和 host 架构)
cd lame-src
CC="musl-gcc" ./configure \
    --host=x86_64-linux-gnu \
    --target=x86_64-linux-musl \
    --enable-static \
    --disable-shared \
    --disable-frontend \
    --disable-x86asm \
    --prefix="${LAME_PREFIX}"

make -j$(nproc)
make install
cd "${ROOT_DIR}"

# Build FFmpeg
cd ffmpeg-src
export PKG_CONFIG=/usr/bin/false

./configure \
    --cc="musl-gcc" \
    --ar="ar" \
    --nm="nm" \
    --arch=x86_64 \
    --target-os=linux \
    --disable-x86asm \
    "${FFMPEG_CONFIG_FLAGS[@]}" \
    --extra-cflags="-I${LAME_PREFIX}/include" \
    --extra-ldflags="-L${LAME_PREFIX}/lib -static" \
    --extra-libs="-lm -lpthread"


make -j$(nproc)
cp ffmpeg "${DIST_DIR}/ffmpeg-linux-x86_64"
chmod +x "${DIST_DIR}/ffmpeg-linux-x86_64"
cd "${DIST_DIR}"
tar -czf ffmpeg-linux-x86_64.tar.gz ffmpeg-linux-x86_64
rm ffmpeg-linux-x86_64
cd "${ROOT_DIR}"
