#!/bin/bash

set -euxo pipefail

IP="`hostname -I | awk '{print $1}'`"

echo "When the server has started, open https://$IP:8080/?workspace=/build/lean.code-workspace"

code-server --cert=/certs/cert.pem --cert-key=/certs/key.pem --bind-addr 0.0.0.0:8080

