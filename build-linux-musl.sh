#!/bin/bash
set -euo pipefail
source ./config.env

TARGET_ARCH="x86_64-linux-musl"
rm -rf "${BUILD_ROOT}/linux_${TARGET_ARCH}"
mkdir -p "${BUILD_ROOT}/linux_${TARGET_ARCH}/lame"
LAME_PREFIX="${PWD}/${BUILD_ROOT}/linux_${TARGET_ARCH}/lame"

# Build LAME
cd lame-src
./configure \
    --enable-static \
    --disable-shared \
    --disable-frontend \
    --disable-x86asm \
    --prefix="${LAME_PREFIX}"
make -j$(nproc)
make install
cd ..

# Build FFmpeg
cd ffmpeg-src
NM=nm ./configure \
    --cross-prefix=x86_64-linux-musl- \
    --arch=x86_64 \
    --target-os=linux \
    --disable-x86asm \
    "${FFMPEG_CONFIG_FLAGS[@]}" \
    --extra-cflags="-I${LAME_PREFIX}/include" \
    --extra-ldflags="-L${LAME_PREFIX}/lib -static"
make -j$(nproc)
cp ffmpeg "../${DIST_ROOT}/ffmpeg-linux-x86_64"
cd ..