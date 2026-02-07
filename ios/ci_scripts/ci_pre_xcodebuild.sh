#!/bin/sh

# Xcode Cloud ci_pre_xcodebuild.sh
# This script runs before xcodebuild

set -e

echo "=== ci_pre_xcodebuild.sh started ==="

# Set Flutter path
export PATH="$PATH:$HOME/flutter/bin"

# Verify Flutter is available
flutter --version

echo "=== ci_pre_xcodebuild.sh completed ==="
