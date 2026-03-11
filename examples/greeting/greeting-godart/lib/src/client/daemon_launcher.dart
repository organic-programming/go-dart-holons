import 'dart:async';
import 'dart:io';

import 'package:grpc/grpc.dart';
import 'package:grpc/src/client/connection.dart' show ClientConnection;
import 'package:grpc/src/client/http2_connection.dart'
    show Http2ClientConnection;
import 'package:holons/holons.dart' as holons;

const ChannelOptions _stdioChannelOptions = ChannelOptions(
  credentials: ChannelCredentials.insecure(),
  idleTimeout: null,
);

class _StdioClientChannel extends ClientChannel {
  final holons.StdioTransportConnector _connector;

  _StdioClientChannel(this._connector)
      : super('localhost', port: 0, options: _stdioChannelOptions);

  @override
  ClientConnection createConnection() =>
      Http2ClientConnection.fromClientTransportConnector(_connector, options);
}

/// Launches the bundled daemon over stdio without relying on holon discovery.
class DaemonLauncher {
  Process? _process;

  Future<ClientChannel> start(String binaryPath) async {
    await stop();
    final file = File(binaryPath);
    if (!file.existsSync()) {
      throw StateError('Daemon binary not found: $binaryPath');
    }

    final connector = await holons.StdioTransportConnector.spawn(
      file.absolute.path,
    );
    unawaited(connector.process.stderr.drain<void>());
    _process = connector.process;
    return _StdioClientChannel(connector);
  }

  Future<void> stop([ClientChannel? channel]) async {
    final process = _process;
    _process = null;

    try {
      if (channel != null) {
        await channel.shutdown();
      }
    } finally {
      if (process != null) {
        await _stopProcess(process);
      }
    }
  }

  Future<void> _stopProcess(Process process) async {
    process.kill(ProcessSignal.sigterm);
    await process.exitCode.timeout(
      const Duration(seconds: 2),
      onTimeout: () {
        process.kill(ProcessSignal.sigkill);
        return process.exitCode;
      },
    );
  }
}
