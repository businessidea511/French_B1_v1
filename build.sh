#!/bin/bash

echo "=== STARTING FLUTTER BUILD ==="
# Standard build command
./flutter/bin/flutter build web --release --dart-define=DEEPSEEK_API_KEY="$DEEPSEEK_API_KEY"

echo "=== PREPARING FOR VERCEL SERVICE ==="
# Move to 'public' folder which Vercel handles very reliably
rm -rf public
mkdir -p public
cp -r build/web/* public/

echo "=== VERIFYING OUTPUT FILES ==="
ls -la public/
if [ -f "public/main.dart.js" ]; then
  echo "Success: main.dart.js is present in public/"
else
  echo "Error: main.dart.js NOT FOUND"
  exit 1
fi

echo "Build and preparation complete."
