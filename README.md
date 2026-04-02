# StorFuzz-fuzzbench: Dockerized Local Experiment Environment
Storfuzz-fuzzbench 환경에서 Angora 퍼저 빌드 및 실험을 위한 StorFuzz-fuzzbench의 도커 컨테이너 환경입니다. 

원본 코드는 아래 링크에서 확인하실 수 있습니다.

🔗 **Original Repository:** https://github.com/rub-softsec/StorFuzz-fuzzbench/

## 🚀 Getting Started

### 1. 설정 파일 세팅 (`config.yaml`)
원활한 볼륨 마운트를 위해 `experiment_filestore`와 `report_filestore`의 경로는 반드시 호스트의 `/tmp` 하위 폴더 절대 경로로 설정해야 합니다.

**`config.yaml` 예시**
```yaml
experiment_filestore: /tmp/storfuzz-fuzzbench/experiment-data
report_filestore: /tmp/storfuzz-fuzzbench/report-data
```

### 2. 도커 이미지 빌드
```bash
docker build -t storfuzz-fuzzbench .
```

### 3. 컨테이너 실행 (DooD 방식)
호스트의 도커 소켓과 1단계에서 설정한 데이터 경로를 볼륨으로 마운트하여 컨테이너를 실행합니다.

***주의*** : 아래 명령어의 볼륨 경로는 config.yaml에 작성한 경로와 완전히 동일해야 합니다.
```bash
docker run -v /var/run/docker.sock:/var/run/docker.sock \
           -v /tmp/StorFuzz-fuzzbench/experiment-data:/tmp/StorFuzz-fuzzbench/experiment-data \
           -v /tmp/StorFuzz-fuzzbench/report-data:/tmp/StorFuzz-fuzzbench/report-data \
           -it storfuzz-fuzzbench
```

### 4. 퍼징 실험 시작
컨테이너 실행 후 내부 하위 이미지 빌드가 끝나고 쉘(`(venv)`)에 성공적으로 진입했다면, 아래 명령어를 실행하여 본격적인 퍼징 테스트를 시작할 수 있습니다.
```
PYTHONPATH=. python3.10 experiment/run_experiment.py \
  --experiment-config config.yaml \
  --concurrent-builds 1 \
  --runners-cpus 1 \
  --measurers-cpus 1 \
  --experiment-name storfuzz-fuzzbench \
  --fuzzers angora storfuzz \
  --benchmarks zlib_zlib_uncompress_fuzzer
```