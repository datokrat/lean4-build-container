#!/bin/bash

set -euxo pipefail

ID="$1"

rsync -a --delete \
  "/builds/$ID" /build/
