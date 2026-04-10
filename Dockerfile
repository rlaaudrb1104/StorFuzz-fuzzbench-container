# usage DooD : docker run -v /var/run/docker.sock:/var/run/docker.sock -v /tmp/storfuzz-fuzzbench2/experiment-data:/tmp/storfuzz-fuzzbench2/experiment-data -v /tmp/storfuzz-fuzzbench2/report-data:/tmp/storfuzz-fuzzbench2/report-data -it StorFuzz
FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

ENV TZ=Asia/Seoul
ENV PYTHONIOENCODING=UTF-8
ENV LC_CTYPE=C.UTF-8
ENV HOME=/root
WORKDIR /root

# setup
RUN apt-get update && \
    apt-get install -y software-properties-common && \
    add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y \
    git sudo gcc gcc-multilib make build-essential curl wget vim unzip \
    python3.10 python3.10-dev python3.10-venv libpq-dev rsync docker.io

# copy entrypoint & patch files
COPY entrypoint.sh /root/entrypoint.sh
COPY storfuzz-patch.patch /root/storfuzz-patch.patch

# StorFuzz setup (StorFuzz Fix version)
# RUN git clone https://github.com/rub-softsec/StorFuzz-fuzzbench.git && \
#     cd StorFuzz-fuzzbench && \
#     git apply /root/storfuzz-patch.patch

COPY StorFuzz-fuzzbench /root/StorFuzz-fuzzbench

WORKDIR /root/StorFuzz-fuzzbench

# copy config file
COPY config.yaml .
COPY cached.zip /root/StorFuzz-fuzzbench/fuzzers/angora/cached.zip

WORKDIR /root/StorFuzz-fuzzbench/fuzzers/angora
RUN unzip /root/StorFuzz-fuzzbench/fuzzers/angora/cached.zip && \
    rm /root/StorFuzz-fuzzbench/fuzzers/angora/cached.zip

WORKDIR /root/StorFuzz-fuzzbench
# virtual environment setup
ENV PATH="/root/StorFuzz-fuzzbench/.venv/bin:$PATH"

RUN python3.10 -m venv .venv && \
    pip install --upgrade pip && \
    pip install --no-compile -r requirements.txt

# base-image & dispatcher-image setup
RUN chmod +x /root/entrypoint.sh

ENTRYPOINT ["/root/entrypoint.sh"]