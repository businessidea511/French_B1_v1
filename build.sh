#!/bin/bash

# Exit on error
set -e

echo "=== PREPARING CONFIGURATION ==="
# Create a JSON file for dart-define to avoid shell escaping issues with special characters in the API key
echo "{\"DEEPSEEK_API_KEY\": \"$DEEPSEEK_API_KEY\"}" > dart_config.json

# Create a dummy .env file if it doesn't exist (Flutter build requires it since it's in pubspec.yaml)
if [ ! -f ".env" ]; then
  echo "Creating dummy .env for build compatibility..."
  touch .env
fi

echo "=== STARTING FLUTTER BUILD ==="
# Using --dart-define-from-file is much more stable than passing it via command line
./flutter/bin/flutter build web --release --dart-define-from-file=dart_config.json --no-wasm-dry-run

echo "=== PREPARING FOR VERCEL SERVICE ==="
rm -rf public
mkdir -p public
if [ -d "build/web" ]; then
  cp -r build/web/* public/
  echo "Success: Project copied to public/"
else
  echo "ERROR: build/web not found"
  exit 1
fi

# Clean up the temporary config file
rm dart_config.json

echo "Build and preparation complete."
