#!/bin/bash
# Build a Go daemon as a C shared library for mobile (iOS/Android).
#
# Usage:
#   ./scripts/build_mobile.sh <daemon_source_dir> <platform> [output_dir]
#
# Platforms: ios, android
# Output defaults to ./build/<platform>/libdaemon.<ext>
#
# Prerequisites:
#   - Go 1.21+ with CGo support
#   - iOS: Xcode command-line tools
#   - Android: NDK installed, ANDROID_NDK_HOME set

set -euo pipefail

if [ $# -lt 2 ]; then
  echo "usage: build_mobile.sh <daemon_source_dir> <platform> [output_dir]" >&2
  echo "  platforms: ios, android" >&2
  exit 1
fi

DAEMON_SRC="$(cd "$1" && pwd)"
PLATFORM="$2"
OUTPUT_DIR="${3:-./build/${PLATFORM}}"

# Resolve Go compiler.
GO="${GO_BIN:-$(command -v go)}"
if [ -z "${GO}" ] || [ ! -x "${GO}" ]; then
  echo "error: go compiler not found" >&2
  exit 1
fi

mkdir -p "$OUTPUT_DIR"
ABS_OUTPUT="$(cd "$OUTPUT_DIR" && pwd)"

case "$PLATFORM" in
  ios)
    GOOS=ios
    GOARCH=arm64
    OUTPUT_FILE="${ABS_OUTPUT}/libdaemon.dylib"
    ;;
  android)
    GOOS=android
    GOARCH=arm64
    OUTPUT_FILE="${ABS_OUTPUT}/libdaemon.so"
    if [ -z "${ANDROID_NDK_HOME:-}" ]; then
      echo "error: ANDROID_NDK_HOME is not set" >&2
      exit 1
    fi
    ;;
  *)
    echo "error: unsupported platform '$PLATFORM' (use ios or android)" >&2
    exit 1
    ;;
esac

echo "Building daemon shared library for ${GOOS}/${GOARCH}..."
CGO_ENABLED=1 GOOS="${GOOS}" GOARCH="${GOARCH}" \
  "${GO}" build -C "$DAEMON_SRC" \
    -buildmode=c-shared \
    -o "$OUTPUT_FILE" \
    ./cmd/...

echo "Built: $OUTPUT_FILE ($(du -h "$OUTPUT_FILE" | cut -f1))"
