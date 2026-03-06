# Build & Run

Step-by-step instructions to build and run a Godart app on every
supported platform. All commands below use the **greeting example**
(`greeting-daemon` + `greeting-godart`) that ships with this SDK. The
same workflow applies to any Godart app — just replace the paths and
names with your own holons.

All build artifacts are placed in `examples/greeting/build/` — never
inside the source directories.

---

## macOS

### Prerequisites

- Go 1.21+
- Flutter 3.19+
- Xcode 15+ with command-line tools

### Build & Run

```bash
cd examples/greeting
./greeting-godart/scripts/build_daemon.sh   # Go → build/gudule-daemon-greeting-godart
cd greeting-godart
flutter build macos --debug                 # Xcode copies daemon into .app
flutter run -d macos
```

### How it works

- `build_daemon.sh` compiles the Go daemon into `greeting/build/gudule-daemon-greeting-godart`
- An Xcode "Run Script" build phase copies it into
  `Contents/Resources/gudule-daemon-greeting-godart` inside the `.app` bundle
- At runtime, the app spawns the daemon with `--listen stdio://`
- gRPC flows over stdin/stdout pipes (HTTP/2)
- On ⌘Q, the daemon receives SIGTERM → `GracefulStop()`

---

## Linux

### Prerequisites

- Go 1.21+
- Flutter 3.19+
- GTK 3: `sudo apt install libgtk-3-dev`
- `clang`, `cmake`, `ninja-build`, `pkg-config`

### Build & Run

```bash
cd examples/greeting
../../scripts/build_daemon.sh greeting-daemon build
cd greeting-godart
flutter build linux --debug
cp ../build/gudule-daemon-greeting-godart build/linux/x64/debug/bundle/gudule-daemon-greeting-godart
./build/linux/x64/debug/bundle/gudule-greeting-godart
```

### Cross-compile from macOS

```bash
cd examples/greeting/greeting-daemon
GOOS=linux GOARCH=amd64 go build -o ../../build/gudule-daemon-greeting-godart ./cmd/gudule-daemon-greeting-godart
```

### Docker (headless CI)

```bash
docker build -t godart-linux-test \
  -f examples/greeting/greeting-godart/docker/Dockerfile.linux-test .
docker run --rm -v "$(pwd):/workspace" godart-linux-test bash -c '...'
```

---

## Windows

### Prerequisites

- Go 1.21+
- Flutter 3.19+
- Visual Studio 2022 with "Desktop development with C++" workload
- Git for Windows

### Build & Run

```powershell
cd examples\greeting
..\..\scripts\build_daemon.sh greeting-daemon build
cd greeting-godart
flutter build windows --debug
copy ..\build\gudule-daemon-greeting-godart.exe build\windows\x64\runner\Debug\gudule-daemon-greeting-godart.exe
.\build\windows\x64\runner\Debug\gudule-greeting-godart.exe
```

### Cross-compile from macOS/Linux

```bash
cd examples/greeting/greeting-daemon
GOOS=windows GOARCH=amd64 go build -o ../../build/gudule-daemon-greeting-godart.exe ./cmd/gudule-daemon-greeting-godart
```

### Shutdown behavior

On Windows, `process.kill(SIGTERM)` sends `CTRL_BREAK_EVENT`. Go's
`signal.Notify(SIGTERM)` receives it and triggers the same
`GracefulStop()` path as on Unix — shutdown is graceful on all
desktop platforms.

---

## iOS

### Prerequisites

- Go 1.21+ (with CGo cross-compilation support)
- Flutter 3.19+
- Xcode 15+
- A physical device or simulator

### Build the shared library

```bash
cd examples/greeting/greeting-daemon
CGO_ENABLED=1 GOOS=ios GOARCH=arm64 \
  go build -buildmode=c-shared \
  -o ../../build/ios/libdaemon.dylib ./cmd/gudule-daemon-greeting-godart
```

### Integration

1. Add the `.dylib` as a framework in the Xcode project
2. The Dart FFI bridge loads the library and calls `StartDaemon()`
   with a `unix://` URI inside the app sandbox
3. The gRPC client connects via `unix://` — same `ServiceClient.connect()`
   code as desktop

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

> **Note**: `Process.start()` is forbidden on iOS. The daemon runs
> in-process as a C shared library via `dart:ffi`.

---

## Android

### Prerequisites

- Go 1.21+ (with CGo cross-compilation support)
- Flutter 3.19+
- Android SDK + NDK
- A physical device or emulator

### Build the shared library

```bash
cd examples/greeting/greeting-daemon
CGO_ENABLED=1 GOOS=android GOARCH=arm64 \
  go build -buildmode=c-shared \
  -o ../../build/android/libdaemon.so ./cmd/gudule-daemon-greeting-godart
```

### Integration

1. Place the `.so` in `android/app/src/main/jniLibs/arm64-v8a/`
2. The Dart FFI bridge loads `libdaemon.so` and calls `StartDaemon()`
   with a `unix://` URI inside the app sandbox
3. Same gRPC client code as all other platforms

### Run

```bash
flutter build apk
flutter run -d <device-id>
```

> **Note**: same as iOS — `Process.start()` is forbidden. The daemon
> runs in-process via `dart:ffi`.

---

## Build Matrix (from macOS)

| Target  | Go daemon | Flutter app | Notes |
|---------|-----------|-------------|-------|
| macOS   | ✅ native  | ✅ native    | Full pipeline |
| iOS     | ✅ c-shared | ✅ Xcode    | Full pipeline |
| Android | ✅ c-shared | ✅ Android SDK | Full pipeline |
| Linux   | ✅ cross   | ⚠️ Docker   | `flutter build linux` needs GTK3 |
| Windows | ✅ cross   | ❌           | Requires Visual Studio on Windows |

---

## External Daemon (all platforms)

For development, run the daemon in a separate terminal:

```bash
cd examples/greeting/greeting-daemon
go run ./cmd/daemon serve --listen tcp://:9091
```

Then point the Flutter app at `tcp://localhost:9091` — no embedded
daemon needed. Useful for debugging, profiling, or running with `dlv`.
