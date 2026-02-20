#!/bin/bash

set -euo pipefail

container build -t lean4-isolated -f Dockerfile .
container build -t lean4-management -f management.Dockerfile .
