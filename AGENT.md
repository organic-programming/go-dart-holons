# Agent Instructions — go-dart-holons

Instructions for AI coding agents working on Godart apps.

## Proto Sharing: No Copy, No Symlink

In a Godart app, the **proto source of truth lives in the Go daemon**
holon. The Flutter (Godart) holon does **not** copy or symlink the proto
files. Instead, `protoc -I` resolves imports via relative paths at
generation time.

### Directory layout

```
holons/
├── my-daemon/
│   └── protos/
│       └── myservice/v1/service.proto    ← source of truth
└── my-godart/
    ├── protos/
    │   └── godart/v1/godart.proto        ← Godart-only services (optional)
    └── lib/gen/                          ← generated Dart stubs
```

The Godart holon's `protos/` directory may contain **Godart-specific**
proto files (services implemented in Dart only, not by the Go daemon).
These files can `import` from the daemon's protos:

```protobuf
// protos/godart/v1/godart.proto
syntax = "proto3";
package godart.v1;

import "myservice/v1/service.proto";  // resolved via -I
```

### Generating Dart stubs

Always use `-I` to point at the daemon's proto directory:

```bash
# From the Godart holon root
cd holons/my-godart

# Generate stubs for the daemon's service
protoc \
  -I../../my-daemon/protos \
  --dart_out=grpc:lib/gen/myservice/v1 \
  myservice/v1/service.proto

# Generate stubs for Godart-only services (if any)
protoc \
  -I../../my-daemon/protos \
  -Iprotos \
  --dart_out=grpc:lib/gen/godart/v1 \
  godart/v1/godart.proto
```

The `-I../../my-daemon/protos` flag tells `protoc` where to find the
daemon's `.proto` files when resolving `import` statements.

### Rules for agents

1. **Never copy or symlink proto files** between holons. Use `protoc -I`
   with a relative path to the daemon's `protos/` directory.
2. **The daemon owns the proto**. If you need to change the service
   contract, edit the proto in the daemon holon, then regenerate stubs
   on both sides.
3. **Godart-specific services** (Dart-only, not implemented by Go) go
   in the Godart holon's own `protos/` directory.
4. **Generated stubs** go in `lib/gen/` (Dart) or `gen/` (Go). These
   are checked into git.

## Connection Dispatch

A Godart app's `connectDaemon(address)` dispatches by URI scheme:

| Scheme | Behavior |
|--------|----------|
| `stdio://` | Spawn daemon binary as child process (desktop) |
| `unix://` | Connect to Unix domain socket (mobile, or external) |
| `tcp://` | Connect to TCP address (external/debug) |

On desktop, the default is `stdio://` with the bundled binary path.
On mobile, `unix://` with the sandbox socket path.

## Build Workflow

1. Build the Go daemon first (binary or shared library)
2. Build the Flutter app (Xcode/Gradle/CMake copies the artifact)
3. Always rebuild the daemon when the proto changes
