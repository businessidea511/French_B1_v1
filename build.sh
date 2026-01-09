#!/bin/bash

# Create a dummy .env if it doesn't exist to satisfy the asset requirement (though we removed it from pubspec, it's good practice)
mkdir -p assets/env
touch .env
touch assets/env/.env

echo "Building Flutter Web with DEEPSEEK_API_KEY injection..."

# Run the build with dart-define
# We use quotes around the variable to handle any special characters
flutter/bin/flutter build web --release \
  --dart-define=DEEPSEEK_API_KEY="$DEEPSEEK_API_KEY" \
  --web-renderer html

echo "Build complete."
