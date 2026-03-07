import 'dart:io';

import 'package:grpc/grpc.dart';
import 'package:holons/holons.dart' as holons;

/// Stages the bundled daemon as a discoverable holon and connects to it.
class DaemonLauncher {
  static const String _slug = 'greeting-daemon-greeting-godart';
  static const String _uuid = '1a409a1e-69e3-4846-9f9b-47b0a6f98f84';
  static const String _familyName = 'Greeting-Godart';

  Directory? _root;

  Future<ClientChannel> start(String binaryPath) async {
    await stop();
    final file = File(binaryPath);
    if (!file.existsSync()) {
      throw StateError('Daemon binary not found: $binaryPath');
    }

    final root =
        await Directory.systemTemp.createTemp('greeting-godart-holon-');
    _root = root;
    final holonDir = Directory(
      '${root.path}${Platform.pathSeparator}holons${Platform.pathSeparator}$_slug',
    );
    await holonDir.create(recursive: true);
    await File(
      '${holonDir.path}${Platform.pathSeparator}holon.yaml',
    ).writeAsString(_manifestFor(file.absolute.path));

    final previousDirectory = Directory.current.path;
    try {
      Directory.current = root.path;
      return await holons.connect(_slug);
    } catch (_) {
      await _deleteRoot(root);
      _root = null;
      rethrow;
    } finally {
      Directory.current = previousDirectory;
    }
  }

  Future<void> stop([ClientChannel? channel]) async {
    final root = _root;
    _root = null;

    try {
      if (channel != null) {
        await holons.disconnect(channel);
      }
    } finally {
      if (root != null) {
        await _deleteRoot(root);
      }
    }
  }

  String _manifestFor(String binaryPath) {
    final escapedBinaryPath = _escapeYaml(binaryPath);
    return '''
schema: holon/v0
uuid: "$_uuid"
given_name: greeting-daemon
family_name: "$_familyName"
motto: Greets users in 56 languages — a Godart recipe example.
composer: B. ALTER
clade: deterministic/pure
status: draft
born: "2026-02-20"
generated_by: manual
kind: native
build:
  runner: go-module
artifacts:
  binary: "$escapedBinaryPath"
''';
  }

  String _escapeYaml(String value) {
    return value.replaceAll('\\', '\\\\').replaceAll('"', '\\"');
  }

  Future<void> _deleteRoot(Directory root) async {
    if (!root.existsSync()) {
      return;
    }
    await root.delete(recursive: true);
  }
}
