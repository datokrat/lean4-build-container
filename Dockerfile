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
    && rm -rf /var/lib/apt/lists/*

RUN curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | \
    sh -s -- -y --default-toolchain none --no-modify-path

ENV PATH="/root/.elan/bin:${PATH}"
ENV ELAN_HOME="/root/.elan"

# Pre-install stable für schnelle Tests
# RUN elan toolchain install stable

RUN elan --version # && lean --version

ENV CCACHE_DIR=/build/.ccache

WORKDIR /build
