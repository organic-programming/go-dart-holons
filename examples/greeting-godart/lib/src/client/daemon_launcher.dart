import 'dart:io';

import 'package:grpc/grpc.dart';
import 'package:holons/holons.dart';

/// Manages the embedded Go daemon process lifecycle.
class DaemonLauncher {
  ClientTransportConnectorChannel? _channel;
  Process? _process;

  bool get isRunning => _process != null;

  /// Spawns the daemon binary and returns a gRPC channel over stdio.
  Future<ClientTransportConnectorChannel> start(String binaryPath) async {
    await stop();

    final file = File(binaryPath);
    if (!file.existsSync()) {
      throw StateError('Daemon binary not found: $binaryPath');
    }

    final (channel, process) = await dialStdio(binaryPath);
    _channel = channel;
    _process = process;

    // Forward daemon stderr to debug console.
    process.stderr
        .transform(const SystemEncoding().decoder)
        .listen((line) => stderr.write('[daemon] $line'));

    return channel;
  }

  /// Gracefully stops the daemon: SIGTERM, then SIGKILL after 5s.
  Future<void> stop() async {
    final channel = _channel;
    final process = _process;
    _channel = null;
    _process = null;

    if (channel != null) await channel.shutdown();
    if (process != null) {
      process.kill(ProcessSignal.sigterm);
      await process.exitCode.timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          process.kill(ProcessSignal.sigkill);
          return -1;
        },
      );
    }
  }
}
