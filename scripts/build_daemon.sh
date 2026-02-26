#!/bin/bash
# Build a Go daemon binary for bundling in a Flutter desktop app.
#
# Usage:
#   ./scripts/build_daemon.sh <daemon_source_dir> [output_dir]
#
# The daemon source directory must contain a cmd/<name>/main.go.
# Builds for the current GOOS/GOARCH only.
# Output defaults to ./build/daemon.

set -euo pipefail

if [ $# -lt 1 ]; then
  echo "usage: build_daemon.sh <daemon_source_dir> [output_dir]" >&2
  exit 1
fi

DAEMON_SRC="$(cd "$1" && pwd)"
OUTPUT_DIR="${2:-./build}"
OUTPUT_PATH="${OUTPUT_DIR}/daemon"

# Resolve Go compiler.
if [ -n "${GO_BIN:-}" ]; then
  GO="${GO_BIN}"
elif [ -n "${GOROOT:-}" ] && [ -x "${GOROOT}/bin/go" ]; then
  GO="${GOROOT}/bin/go"
else
  GO="$(command -v go)"
fi

if [ -z "${GO}" ] || [ ! -x "${GO}" ]; then
  echo "error: go compiler not found" >&2
  exit 1
fi

GOOS="$("${GO}" env GOOS)"
GOARCH="$("${GO}" env GOARCH)"

mkdir -p "$OUTPUT_DIR"

echo "Building daemon for ${GOOS}/${GOARCH}..."
"${GO}" build -C "$DAEMON_SRC" -o "$(cd "$OUTPUT_DIR" && pwd)/daemon" ./cmd/...

echo "Built: $OUTPUT_PATH ($(du -h "$OUTPUT_PATH" | cut -f1))"
