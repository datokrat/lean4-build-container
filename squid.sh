#!/bin/bash

set -euo pipefail

if ! container status &>/dev/null; then
  echo "⚠ Starting container system..."
  container system start # these are Colima-specific arguments: --cpu 8 --memory 16 --mount-type=virtiofs
  sleep 5
fi

if container list | grep -q lean-squid-proxy; then
  echo "stopping..."
  container kill lean-squid-proxy
  echo "stopped"
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
