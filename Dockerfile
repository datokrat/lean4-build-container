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
    libssl-dev

RUN rm -rf /var/lib/apt/lists/*

ENV CC=clang
ENV CXX=clang++


# Setze Clang als default C/C++ Compiler
RUN update-alternatives --install /usr/bin/cc cc /usr/bin/clang 100 && \
    update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++ 100

RUN curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | \
    sh -s -- -y --default-toolchain none --no-modify-path

ENV PATH="/root/.elan/bin:${PATH}"
ENV ELAN_HOME="/root/.elan"

# Pre-install stable für schnelle Tests
# RUN elan toolchain install stable

RUN elan --version # && lean --version

ENV CCACHE_DIR=/build/.ccache

WORKDIR /build
