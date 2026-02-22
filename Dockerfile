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

COPY container/.claude /root/.claude
RUN cp /root/.claude/.claude.json /root/.claude.json || true
# COPY container/.claude.json /root/.claude.json

RUN apt-get install -y wget

RUN cd /scripts && wget https://elan.lean-lang.org/elan-init.sh
RUN cd /scripts && sh elan-init.sh -y
RUN echo "source /root/.elan/env" >> /root/.bashrc

# RUN curl -LsSf https://astral.sh/uv/install.sh | sh
COPY container/install-uv.sh /scripts/install-uv.sh
RUN sh /scripts/install-uv.sh

WORKDIR /build

RUN ~/.local/bin/claude plugin marketplace add DrCatHicks/learning-opportunities
RUN ~/.local/bin/claude plugin install learning-opportunities
RUN ~/.local/bin/claude mcp add lean-lsp uvx lean-lsp-mcp

RUN echo "source /source/.proxyrc" >> /root/.bashrc

COPY container/sync.sh /scripts/sync.sh
COPY container/build.sh /scripts/build.sh
COPY container/restore.sh /scripts/restore.sh

RUN curl -fsSL https://code-server.dev/install.sh | sh
RUN code-server --install-extension leanprover.lean4

RUN mkdir -p /certs
RUN openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /certs/key.pem -out /certs/cert.pem -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
# COPY container/code-settings.json /root/.local/share/code-server/User/settings.json
COPY container/code.sh /scripts/code.sh
COPY container/code-server-config.yaml /root/.config/code-server/config.yaml
COPY container/code-settings.json /root/.local/share/code-server/User/settings.json

RUN rm -rf /var/lib/apt/lists/*

