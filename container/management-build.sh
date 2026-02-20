#!/bin/bash

set -euxo pipefail

ID="`git rev-parse HEAD`"

if [ ! -f build/CMakeCache.txt ]; then
  echo "Running CMake configuration..."
  cmake --preset release -DUSE_LAKE=ON 2>&1 | tee /output/cmake.log
else
  echo "CMake already configured, skipping..."
fi

echo ""
echo "Starting make build..."
timeout "${BUILD_TIMEOUT}" make -C build/release -j$(nproc) 2>&1 | tee /output/build.log
EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE -eq 0 ]; then
  rsync -a --delete /build/ "/builds/$ID"
  echo ""
  echo "✓ Build successful"
  echo "✓ BUILD SUCCESSFUL" >> /output/build.log
else
  echo ""
  echo "✗ Build failed"
  echo "✗ BUILD FAILED (exit $EXIT_CODE)" >> /output/build.log
fi

exit $EXIT_CODE

exit $EXIT_CODE
