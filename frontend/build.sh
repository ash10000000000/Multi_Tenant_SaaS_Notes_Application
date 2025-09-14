#!/bin/bash

# Build script for Kotlin/JS frontend
echo "Building Kotlin/JS frontend..."

# Install dependencies
./gradlew build

# Copy built files to distribution directory
mkdir -p build/distributions
cp -r build/dist/js/packages/frontend/kotlin-dce/* build/distributions/

echo "Frontend build completed!"
