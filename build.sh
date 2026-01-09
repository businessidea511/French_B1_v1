#!/bin/bash

echo "=== FLUTTER VERSION INFO ==="
./flutter/bin/flutter --version
./flutter/bin/flutter config

echo "=== STARTING FLUTTER BUILD ==="
# Removing --web-renderer as it was causing "option not found" errors on Vercel
# Removed -v to keep logs cleaner unless really needed
./flutter/bin/flutter build web --release --dart-define=DEEPSEEK_API_KEY="$DEEPSEEK_API_KEY"

echo "=== BUILD FINISHED ==="
if [ -d "build/web" ]; then
  echo "Success: build/web directory found"
else
  echo "ERROR: build/web directory NOT found"
  exit 1
fi
