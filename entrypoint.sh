#!/bin/bash
set -e

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

# Set up virtual environment for /root/StorFuzz-fuzzbench
# grep -qF "source /root/StorFuzz-fuzzbench/.venv/bin/activate" ~/.bashrc || echo "source /root/StorFuzz-fuzzbench/.venv/bin/activate" >> ~/.bashrc
# echo "cd /root/StorFuzz-fuzzbench" >> ~/.bashrc

echo "[+] Done! Images built successfully."
echo "[+] To run experiment (example command)"
echo "[>] PYTHONPATH=. python3.10 experiment/run_experiment.py --experiment-config config.yaml --concurrent-builds 1 --runners-cpus 1 --measurers-cpus 1 --experiment-name storfuzz-fuzzbench --fuzzers angora storfuzz --benchmarks zlib_zlib_uncompress_fuzzer"

exec /bin/bash