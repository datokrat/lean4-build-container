#!/bin/bash

set -euo pipefail

docker volume create lean4-build-cache
docker volume create lean-elan-cache

docker network create lean-build-network 2>/dev/null || true

