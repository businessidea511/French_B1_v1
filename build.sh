#!/bin/bash

echo "=== ENVIRONMENT CHECK ==="
pwd
ls -la
if [ -z "$DEEPSEEK_API_KEY" ]; then
  echo "WARNING: DEEPSEEK_API_KEY is empty"
else
  echo "DEEPSEEK_API_KEY is present (length: ${#DEEPSEEK_API_KEY})"
fi

echo "=== STARTING FLUTTER BUILD ==="
# Using verbose mode to see the actual compile error
./flutter/bin/flutter build web --release \
  -v \
  --dart-define=DEEPSEEK_API_KEY=$DEEPSEEK_API_KEY \
  --web-renderer html

echo "=== BUILD FINISHED ==="
if [ -d "build/web" ]; then
  echo "Success: build/web directory found"
  ls -la build/web
else
  echo "ERROR: build/web directory NOT found"
  exit 1
fi
