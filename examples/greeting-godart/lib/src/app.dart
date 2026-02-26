import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'client/greeting_client.dart';
import 'screens/greeting_screen.dart';

class GreetingApp extends StatefulWidget {
  const GreetingApp({super.key});

  @override
  State<GreetingApp> createState() => _GreetingAppState();
}

class _GreetingAppState extends State<GreetingApp> {
  final GreetingClient _client = GreetingClient();
  bool _connecting = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  String _resolveDaemonPath() {
    final exe = Platform.resolvedExecutable;
    if (Platform.isMacOS) {
      // macOS: daemon is in Contents/Resources/
      return exe.replaceFirst(RegExp(r'/[^/]+$'), '/../Resources/daemon');
    }
    // Linux/Windows: daemon sits next to the executable
    final dir = File(exe).parent.path;
    final name = Platform.isWindows ? 'daemon.exe' : 'daemon';
    return '$dir/$name';
  }

  Future<void> _connect() async {
    try {
      final daemonPath = _resolveDaemonPath();

      if (File(daemonPath).existsSync()) {
        await _client.connectEmbedded(daemonPath);
      } else {
        // Fallback: external daemon for development.
        await _client.connect('tcp://localhost:9091');
      }
      setState(() => _connecting = false);
    } catch (e) {
      setState(() {
        _connecting = false;
        _error = e.toString();
      });
    }
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Godart Greeting',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      ),
      home: _buildHome(),
    );
  }

  Widget _buildHome() {
    if (_connecting) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F1A),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F1A),
        body: Center(
          child: Text(
            'Connection error:\n$_error',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      );
    }
    return GreetingScreen(client: _client);
  }
}
