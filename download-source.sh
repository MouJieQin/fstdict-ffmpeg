#!/bin/bash
# download-source.sh
set -euo pipefail
source ./config.env

download_file() {
    local FILENAME="$1"
    local OFFICIAL_URL="$2"
    local LOCAL_PATH="$3"

    # 优先本仓库release资产
    PRIMARY_URL="https://github.com/${REPO_OWNER}/${REPO_NAME}/releases/download/${SOURCE_RELEASE_TAG}/${FILENAME}"
    echo "Try download from repo asset: ${PRIMARY_URL}"
    if curl -fsSL "${PRIMARY_URL}" -o "${LOCAL_PATH}"; then
        echo "Download success from repo asset"
        return 0
    fi

    echo "Fallback to official source: ${OFFICIAL_URL}"
    curl -fsSL "${OFFICIAL_URL}" -o "${LOCAL_PATH}"
    return $?
}

# 下载 ffmpeg
FFMPEG_FILE="ffmpeg-${FFMPEG_VERSION}.tar.xz"
FFMPEG_OFFICIAL="https://ffmpeg.org/releases/${FFMPEG_FILE}"
download_file "${FFMPEG_FILE}" "${FFMPEG_OFFICIAL}" "./${FFMPEG_FILE}"

# 下载 lame
LAME_FILE="lame-${LAME_VERSION}.tar.gz"
LAME_OFFICIAL="https://downloads.sourceforge.net/project/lame/lame/3.100/${LAME_FILE}"
download_file "${LAME_FILE}" "${LAME_OFFICIAL}" "./${LAME_FILE}"

# 解压
rm -rf ffmpeg-src lame-src
mkdir -p ffmpeg-src lame-src
tar -xf "${FFMPEG_FILE}" -C ffmpeg-src --strip-components 1
tar -xf "${LAME_FILE}" -C lame-src --strip-components 1