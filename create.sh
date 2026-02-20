#!/bin/bash

set -euo pipefail

SOURCE_DIR="$(cd "${1:-.}" && pwd)"
BUILD_TIMEOUT="${2:-1800}"
BUILD_ID=$(date +%s)
OUTPUT_DIR="${HOME}/.lean4-builds/${BUILD_ID}"
WORKING_COPY_VOLUME="lean4-working-copy-${BUILD_ID}"
# this would create nested mounts OUTPUT_DIR="$(pwd)/isolated-builds/${BUILD_ID}"

mkdir -p "${OUTPUT_DIR}"
ln -fs "${OUTPUT_DIR}" ./vm-output
touch .proxyrc

echo "Lean4 Isolated Build ${BUILD_ID}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if ! container status &>/dev/null; then
  echo "⚠ Starting container system..."
  container system start # these are Colima-specific arguments: --cpu 8 --memory 16 --mount-type=virtiofs
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
    -v ~/code/lean-isolated/squid.conf:/etc/squid/squid.conf:ro \
    -p 127.0.0.1:3128:3128 \
    ubuntu/squid:latest
  sleep 3
fi

# container network connect leanbuild lean-squid-proxy

if ! container list | grep -q lean-squid-proxy; then
  echo "❌ Proxy failed to start!"
  container logs lean-squid-proxy
  exit 1
fi

# PROXY_HOST=$(container inspect lean-squid-proxy -f '{{.NetworkSettings.Networks.leanbuild.IPAddress}}')
PROXY_IP=$(container inspect lean-squid-proxy | \
  jq -r '.[0].networks[] | select(.network=="leanbuild") | .ipv4Address' | \
  cut -d'/' -f1)

# echo "DEBUG: PROXY_HOST='${PROXY_HOST}'"


echo "Proxy:   ${PROXY_IP}:3128"
echo "Source:  ${SOURCE_DIR}"
echo "Output:  ${OUTPUT_DIR}"
echo "Timeout: ${BUILD_TIMEOUT}s"
echo ""

container run -it \
  --name "lean4-build-${BUILD_ID}" \
  --network leanbuild \
  --memory="16g" \
  --cpus="12" \
  -v "${SOURCE_DIR}:/source:ro" \
  -v "${WORKING_COPY_VOLUME}:/build:rw" \
  -v lean-elan-cache:/root/.elan:rw \
  -v "${OUTPUT_DIR}:/output:rw" \
  -e BUILD_TIMEOUT="${BUILD_TIMEOUT}" \
  -e http_proxy="http://${PROXY_IP}:3128" \
  -e https_proxy="http://${PROXY_IP}:3128" \
  lean4-isolated \
  bash

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
