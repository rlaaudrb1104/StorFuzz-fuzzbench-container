#!/bin/bash
# StorFuzz 전체 빌드 & 실행 자동화 스크립트
#
# 사용법:
#   bash setup.sh <username>                                      # prebuild 포함 전체 실행
#   bash setup.sh <username> --skip-prebuild                      # prebuild 및 zip 생략
#   bash setup.sh <username> --seed-corpus /path/to/seed_corpus   # seed corpus 마운트

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FUZZERS_DIR="${SCRIPT_DIR}/StorFuzz-fuzzbench/fuzzers"
SEED_CORPUS=""

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info()  { echo -e "${GREEN}[INFO]${NC} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${NC} $*"; }
error() { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ─── 인자 파싱 ───
if [ $# -lt 1 ]; then
    error "사용법: bash setup.sh <username> [--skip-prebuild]"
fi

USERNAME="$1"
shift

SKIP_PREBUILD=false
while [ $# -gt 0 ]; do
    case "$1" in
        --skip-prebuild) SKIP_PREBUILD=true; shift ;;
        --seed-corpus)
            [ $# -lt 2 ] && error "--seed-corpus 옵션에 경로를 지정해주세요."
            SEED_CORPUS="$2"; shift 2 ;;
        *) error "알 수 없는 옵션: $1" ;;
    esac
done

IMAGE_NAME="${USERNAME}/storfuzz-fuzzbench"
EXPERIMENT_DATA="/tmp/${USERNAME}/storfuzz-fuzzbench/experiment-data"
REPORT_DATA="/tmp/${USERNAME}/storfuzz-fuzzbench/report-data"

info "사용자: ${USERNAME}"
info "이미지: ${IMAGE_NAME}"

# ─── Phase 1: Prebuild ───
if [ "$SKIP_PREBUILD" = false ]; then
    info "=========================================="
    info "Phase 1: snappy_angora prebuild"
    info "=========================================="
    cd "${FUZZERS_DIR}/snappy_angora"
    bash prebuild.sh

    info "=========================================="
    info "Phase 2: snappy_angora_reusing prebuild"
    info "=========================================="
    cd "${FUZZERS_DIR}/snappy_angora_reusing"
    bash prebuild.sh

    # ─── Phase 2: cached.zip 생성 ───
    info "=========================================="
    info "Phase 3: cached.zip 생성"
    info "=========================================="

    for fuzzer in snappy_angora snappy_angora_reusing; do
        FUZZER_DIR="${FUZZERS_DIR}/${fuzzer}"
        if [ ! -d "${FUZZER_DIR}/cached" ]; then
            error "${fuzzer}/cached/ 디렉토리가 없습니다. prebuild를 먼저 실행하세요."
        fi
        info "${fuzzer}/cached.zip 생성 중..."
        cd "${FUZZER_DIR}"
        zip -r cached.zip cached/ > /dev/null
        info "${fuzzer}/cached.zip 완료"
    done
else
    warn "prebuild 및 zip 생략 (--skip-prebuild)"
fi

# ─── Phase 3: 루트 Docker 이미지 빌드 ───
info "=========================================="
info "Phase 4: 루트 Docker 이미지 빌드 (${IMAGE_NAME})"
info "=========================================="
cd "${SCRIPT_DIR}"
docker build -t "${IMAGE_NAME}" .

# ─── Phase 4: 호스트 디렉토리 생성 ───
info "=========================================="
info "Phase 5: 호스트 디렉토리 준비"
info "=========================================="
mkdir -p "${EXPERIMENT_DATA}"
mkdir -p "${REPORT_DATA}"
info "experiment-data: ${EXPERIMENT_DATA}"
info "report-data:     ${REPORT_DATA}"

# ─── Phase 5: 컨테이너 실행 ───
info "=========================================="
info "Phase 6: 컨테이너 실행"
info "=========================================="

SEED_MOUNT=""
if [ -n "${SEED_CORPUS}" ]; then
    [ -d "${SEED_CORPUS}" ] || error "seed corpus 디렉토리가 없습니다: ${SEED_CORPUS}"
    SEED_MOUNT="-v ${SEED_CORPUS}:/seed_corpus"
    info "seed_corpus 마운트: ${SEED_CORPUS} → /seed_corpus"
else
    info "seed corpus 미지정 — 마운트 생략"
fi

docker run \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v "${EXPERIMENT_DATA}:${EXPERIMENT_DATA}" \
    -v "${REPORT_DATA}:${REPORT_DATA}" \
    ${SEED_MOUNT} \
    -it "${IMAGE_NAME}"
