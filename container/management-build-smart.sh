#!/bin/bash

set -euxo pipefail

REF="$1"

# Resolve REF to a commit hash using the read-only /source repo
TARGET_COMMIT=$(git -C /source rev-parse "$REF")

# Check if we already have a build for the exact target commit
if [ -d "/builds/$TARGET_COMMIT" ]; then
  echo "Build already exists for $TARGET_COMMIT, nothing to do"
  exit 0
fi

# Search for a stored build in the commit history
MAX_COMMITS=100
FOUND_COMMIT=""
CURRENT_COMMIT="$TARGET_COMMIT"

for i in $(seq 1 $MAX_COMMITS); do
  # Get the parent commit
  PARENT_COMMIT=$(git -C /source rev-parse "${CURRENT_COMMIT}^" 2>/dev/null || true)

  if [ -z "$PARENT_COMMIT" ]; then
    echo "Reached root commit without finding a stored build"
    break
  fi

  # Check if this is a "chore: update stage0" commit
  COMMIT_TITLE=$(git -C /source log --format=%s -n1 "$PARENT_COMMIT")
  if [ "$COMMIT_TITLE" = "chore: update stage0" ]; then
    echo "Hit 'chore: update stage0' commit, giving up on history search"
    break
  fi

  # Check if we have a build for this commit
  if [ -d "/builds/$PARENT_COMMIT" ]; then
    FOUND_COMMIT="$PARENT_COMMIT"
    echo "Found stored build at commit $FOUND_COMMIT ($i commits back)"
    break
  fi

  CURRENT_COMMIT="$PARENT_COMMIT"
done

if [ -n "$FOUND_COMMIT" ]; then
  # Restore the found build (includes .git, so /build becomes a repo)
  echo "Restoring build from $FOUND_COMMIT..."
  rsync -a --delete "/builds/$FOUND_COMMIT/" /build/

  # Checkout the target ref
  echo "Checking out $REF ($TARGET_COMMIT)..."
  git -C /build checkout "$TARGET_COMMIT"
else
  # No stored build found, need to sync first
  echo "No stored build found in history, syncing from /source..."
  bash /scripts/sync.sh

  # Checkout the target ref
  echo "Checking out $REF ($TARGET_COMMIT)..."
  git -C /build checkout "$TARGET_COMMIT"
fi

# Run the build
echo "Running build..."
exec bash /scripts/build.sh
