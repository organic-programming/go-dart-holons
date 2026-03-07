# Gudule Greeting Godart

`Gudule Greeting Godart` is the flagship example in `go-dart-holons`:
a Flutter frontend paired with an embedded Go gRPC daemon.

It is the quickest way to see the Godart pattern working in practice:

- Go owns the service contract and business logic
- Flutter owns the user interface
- desktop startup goes through `dart-holons.connect("greeting-daemon-greeting-godart")`
- the daemon is bundled beside the app and launched as a child process

## What You Build

The source directories still use the historical names:

- `../greeting-daemon/`
- `greeting-godart/` (this directory)

But the desktop artifacts you care about are:

- app: `gudule-greeting-godart`
- daemon: `gudule-daemon-greeting-godart`

The daemon build lands in `../build/`.

## Quickstart

### macOS

```bash
flutter pub get
./scripts/build_daemon.sh
flutter run -d macos
```

### Linux

```bash
flutter pub get
./scripts/build_daemon.sh
flutter build linux --debug
cp ../build/gudule-daemon-greeting-godart \
  build/linux/x64/debug/bundle/gudule-daemon-greeting-godart
./build/linux/x64/debug/bundle/gudule-greeting-godart
```

### Windows

```powershell
flutter pub get
go build -C ..\greeting-daemon `
  -o ..\build\gudule-daemon-greeting-godart.exe `
  ./cmd/daemon
flutter build windows --debug
copy ..\build\gudule-daemon-greeting-godart.exe `
  build\windows\x64\runner\Debug\gudule-daemon-greeting-godart.exe
.\build\windows\x64\runner\Debug\gudule-greeting-godart.exe
```

## What to Expect at Runtime

- `Gudule Greeting Godart` starts the bundled daemon automatically.
- The app stages a temporary `holon.yaml`, resolves the daemon by slug,
  and lets `dart-holons.connect()` launch it on an ephemeral local TCP
  port.
- The UI lets you choose a language and request greetings from the Go
  backend.
- During development, the app uses the daemon binary built into
  `../build/` and runs the same slug-based connect flow.

## Why This Example Matters

`Gudule Greeting Godart` is not just a demo app. It is the reference
implementation for the whole repository:

- it proves the desktop bundling flow
- it shows the Go/Flutter split clearly
- it gives you a concrete file layout to copy
- it keeps the docs honest because the example must stay runnable

## Read Next

- [../../../BUILD.md](../../../BUILD.md) for the full platform matrix
- [../../../APPS.md](../../../APPS.md) for the architecture behind the pattern
