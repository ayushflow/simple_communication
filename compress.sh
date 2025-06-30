#!/bin/bash

# Navigate to the build directory
cd example/build/web

# Find and compress all eligible files
find . -type f \( \
    -name "*.js" -o \
    -name "*.css" -o \
    -name "*.html" -o \
    -name "*.json" -o \
    -name "*.ttf" -o \
    -name "*.otf" -o \
    -name "*.woff" -o \
    -name "*.woff2" -o \
    -name "*.svg" -o \
    -name "*.xml" \
\) -exec gzip -9 -k {} \; -exec echo "Compressed: {}" \;

echo "Gzip compression complete!"