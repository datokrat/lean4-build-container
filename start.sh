#!/bin/bash

set -euxo pipefail

PROXY_IP=$(container inspect lean-squid-proxy | \
  jq -r '.[0].networks[] | select(.network=="leanbuild") | .ipv4Address' | \
  cut -d'/' -f1)

rm -f ./.proxyrc
echo "export https_proxy=http://$PROXY_IP:3128" >> ./.proxyrc
echo "export http_proxy=http://$PROXY_IP:3128" >> ./.proxyrc

container start --interactive "lean4-build-$1"
