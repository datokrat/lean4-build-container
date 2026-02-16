#!/bin/bash

set -euxo pipefail

container start --interactive "lean4-build-$1"
