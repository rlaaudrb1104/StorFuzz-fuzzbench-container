#!/bin/bash
#
# start.sh - StorFuzz-FuzzBench 컨테이너 실행 인터페이스
#
# 사용법:
#   ./start.sh                      # 기본 config.yaml 사용
#   ./start.sh /path/to/config.yaml # 커스텀 config 지정
 
set -euo pipefail
 
IMAGE="myeonggyu/storfuzz-fuzzbench"
CONTAINER_WORKDIR="/root/StorFuzz-fuzzbench"
CONFIG_FILE="${1:-config.yaml}"
 
# ── config.yaml 존재 확인 ──
if [[ ! -f "$CONFIG_FILE" ]]; then
    echo "[ERROR] config.yaml not found: $CONFIG_FILE"
    echo "Usage: $0 [config.yaml path]"
    exit 1
fi
 
# ── config.yaml 파싱 ──
parse_yaml_value() {
    local key="$1"
    grep "^${key}:" "$CONFIG_FILE" | sed "s/^${key}:[[:space:]]*//" | tr -d "'\""
}
 
EXPERIMENT_FILESTORE=$(parse_yaml_value "experiment_filestore")
REPORT_FILESTORE=$(parse_yaml_value "report_filestore")
 
if [[ -z "$EXPERIMENT_FILESTORE" ]]; then
    echo "[ERROR] experiment_filestore not found in $CONFIG_FILE"
    exit 1
fi
 
if [[ -z "$REPORT_FILESTORE" ]]; then
    echo "[ERROR] report_filestore not found in $CONFIG_FILE"
    exit 1
fi

echo "[INFO] Config file       : $CONFIG_FILE"
echo "[INFO] experiment_filestore : $EXPERIMENT_FILESTORE"
echo "[INFO] report_filestore     : $REPORT_FILESTORE"
 
# ── 호스트 디렉토리 생성 ──
mkdir -p "$EXPERIMENT_FILESTORE"
mkdir -p "$REPORT_FILESTORE"
 
# ── config.yaml을 컨테이너에 복사 (임시 컨테이너 이용) ──
echo "[INFO] Copying config.yaml into image..."
TEMP_CONTAINER=$(docker create "$IMAGE")
docker cp "$CONFIG_FILE" "${TEMP_CONTAINER}:${CONTAINER_WORKDIR}/config.yaml"
docker commit "$TEMP_CONTAINER" "${IMAGE}:configured" > /dev/null
docker rm "$TEMP_CONTAINER" > /dev/null
 
# ── 컨테이너 실행 ──
echo "[INFO] Starting container..."
exec docker run \
    -v /usr/libexec/docker/cli-plugins/docker-buildx:/usr/libexec/docker/cli-plugins/docker-buildx \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "${EXPERIMENT_FILESTORE}:${EXPERIMENT_FILESTORE}" \
    -v "${REPORT_FILESTORE}:${REPORT_FILESTORE}" \
    -w "${CONTAINER_WORKDIR}" \
    -it "${IMAGE}:configured"