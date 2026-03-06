#!/bin/bash
# Build the greeting daemon binary into the composite build/ directory.
# Output lands at ../../build/daemon (the greeting/ level), not inside
# greeting-godart/ — keeping the source tree clean.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DAEMON_SRC="$(cd "${SCRIPT_DIR}/../../greeting-daemon" && pwd)"
OUTPUT_DIR="${1:-${SCRIPT_DIR}/../../build}"

GO="$(command -v go)"
mkdir -p "$OUTPUT_DIR"

echo "Building greeting daemon for $(${GO} env GOOS)/$(${GO} env GOARCH)..."
"${GO}" build -C "$DAEMON_SRC" -o "$(cd "$OUTPUT_DIR" && pwd)/daemon" ./cmd/daemon

echo "Built: ${OUTPUT_DIR}/daemon"
