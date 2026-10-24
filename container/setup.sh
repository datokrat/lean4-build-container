#!/bin/bash

set -euxo pipefail

# apt-get update && apt-get install -y \
#   git curl build-essential cmake clang lld libgmp-dev ccache ninja-build rsync clang \
#   pkg-config libuv1-dev zlib1g-dev libssl-dev inetutils-ping vim wget
# 
# export CC=clang
# export CXX=clang++
# 
# # Setze Clang als default C/C++ Compiler
# update-alternatives --install /usr/bin/cc cc /usr/bin/clang 100 && \
#   update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++ 100

curl https://raw.githubusercontent.com/leanprover/elan/master/elan-init.sh -sSf | \
    sh -s -- -y --default-toolchain none --no-modify-path

export PATH="/root/.elan/bin:${PATH}"
export ELAN_HOME="/root/.elan"

elan --version # && lean --version

export CCACHE_DIR=/build/.ccache

bash /setup/install-claude.sh

cp -r /setup/.claude /root/.claude
mv /root/.claude/.claude.json /root/.claude.json || true

sh /setup/install-uv.sh

# RUN ~/.local/bin/claude plugin marketplace add DrCatHicks/learning-opportunities
# RUN ~/.local/bin/claude plugin install learning-opportunities
# RUN ~/.local/bin/claude mcp add lean-lsp uvx lean-lsp-mcp

code-server --install-extension leanprover.lean4

mkdir -p /root/certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /root/certs/key.pem -out /root/certs/cert.pem -subj "/C=US/ST=State/L=City/O=Organization/CN=localhost"
cp /setup/code-server-config.yaml /root/.config/code-server/config.yaml
cp /setup/code-settings.json /root/.local/share/code-server/User/settings.json

git config --global user.email "6992158+datokrat@users.noreply.github.com"
git config --global user.name "Paul Reichert"

