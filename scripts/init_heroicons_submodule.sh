#!/usr/bin/env bash
set -euo pipefail

# This script initializes or updates the heroicons submodule and ensures it only checks out the `optimized` folder.
# It is safe to run multiple times (idempotent).

ROOT_DIR=$(cd "$(dirname "$0")/.." && pwd)
SUBMODULE_PATH="assets/vendor/heroicons"
REPO_URL="https://github.com/tailwindlabs/heroicons.git"

cd "$ROOT_DIR"

# If submodule not added yet, add it (skip if already configured)
if ! git -c color.ui=false submodule status -- "$SUBMODULE_PATH" >/dev/null 2>&1; then
  if [ ! -e "$SUBMODULE_PATH" ] || [ -d "$SUBMODULE_PATH" ]; then
    echo "[heroicons] Adding submodule at $SUBMODULE_PATH"
    git submodule add "$REPO_URL" "$SUBMODULE_PATH"
  fi
else
  echo "[heroicons] Submodule already configured at $SUBMODULE_PATH"
fi

# Initialize and update submodules
if [ -f .gitmodules ]; then
  echo "[heroicons] Initializing and updating submodules"
  git submodule update --init --recursive "$SUBMODULE_PATH" || true
fi

# Configure sparse checkout within the submodule to only include the optimized folder
if [ -d "$SUBMODULE_PATH/.git" ]; then
  echo "[heroicons] Enabling sparse-checkout for optimized"
  git -C "$SUBMODULE_PATH" sparse-checkout set --cone optimized || true
fi

echo "[heroicons] Submodule ready at $SUBMODULE_PATH"
