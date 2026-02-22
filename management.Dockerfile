FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    git \
    curl \
    build-essential \
    cmake \
    clang \
    lld \
    libgmp-dev \
    ccache \
    ninja-build \
    rsync

RUN apt-get install -y clang

RUN apt-get install -y \
    git curl build-essential cmake clang lld \
    libgmp-dev ccache ninja-build rsync \
    pkg-config libuv1-dev zlib1g-dev \
    libssl-dev \
    inetutils-ping \
    vim

RUN apt-get install -y wget

ENV CC=clang
ENV CXX=clang++

RUN update-alternatives --install /usr/bin/cc cc /usr/bin/clang 100 && \
    update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++ 100

RUN curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | \
    sh -s -- -y --default-toolchain none --no-modify-path

ENV PATH="/root/.elan/bin:${PATH}"
ENV ELAN_HOME="/root/.elan"

ENV CCACHE_DIR=/build/.ccache

RUN mkdir /scripts

RUN cd /scripts && wget https://elan.lean-lang.org/elan-init.sh
RUN cd /scripts && sh elan-init.sh -y
RUN echo "source /root/.elan/env" >> /root/.bashrc

RUN elan --version

COPY container/sync.sh /scripts/sync.sh
COPY container/management-build.sh /scripts/build.sh
COPY container/management-build-smart.sh /scripts/build-smart.sh
COPY container/management-restore.sh /scripts/restore.sh

RUN rm -rf /var/lib/apt/lists/*

WORKDIR /build

