#!/bin/bash
set -euo pipefail
source ./config.env

# 编译单架构入口
build_arch() {
    ARCH=$1
    echo "==== Build macOS ${ARCH} ===="
    export CFLAGS="-arch ${ARCH}"
    export CXXFLAGS="-arch ${ARCH}"
    export LDFLAGS="-arch ${ARCH}"

    rm -rf build_out/macos_${ARCH}
    mkdir -p build_out/macos_${ARCH}/lame
    mkdir -p build_out/macos_${ARCH}/ffmpeg

    # build lame static
    cd lame-src
    ./configure --enable-static --disable-shared --prefix="${PWD}/../build_out/macos_${ARCH}/lame"
    make -j$(sysctl -n hw.ncpu)
    make install
    cd ..

    # build ffmpeg
    cd ffmpeg-src
    ./configure \
        "${FFMPEG_CONFIG_FLAGS[@]}" \
        --extra-cflags="-I${PWD}/../build_out/macos_${ARCH}/lame/include" \
        --extra-ldflags="-L${PWD}/../build_out/macos_${ARCH}/lame/lib"
    make -j$(sysctl -n hw.ncpu)
    cp ffmpeg "../build_out/macos_${ARCH}/ffmpeg"
    cd ..
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