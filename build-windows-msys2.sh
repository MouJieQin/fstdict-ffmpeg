#!/bin/bash
set -euo pipefail
source ./config.env

rm -rf "${BUILD_ROOT}/windows_x86_64"
mkdir -p "${BUILD_ROOT}/windows_x86_64/lame"

cd lame-src
./configure \
    --enable-static \
    --disable-shared \
    --disable-frontend \
    --disable-x86asm \
    --prefix="${PWD}/../build_out/windows_x86_64/lame"
make -j$(nproc)
make install
cd ..


cd ffmpeg-src
./configure \
    --disable-x86asm \
    "${FFMPEG_CONFIG_FLAGS[@]}" \
    --extra-cflags="-I${PWD}/../build_out/windows_x86_64/lame/include" \
    --extra-ldflags="-L${PWD}/../build_out/windows_x86_64/lame/lib -static -static-libgcc -static-libstdc++"
make -j$(nproc)
cp ffmpeg.exe "../${DIST_ROOT}/ffmpeg-windows-x86_64.exe"
cd ..