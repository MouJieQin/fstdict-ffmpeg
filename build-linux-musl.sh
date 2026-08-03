#!/bin/bash
set -euo pipefail
source ./config.env

TARGET_ARCH="x86_64-linux-musl"
rm -rf "${BUILD_ROOT}/linux_${TARGET_ARCH}"
mkdir -p "${BUILD_ROOT}/linux_${TARGET_ARCH}/lame"

cd lame-src
./configure --enable-static --disable-shared --prefix="${PWD}/../build_out/linux_${TARGET_ARCH}/lame"
make -j$(nproc)
make install
cd ..

cd ffmpeg-src
./configure \
    --cross-prefix=x86_64-linux-musl- \
    --arch=x86_64 \
    --target-os=linux \
    "${FFMPEG_CONFIG_FLAGS[@]}" \
    --extra-cflags="-I${PWD}/../build_out/linux_${TARGET_ARCH}/lame/include" \
    --extra-ldflags="-L${PWD}/../build_out/linux_${TARGET_ARCH}/lame/lib -static"
make -j$(nproc)
cp ffmpeg "../${DIST_ROOT}/ffmpeg-linux-x86_64"
cd ..