#!/bin/bash

# Exit on error
set -e

echo "=== DIAGNOSTICS ==="
./flutter/bin/flutter --version
./flutter/bin/flutter build web -h | grep "web-renderer" || echo "Note: --web-renderer flag not found in help"

echo "=== BUILDING WEB ==="
# Minimal command. No renderer flag, no verbose.
./flutter/bin/flutter build web --release --dart-define=DEEPSEEK_API_KEY="$DEEPSEEK_API_KEY"

echo "=== POST-BUILD CHECK ==="
if [ -d "build/web" ]; then
  echo "Success: Contents of build/web:"
  ls -F build/web/
  
  # Ensure public/ exists and is fresh
  rm -rf public
  mkdir -p public
  cp -r build/web/* public/
  
  echo "Final public/ directory ready for Vercel."
else
  echo "ERROR: build/web was not created."
  exit 1
fi
