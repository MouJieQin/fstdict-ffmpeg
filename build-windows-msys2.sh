#!/bin/bash
set -euo pipefail
source ./config.env

# 1. 锁死绝对路径，避免 MSYS2 相对路径定位失效
ROOT_DIR="$(pwd)"
LAME_PREFIX="${ROOT_DIR}/build_out/windows_x86_64/lame"
DIST_DIR="${ROOT_DIR}/${DIST_ROOT}"

# 2. 彻底初始化清理，并确保创建输出文件夹
rm -rf "${ROOT_DIR}/build_out/windows_x86_64"
mkdir -p "${LAME_PREFIX}"
mkdir -p "${DIST_DIR}"

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
cd "${ROOT_DIR}"

# Build FFmpeg
cd ffmpeg-src
export PKG_CONFIG=/usr/bin/false
./configure \
    --disable-x86asm \
    "${FFMPEG_CONFIG_FLAGS[@]}" \
    --extra-cflags="-I${LAME_PREFIX}/include" \
    --extra-ldflags="-L${LAME_PREFIX}/lib -static -static-libgcc -static-libstdc++"
make -j$(nproc)

# 复制到保证存在的绝对目标文件夹
cp ffmpeg.exe "${DIST_DIR}/ffmpeg-windows-x86_64.exe"
cd "${DIST_DIR}"
pacman -S --noconfirm zip # 确保 msys2 环境中有 zip 命令
zip ffmpeg-windows-x86_64.zip ffmpeg-windows-x86_64.exe
rm ffmpeg-windows-x86_64.exe
cd "${ROOT_DIR}"
