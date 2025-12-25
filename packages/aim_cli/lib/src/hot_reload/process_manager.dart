import 'dart:io';

/// Class responsible for managing server processes
class ProcessManager {
  final String _entryPoint;
  final Map<String, String> _environment;

  Process? _currentProcess;
  bool _isShuttingDown = false;

  ProcessManager({
    required String entryPoint,
    required Map<String, String> environment,
  }) : _entryPoint = entryPoint,
       _environment = environment;

  /// Start process
  Future<void> start() async {
    if (_currentProcess != null) {
      throw StateError('Process is already running');
    }

    try {
      _currentProcess = await Process.start(
        'dart',
        ['run', _entryPoint],
        mode: ProcessStartMode.inheritStdio,
        environment: _environment,
      );
    } catch (e) {
      print('❌ Error: Failed to start server');
      print('   $e');
      rethrow;
    }
  }

  /// Stop process (graceful shutdown)
  Future<void> stop({Duration timeout = const Duration(seconds: 5)}) async {
    if (_currentProcess == null || _isShuttingDown) {
      return;
    }

    _isShuttingDown = true;

    try {
      // Attempt graceful shutdown
      final success = await _gracefulShutdown(timeout);

      if (!success) {
        print('⚠️  Warning: Graceful shutdown failed (forcing kill)');
        await _forceKill();
      }
    } finally {
      _currentProcess = null;
      _isShuttingDown = false;
    }
  }

  /// Restart process
  Future<void> restart() async {
    await stop();
    await start();
  }

  /// Check if process is running
  bool get isRunning => _currentProcess != null && !_isShuttingDown;

  /// Attempt graceful shutdown (SIGTERM)
  Future<bool> _gracefulShutdown(Duration timeout) async {
    _currentProcess!.kill(ProcessSignal.sigterm);

    final exitCode = await _currentProcess!.exitCode.timeout(
      timeout,
      onTimeout: () => -1,
    );

    return exitCode != -1;
  }

  /// Force kill (SIGKILL)
  Future<void> _forceKill() async {
    _currentProcess!.kill(ProcessSignal.sigkill);
    await _currentProcess!.exitCode;
  }
}
