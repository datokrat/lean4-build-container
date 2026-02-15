#!/bin/bash

set -euo pipefail


SOURCE_DIR="$(cd "${1:-.}" && pwd)"
BUILD_TIMEOUT="${2:-1800}"
BUILD_ID=$(date +%s)
OUTPUT_DIR="$(pwd)/isolated-builds/${BUILD_ID}"

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
  docker network create lean-build-network 2>/dev/null || true
  docker rm -f lean-squid-proxy
  docker run -d \
    --name lean-squid-proxy \
    --network lean-build-network \
    -v ~/code/lean-isolated/squid.conf:/etc/squid/squid.conf:ro \
    -p 127.0.0.1:3128:3128 \
    ubuntu/squid:latest
  sleep 3
fi

PROXY_HOST=$(docker inspect lean-squid-proxy -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}')

echo "DEBUG: PROXY_HOST='${PROXY_HOST}'"

echo "Source:  ${SOURCE_DIR}"
echo "Output:  ${OUTPUT_DIR}"
echo "Timeout: ${BUILD_TIMEOUT}s"
echo ""

docker run --rm \
  --name "lean4-build-${BUILD_ID}" \
  --network lean-build-network \
  --memory="16g" \
  --cpus="8" \
#  -v "${SOURCE_DIR}:/source:ro" \           # Source read-only
#  -v lean4-working-copy:/build:rw \
#  -v lean-elan-cache:/root/.elan:rw \
#  -v "${OUTPUT_DIR}:/output:rw" \
  lean4-isolated \
  bash -c '
    echo Test successful
#    # Sync source → build, preserve build artifacts
#    rsync -a --delete \
#      --exclude "/build/" \
#      --exclude "/.git/" \
#      --exclude "/.ccache/" \
#      --exclude ".DS_Store" \
#      /source/ /build/
#    cd /build
#    lake build 2>&1 | tee /output/build.log
#
#    if [ ! -f build/CMakeCache.txt ]; then
#      echo "⚙️  Running CMake configuration..."
#      cmake --preset release -DUSE_LAKE=ON 2>&1 | tee /output/cmake.log
#    else
#      echo "✓ CMake already configured, skipping..."
#    fi
#    
#    echo ""
#    echo "🔨 Starting make build..."
#    timeout "${BUILD_TIMEOUT}" make -C build/release -j$(nproc) 2>&1 | tee /output/build.log
#    EXIT_CODE=${PIPESTATUS[0]}
#    
#    if [ $EXIT_CODE -eq 0 ]; then
#      echo ""
#      echo "✓ Build successful, copying outputs..."
#      echo "✓ BUILD SUCCESSFUL" >> /output/build.log
#    else
#      echo ""
#      echo "✗ Build failed"
#      echo "✗ BUILD FAILED (exit $EXIT_CODE)" >> /output/build.log
#    fi
#    
#    exit $EXIT_CODE
  '

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
