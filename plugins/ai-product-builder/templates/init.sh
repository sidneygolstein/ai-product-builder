#!/bin/bash
set -e

echo "Initializing ai-product-builder project..."

# Install dependencies if package.json exists
if [ -f package.json ]; then
  npm install
fi

echo "Done. Next: fill in feature_list.json and open progress.md."
