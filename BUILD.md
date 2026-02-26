# Build & Run

Step-by-step instructions to build and run a Godart app on every
supported platform. All commands below use the **greeting example**
(`greeting-daemon` + `greeting-godart`) that ships with this SDK. The
same workflow applies to any Godart app — just replace the paths and
names with your own holons.

---

## macOS

### Prerequisites

- Go 1.21+
- Flutter 3.19+
- Xcode 15+ with command-line tools

### Build & Run

```bash
cd examples/greeting-godart
./scripts/build_daemon.sh          # Go → build/daemon
flutter build macos --debug        # Xcode copies daemon into .app
flutter run -d macos
```

### How it works

- `scripts/build_daemon.sh` compiles the Go daemon into `build/daemon`
- An Xcode "Run Script" build phase copies it into
  `Contents/Resources/daemon` inside the `.app` bundle
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
cd examples/greeting-daemon
go build -o ../greeting-godart/build/daemon ./cmd/daemon

cd ../greeting-godart
flutter build linux --debug
cp build/daemon build/linux/x64/debug/bundle/daemon
./build/linux/x64/debug/bundle/greeting_godart
```

### Cross-compile from macOS

```bash
GOOS=linux GOARCH=amd64 go build -o build/daemon ./cmd/daemon
```

### Docker (headless CI)

```bash
docker build -t godart-linux-test \
  -f examples/greeting-godart/docker/Dockerfile.linux-test .
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
cd examples\greeting-daemon
go build -o ..\greeting-godart\build\daemon.exe .\cmd\daemon

cd ..\greeting-godart
flutter build windows --debug
copy build\daemon.exe build\windows\x64\runner\Debug\daemon.exe
.\build\windows\x64\runner\Debug\greeting_godart.exe
```

### Cross-compile from macOS/Linux

```bash
GOOS=windows GOARCH=amd64 go build -o daemon.exe ./cmd/daemon
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
CGO_ENABLED=1 GOOS=ios GOARCH=arm64 \
  go build -buildmode=c-shared \
  -o build/libdaemon.dylib ./cmd/daemon
```

### Integration

1. Add the `.dylib` as a framework in the Xcode project
2. The Dart FFI bridge loads the library and calls `StartDaemon()`
   with a `unix://` URI inside the app sandbox
3. The gRPC client connects via `unix://` — same `ServiceClient.connect()`
   code as desktop

```dart
final socketPath = '${appSandboxDir}/daemon.sock';
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
CGO_ENABLED=1 GOOS=android GOARCH=arm64 \
  go build -buildmode=c-shared \
  -o build/libdaemon.so ./cmd/daemon
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
cd examples/greeting-daemon
go run ./cmd/daemon serve --listen tcp://:9091
```

Then point the Flutter app at `tcp://localhost:9091` — no embedded
daemon needed. Useful for debugging, profiling, or running with `dlv`.
