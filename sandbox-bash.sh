#!/bin/bash

set -euo pipefail

SOURCE_DIR="$(cd "${1:-.}" && pwd)"
BUILD_TIMEOUT="${2:-1800}"
BUILD_ID=$(date +%s)
OUTPUT_DIR="${HOME}/.lean4-builds/${BUILD_ID}"
# this would create nested mounts OUTPUT_DIR="$(pwd)/isolated-builds/${BUILD_ID}"

mkdir -p "${OUTPUT_DIR}"

echo "Lean4 Isolated Build ${BUILD_ID}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Stelle sicher dass alles läuft
if ! colima status &>/dev/null; then
  echo "⚠ Starting Colima..."
  colima start --cpu 4 --memory 8 --mount-type=virtiofs
  sleep 5
fi

if ! docker ps | grep -q lean-squid-proxy; then
  echo "⚠ Proxy not running, starting..."
  docker network rm leanbuild lean-proxy-network 2>/dev/null || true
  docker network create --internal leanbuild 2>/dev/null || true
  docker network create lean-proxy-network 2>/dev/null || true
  docker rm -f lean-squid-proxy
  docker run -d \
    --name lean-squid-proxy \
    --network lean-proxy-network \
    -v ~/code/lean-isolated/squid.conf:/etc/squid/squid.conf:ro \
    -p 127.0.0.1:3128:3128 \
    ubuntu/squid:latest
  sleep 3
  docker network connect leanbuild lean-squid-proxy
fi

# Proxy läuft? Check!
if ! docker ps | grep -q lean-squid-proxy; then
  echo "❌ Proxy failed to start!"
  docker logs lean-squid-proxy
  exit 1
fi

PROXY_HOST=$(docker inspect lean-squid-proxy -f '{{.NetworkSettings.Networks.leanbuild.IPAddress}}')

echo "DEBUG: PROXY_HOST='${PROXY_HOST}'"


echo "Proxy:   ${PROXY_HOST}:3128"
echo "Source:  ${SOURCE_DIR}"
echo "Output:  ${OUTPUT_DIR}"
echo "Timeout: ${BUILD_TIMEOUT}s"
echo ""

docker run -it --rm \
  --name "lean4-build-${BUILD_ID}" \
  --network leanbuild \
  --memory="16g" \
  --cpus="8" \
  -v "${SOURCE_DIR}:/source:ro" \
  -v lean4-working-copy:/build:rw \
  -v lean-elan-cache:/root/.elan:rw \
  -v "${OUTPUT_DIR}:/output:rw" \
  -e BUILD_TIMEOUT="${BUILD_TIMEOUT}" \
  -e http_proxy="http://${PROXY_HOST}:3128" \
  -e https_proxy="http://${PROXY_HOST}:3128" \
  lean4-isolated \
  bash -c '
    set -euxo pipefail
    # Sync source → build, preserve build artifacts
    rsync -a --delete \
      --exclude "/build/" \
      --exclude "/.ccache/" \
      --exclude ".DS_Store" \
      /source/ /build/
    cd /build

    if [ ! -f build/CMakeCache.txt ]; then
      echo "⚙️  Running CMake configuration..."
      cmake --preset release -DUSE_LAKE=ON 2>&1 | tee /output/cmake.log
    else
      echo "✓ CMake already configured, skipping..."
    fi
    
    bash
  '

exit

EXIT_CODE=$?

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $EXIT_CODE -eq 0 ]; then
  echo "✓ Build ${BUILD_ID} completed successfully"
  echo "  Output: ${OUTPUT_DIR}"
else
  echo "✗ Build ${BUILD_ID} failed (exit code: ${EXIT_CODE})"
  echo "  Log: ${OUTPUT_DIR}/build.log"
fi

exit $EXIT_CODE
