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

RUN mkdir /scripts

# RUN curl -fsSL https://claude.ai/install.sh | bash
COPY container/install-claude.sh /scripts/install-claude.sh

RUN bash /scripts/install-claude.sh
RUN echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc

RUN apt-get install -y wget

RUN cd /scripts && wget https://elan.lean-lang.org/elan-init.sh
RUN cd /scripts && sh elan-init.sh -y
RUN echo "source /root/.elan/env" >> /root/.bashrc

# RUN curl -LsSf https://astral.sh/uv/install.sh | sh
COPY container/install-uv.sh /scripts/install-uv.sh
RUN sh /scripts/install-uv.sh

RUN ~/.local/bin/claude plugin marketplace add DrCatHicks/learning-opportunities
RUN ~/.local/bin/claude plugin install learning-opportunities
RUN ~/.local/bin/claude mcp add lean-lsp uvx lean-lsp-mcp

RUN echo "source /source/.proxyrc" >> /root/.bashrc

COPY container/sync.sh /scripts/sync.sh
COPY container/build.sh /scripts/build.sh

RUN rm -rf /var/lib/apt/lists/*

WORKDIR /build

