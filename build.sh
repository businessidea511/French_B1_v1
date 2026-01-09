#!/bin/bash

echo "Starting Flutter Web Build..."

# Simplified single-line command to avoid shell parsing issues with multi-line backslashes
./flutter/bin/flutter build web --release --web-renderer=html --dart-define=DEEPSEEK_API_KEY="$DEEPSEEK_API_KEY"

echo "Build finished. Checking output..."
if [ -d "build/web" ]; then
  echo "Success: Output found in build/web"
else
  echo "Error: build/web not found"
  exit 1
fi
