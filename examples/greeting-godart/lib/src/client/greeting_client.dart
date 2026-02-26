import 'dart:io';

import 'package:grpc/grpc.dart';
import 'package:holons/holons.dart';

import '../../gen/greeting/v1/greeting.pbgrpc.dart';
import 'daemon_launcher.dart';

/// gRPC client for the GreetingService.
///
/// Supports both embedded mode (stdio://) and external mode (tcp://, unix://).
class GreetingClient {
  ClientChannel? _channel;
  GreetingServiceClient? _stub;
  final DaemonLauncher _launcher = DaemonLauncher();

  bool get isConnected => _stub != null;

  /// Embedded mode: spawn the bundled daemon via stdio.
  Future<void> connectEmbedded(String binaryPath) async {
    await close();
    final channel = await _launcher.start(binaryPath);
    _stub = GreetingServiceClient(channel);
  }

  /// External mode: connect to tcp:// or unix://.
  Future<void> connect(String address) async {
    await close();
    final parsed = parseUri(address);
    switch (parsed.scheme) {
      case 'unix':
        _channel = ClientChannel(
          InternetAddress(parsed.path!, type: InternetAddressType.unix),
          port: 0,
          options: const ChannelOptions(
            credentials: ChannelCredentials.insecure(),
          ),
        );
      case 'tcp':
        _channel = ClientChannel(
          parsed.host!,
          port: parsed.port!,
          options: const ChannelOptions(
            credentials: ChannelCredentials.insecure(),
          ),
        );
      default:
        throw ArgumentError('Unsupported scheme: ${parsed.scheme}');
    }
    _stub = GreetingServiceClient(_channel!);
  }

  /// Fetches all available greeting languages.
  Future<ListLanguagesResponse> listLanguages() async {
    return _stub!.listLanguages(ListLanguagesRequest());
  }

  /// Greets the user in the specified language.
  Future<SayHelloResponse> sayHello(String name, String langCode) async {
    return _stub!.sayHello(
      SayHelloRequest(name: name, langCode: langCode),
    );
  }

  /// Shuts down the gRPC channel and daemon process (if embedded).
  Future<void> close() async {
    final channel = _channel;
    _stub = null;
    _channel = null;
    if (channel != null) await channel.shutdown();
    await _launcher.stop();
  }
}
