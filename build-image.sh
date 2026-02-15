#!/bin/bash

set -euo pipefail

docker build -t lean4-isolated -f Dockerfile /docker/
