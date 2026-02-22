#!/bin/bash

set -euo pipefail

if [ -z "${1:-}" ]; then
  echo "Usage: $0 <ref> [source_dir] [build_timeout]"
  echo "  ref:           Git commit hash or branch name to build"
  echo "  source_dir:    Path to source repository (default: current directory)"
  echo "  build_timeout: Build timeout in seconds (default: 1800)"
  exit 1
fi

REF="$1"
SOURCE_DIR="$(cd "${2:-.}" && pwd)"
BUILD_TIMEOUT="${3:-1800}"
OUTPUT_DIR="${HOME}/.lean4-builds/management"
BUILDS_VOLUME=lean-builds
CONTAINER_CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

mkdir -p "$OUTPUT_DIR"

if ! container system status &>/dev/null; then
  echo "Starting container system..."
  container system start
  sleep 5
fi

if ! container list | grep -q lean-squid-proxy; then
  echo "⚠ Proxy not running, starting..."
  container network rm leanbuild lean-proxy-network 2>/dev/null || true
  container network create --internal leanbuild 2>/dev/null || true
  container network create lean-proxy-network 2>/dev/null || true
  container rm -f lean-squid-proxy || true
  container run -d \
    --name lean-squid-proxy \
    --network lean-proxy-network \
    --network leanbuild \
    -v "$CONTAINER_CONFIG_DIR/squid.conf:/etc/squid/squid.conf:ro" \
    -p 127.0.0.1:3128:3128 \
    ubuntu/squid:latest
  sleep 3
fi

if ! container list | grep -q lean-squid-proxy; then
  echo "❌ Proxy failed to start!"
  container logs lean-squid-proxy
  exit 1
fi

PROXY_IP=$(container inspect lean-squid-proxy | \
  jq -r '.[0].networks[] | select(.network=="leanbuild") | .ipv4Address' | \
  cut -d'/' -f1)

echo "Proxy:   ${PROXY_IP}:3128"
echo "Source:  ${SOURCE_DIR}"
echo "Ref:     ${REF}"
echo "Timeout: ${BUILD_TIMEOUT}s"
echo ""

if container run --rm \
  --name "lean4-management-build" \
  --network leanbuild \
  --memory="16g" \
  --cpus="12" \
  -v "${SOURCE_DIR}:/source:ro" \
  -v "${BUILDS_VOLUME}:/builds:rw" \
  -v lean-elan-cache:/root/.elan:rw \
  -v "${OUTPUT_DIR}:/output:rw" \
  -v "${CONTAINER_CONFIG_DIR}/container/sync.sh:/scripts/sync.sh:ro" \
  -v "${CONTAINER_CONFIG_DIR}/container/management-build.sh:/scripts/build.sh:ro" \
  -v "${CONTAINER_CONFIG_DIR}/container/management-build-smart.sh:/scripts/build-smart.sh:ro" \
  -e BUILD_TIMEOUT="${BUILD_TIMEOUT}" \
  -e http_proxy="http://${PROXY_IP}:3128" \
  -e https_proxy="http://${PROXY_IP}:3128" \
  lean4-management \
  bash /scripts/build-smart.sh "$REF"; then
  echo ""
  echo "✓ Build of ${REF} succeeded"
  exit 0
else
  EXIT_CODE=$?
  echo ""
  echo "✗ Build of ${REF} failed (exit code: ${EXIT_CODE})"
  exit $EXIT_CODE
fi
