#!/bin/bash

# Exit on error
set -e

echo "Starting Flutter Web Build..."

# Ensure we have the environment variable
if [ -z "$DEEPSEEK_API_KEY" ]; then
  echo "Warning: DEEPSEEK_API_KEY is not set. AI features may not work."
fi

# We build to build/web (standard Flutter output)
# We use --dart-define=KEY=VALUE without extra quotes for maximum compatibility
./flutter/bin/flutter build web --release --dart-define=DEEPSEEK_API_KEY=$DEEPSEEK_API_KEY

echo "Build complete. Output is in build/web"
ls -la build/web
