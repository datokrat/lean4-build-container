#!/bin/bash

set -euo pipefail

container build -t lean4-isolated -f Dockerfile .
