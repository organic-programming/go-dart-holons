#!/bin/bash
# Generate gRPC stubs for both Go and Dart from a shared .proto file.
#
# Usage:
#   ./templates/proto_gen.sh <proto_dir> <proto_file> <go_out> <dart_out>
#
# Example:
#   ./templates/proto_gen.sh protos myservice/v1/service.proto gen/go lib/gen

set -euo pipefail

if [ $# -lt 4 ]; then
  echo "usage: proto_gen.sh <proto_dir> <proto_file> <go_out> <dart_out>" >&2
  exit 1
fi

PROTO_DIR="$1"
PROTO_FILE="$2"
GO_OUT="$3"
DART_OUT="$4"

echo "Generating Go stubs..."
protoc \
  --proto_path="$PROTO_DIR" \
  --go_out="$GO_OUT" --go_opt=paths=source_relative \
  --go-grpc_out="$GO_OUT" --go-grpc_opt=paths=source_relative \
  "$PROTO_FILE"

echo "Generating Dart stubs..."
protoc \
  --proto_path="$PROTO_DIR" \
  --dart_out=grpc:"$DART_OUT" \
  "$PROTO_FILE"

echo "Done."
