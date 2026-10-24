#!/bin/bash

set -euo pipefail

SOURCE_DIR="$(cd "${1:-.}" && pwd)"
CONTAINER_CONFIG_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

touch .proxyrc

echo "Creating VM"
echo "━━━━━━━━━━━"

if ! container system status &>/dev/null; then
  echo "⚠ Starting container system..."
  container system start # these are Colima-specific arguments: --cpu 8 --memory 16 --mount-type=virtiofs
  sleep 5
fi

# if ! container list | grep -q lean-squid-proxy; then
#   echo "⚠ Proxy not running, starting..."
#   container network rm leanbuild lean-proxy-network 2>/dev/null || true
#   container network create --internal leanbuild 2>/dev/null || true
#   container network create lean-proxy-network 2>/dev/null || true
#   container rm -f lean-squid-proxy || true
#   container run -d \
#     --name lean-squid-proxy \
#     --network lean-proxy-network \
#     --network leanbuild \
#     -v "$CONTAINER_CONFIG_DIR/squid.conf:/etc/squid/squid.conf:ro" \
#     -p 127.0.0.1:3128:3128 \
#     ubuntu/squid:latest
#   sleep 3
# fi

# if ! container list | grep -q lean-squid-proxy; then
#   echo "❌ Proxy failed to start!"
#   container logs lean-squid-proxy
#   exit 1
# fi

PROXY_IP=192.168.128.1

echo "Proxy:   ${PROXY_IP}:3128"
echo ""

container run -it \
  --name "vm" \
  --network leanbuild \
  --memory="16g" \
  --cpus="12" \
  --cap-add="SYS_ADMIN" \
  -v "vmroot:/root:rw" \
  -v "${SOURCE_DIR}:/source:ro" \
  -v "${CONTAINER_CONFIG_DIR}/container:/setup:ro" \
  -e http_proxy="http://${PROXY_IP}:3128" \
  -e https_proxy="http://${PROXY_IP}:3128" \
  -e IS_SANDBOX=1 \
  -e CLAUDE_CODE_DISABLE_ADAPTIVE_THINKING=1 \
  -e CLAUDE_CODE_AUTO_COMPACT_WINDOW=400000 \
  lean4-isolated \
  bash
