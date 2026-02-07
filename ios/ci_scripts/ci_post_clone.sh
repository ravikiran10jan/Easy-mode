#!/bin/sh

# Xcode Cloud ci_post_clone.sh for Flutter iOS app
# This script runs after Xcode Cloud clones the repository

set -e

echo "=== ci_post_clone.sh started ==="

# Navigate to project root
cd "$CI_PRIMARY_REPOSITORY_PATH"

# Install Flutter
echo "Installing Flutter..."
git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$HOME/flutter"
export PATH="$PATH:$HOME/flutter/bin"

# Verify Flutter installation
flutter --version

# Pre-cache iOS artifacts
flutter precache --ios

# Get Flutter dependencies
echo "Getting Flutter dependencies..."
flutter pub get

# Generate code if needed (riverpod_generator, etc.)
echo "Running build_runner..."
flutter pub run build_runner build --delete-conflicting-outputs || true

# Build Flutter iOS (no codesign - Xcode Cloud handles signing)
echo "Building Flutter iOS..."
flutter build ios --release --no-codesign

# Install CocoaPods dependencies
echo "Installing CocoaPods dependencies..."
cd ios
pod install --repo-update

echo "=== ci_post_clone.sh completed ==="
