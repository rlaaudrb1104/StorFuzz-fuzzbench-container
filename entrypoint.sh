#!/bin/bash
set -e

WORKDIR="/root/StorFuzz-fuzzbench"
CONFIG="${WORKDIR}/config.yaml"

cd /root/StorFuzz-fuzzbench

# base-image build
if [[ "$(docker images -q gcr.io/fuzzbench/base-image 2> /dev/null)" == "" ]]; then
  echo "[+] Building base-image..."
  docker build -f docker/base-image/Dockerfile -t gcr.io/fuzzbench/base-image .
else
  echo "[+] gcr.io/fuzzbench/base-image already exists. Skipping build."
fi

# dispatcher-image build
cp docker/dispatcher-image/startup-dispatcher.sh .
if [[ "$(docker images -q gcr.io/fuzzbench/dispatcher-image 2> /dev/null)" == "" ]]; then
  echo "[+] Building dispatcher-image..."
  docker build -f docker/dispatcher-image/Dockerfile -t gcr.io/fuzzbench/dispatcher-image .
else
  echo "[+] gcr.io/fuzzbench/dispatcher-image already exists. Skipping build."
fi

echo "[+] Done! Images built successfully."
echo "[+] To run experiment (example command)"


if [[ ! -f "$CONFIG" ]]; then
    echo "[ERROR] $CONFIG not found"
    exit 1
fi
 
# ── config.yaml 주석 파싱 ──
parse_comment() {
    local key="$1"
    local val
    val=$(grep "^#[[:space:]]*${key}[[:space:]]*:" "$CONFIG" | head -1 | sed "s/^#[[:space:]]*${key}[[:space:]]*:[[:space:]]*//" | xargs)
    echo "$val"
}
 
FUZZERS=$(parse_comment "fuzzers")
TARGETS=$(parse_comment "targets")
RC=$(parse_comment "runners-cpus")
MC=$(parse_comment "measurers-cpus")
CUSTOM_CORPUS=$(parse_comment "custom_corpus")
EXP_NAME=$(parse_comment "experiment-name")
CB=$(parse_comment "concurrent-builds")
 
# ── 기본값 ──
RC="${RC:-1}"
MC="${MC:-1}"
EXP_NAME="${EXP_NAME:-storfuzz-fuzzbench}"
CB="${CB:-2}"
 
# ── 필수값 확인 ──
if [[ -z "$FUZZERS" ]]; then
    echo "[ERROR] 'fuzzers' not found in $CONFIG"
    exit 1
fi
if [[ -z "$TARGETS" ]]; then
    echo "[ERROR] 'targets' not found in $CONFIG"
    exit 1
fi
 
# ── 공백 정리 ──
FUZZERS=$(echo "$FUZZERS" | xargs)
TARGETS=$(echo "$TARGETS" | xargs)
 
# ── 커맨드 조립 ──
CMD="PYTHONPATH=. python3.10 experiment/run_experiment.py"
CMD+=" --experiment-config config.yaml"
CMD+=" --experiment-name $EXP_NAME"
CMD+=" --runners-cpus $RC"
CMD+=" --measurers-cpus $MC"
CMD+=" --concurrent-builds $CB"
CMD+=" --fuzzers $FUZZERS"
CMD+=" --benchmarks $TARGETS"
 
if [[ -n "$CUSTOM_CORPUS" ]]; then
    CMD+=" -cs $CUSTOM_CORPUS"
fi
 
echo "[>] $CMD"
echo ""
 
# cd "$WORKDIR"
# exec bash -c "$CMD"
exec /bin/bash