#!/bin/bash

set -euxo pipefail

# Sync source → build, preserve build artifacts
rsync -a --delete \
  --exclude "/build/" \
  --exclude "/.ccache/" \
  --exclude ".DS_Store" \
  /source/ /build/
