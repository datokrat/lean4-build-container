#!/bin/bash

set -euxo pipefail

ID="`git rev-parse \"$1\"`"

rsync -a --delete "/builds/$ID/build/" /build/build/
rsync -a --delete "/builds/$ID/.ccache/" /build/.ccache/
