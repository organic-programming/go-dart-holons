# Build Gudule Greeting Godart, Then Reuse the Pattern

This document does two jobs:

1. Get the `Gudule Greeting Godart` reference app running.
2. Show the exact build pattern you can copy into your own composite app.

All commands below use the reference implementation in
`examples/greeting/`.

## Naming Note

The source directories keep the historical names:

- `examples/greeting/greeting-daemon/`
- `examples/greeting/greeting-godart/`

But the desktop artifacts you build and ship are:

- app: `gudule-greeting-godart`
- daemon: `gudule-daemon-greeting-godart`

All example build artifacts live in `examples/greeting/build/`, never
inside the source directories.

## Recommended First Run: macOS

If you just want to see the pattern working, start here.

```bash
cd examples/greeting/greeting-godart
flutter pub get
./scripts/build_daemon.sh
flutter run -d macos
```

What you should get:

- Flutter launches `Gudule Greeting Godart`.
- The app bundles and spawns `gudule-daemon-greeting-godart`.
- The UI shows the greeting form and language picker.
- gRPC traffic flows over `stdio://`.

## macOS

### Prerequisites

- Go 1.21+
- Flutter 3.19+
- Xcode 15+ with command-line tools

### Build and run

```bash
cd examples/greeting/greeting-godart
flutter pub get
./scripts/build_daemon.sh
flutter build macos --debug
flutter run -d macos
```

### How it works

- `./scripts/build_daemon.sh` compiles the Go daemon into
  `examples/greeting/build/gudule-daemon-greeting-godart`
- Xcode copies that binary into the app bundle as
  `Contents/Resources/gudule-daemon-greeting-godart`
- At runtime, `Gudule Greeting Godart` spawns the daemon with `serve --listen stdio://`
- gRPC flows over stdin/stdout pipes
- On quit, the daemon receives SIGTERM and shuts down cleanly

## Linux

### Prerequisites

- Go 1.21+
- Flutter 3.19+
- GTK 3: `sudo apt install libgtk-3-dev`
- `clang`, `cmake`, `ninja-build`, `pkg-config`

### Build and run

```bash
cd examples/greeting/greeting-godart
flutter pub get
./scripts/build_daemon.sh
flutter build linux --debug
cp ../build/gudule-daemon-greeting-godart \
  build/linux/x64/debug/bundle/gudule-daemon-greeting-godart
./build/linux/x64/debug/bundle/gudule-greeting-godart
```

### Cross-build the daemon from macOS

```bash
cd examples/greeting/greeting-daemon
GOOS=linux GOARCH=amd64 \
  go build -o ../build/gudule-daemon-greeting-godart ./cmd/daemon
```

### Docker CI note

Use `Gudule Greeting Godart` as the concrete desktop target, then reproduce the
same copy-step in CI:

```bash
docker build -t godart-linux-test \
  -f examples/greeting/greeting-godart/docker/Dockerfile.linux-test .
docker run --rm -v "$(pwd):/workspace" godart-linux-test bash -c '...'
```

## Windows

### Prerequisites

- Go 1.21+
- Flutter 3.19+
- Visual Studio 2022 with the "Desktop development with C++" workload
- Git for Windows

### Build and run

```powershell
cd examples\greeting\greeting-godart
flutter pub get
go build -C ..\greeting-daemon `
  -o ..\build\gudule-daemon-greeting-godart.exe `
  ./cmd/daemon
flutter build windows --debug
copy ..\build\gudule-daemon-greeting-godart.exe `
  build\windows\x64\runner\Debug\gudule-daemon-greeting-godart.exe
.\build\windows\x64\runner\Debug\gudule-greeting-godart.exe
```

### Cross-build the daemon from macOS or Linux

```bash
cd examples/greeting/greeting-daemon
GOOS=windows GOARCH=amd64 \
  go build -o ../build/gudule-daemon-greeting-godart.exe ./cmd/daemon
```

### Shutdown behavior

On Windows, `process.kill(SIGTERM)` maps to the graceful shutdown path,
so `Gudule Greeting Godart` uses the same "terminate, drain, then force if needed"
behavior as on Unix desktops.

## iOS

### Prerequisites

- Go 1.21+ with CGo cross-compilation support
- Flutter 3.19+
- Xcode 15+
- A physical device or simulator

### Build the shared library

```bash
cd examples/greeting/greeting-daemon
CGO_ENABLED=1 GOOS=ios GOARCH=arm64 \
  go build -buildmode=c-shared \
  -o ../build/ios/libdaemon.dylib ./cmd/daemon
```

### Integration pattern

1. Add the `.dylib` to the Xcode project.
2. Start the daemon in-process via FFI.
3. Connect the Flutter client through a sandboxed `unix://` socket.

```dart
final socketPath = '${appSandboxDir}/gudule-daemon-greeting-godart.sock';
daemonFFI.start(socketPath);
await client.connect('unix://$socketPath');
```

### Run

```bash
flutter build ios
flutter run -d <device-id>
```

Note: `Process.start()` is forbidden on iOS. The daemon runs in-process
as a shared library.

## Android

### Prerequisites

- Go 1.21+ with CGo cross-compilation support
- Flutter 3.19+
- Android SDK + NDK
- A physical device or emulator

### Build the shared library

```bash
cd examples/greeting/greeting-daemon
CGO_ENABLED=1 GOOS=android GOARCH=arm64 \
  go build -buildmode=c-shared \
  -o ../build/android/libdaemon.so ./cmd/daemon
```

### Integration pattern

1. Place the `.so` in `android/app/src/main/jniLibs/arm64-v8a/`.
2. Start the daemon via FFI.
3. Connect through a sandboxed `unix://` socket.

### Run

```bash
flutter build apk
flutter run -d <device-id>
```

Note: same constraint as iOS. Android uses in-process FFI, not
`Process.start()`.

## Build Matrix

| Target | Go daemon | Flutter app | Status |
|--------|-----------|-------------|--------|
| macOS | native binary | native Flutter desktop | Best first run |
| Linux | native or cross-built binary | Flutter desktop | Requires GTK toolchain |
| Windows | native or cross-built `.exe` | Flutter desktop | Requires Visual Studio |
| iOS | c-shared library | Flutter mobile | Pattern documented here |
| Android | c-shared library | Flutter mobile | Pattern documented here |

## Desktop Runtime Mode

`Gudule Greeting Godart` now resolves the bundled daemon as the
`greeting-daemon-greeting-godart` holon and launches it through
`dart-holons.connect()`. The SDK starts the daemon on an ephemeral
localhost TCP port, waits for readiness, and tears it down when the app
disconnects.

For low-level daemon debugging, you can still run the binary yourself:

```bash
cd examples/greeting/greeting-daemon
go run ./cmd/daemon serve --listen tcp://127.0.0.1:0
```

## Reusing the Pattern in Your Own App

Once `Gudule Greeting Godart` makes sense, the reusable pattern is straightforward:

1. Put the protobuf source of truth in the Go daemon holon.
2. Generate Dart stubs from that proto with `protoc -I`.
3. Build the Go daemon first.
4. Copy or bundle the daemon beside the Flutter app for desktop.
5. Stage a local `holon.yaml` that points at that binary and call
   `dart-holons.connect(slug)`.
6. Default to `unix://` on mobile when you switch to the FFI pattern.

For the full architectural explanation behind those five steps, read
[APPS.md](APPS.md).
