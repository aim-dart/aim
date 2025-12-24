import 'process_manager.dart';
import 'file_watcher.dart';

/// Integration class for hot reload functionality
class HotReloader {
  final String _entryPoint;
  final Map<String, String> _environment;
  final List<String> _watchPaths;

  late final ProcessManager _processManager;
  late final FileWatcher _fileWatcher;

  bool _isReloading = false;

  HotReloader({
    required String entryPoint,
    required Map<String, String> environment,
    List<String>? watchPaths,
  })  : _entryPoint = entryPoint,
        _environment = environment,
        _watchPaths = watchPaths ?? ['lib', 'bin'];

  /// Start hot reload
  Future<void> start() async {
    _processManager = ProcessManager(
      entryPoint: _entryPoint,
      environment: _environment,
    );

    _fileWatcher = FileWatcher(
      watchPaths: _watchPaths,
      onChanged: _onFileChanged,
    );

    // Start process
    await _processManager.start();

    // Start file watching
    await _fileWatcher.start();

    // Wait until process terminates
    // (Exits with Ctrl+C or error)
    await Future<void>.delayed(const Duration(days: 365));
  }

  /// Stop hot reload
  Future<void> stop() async {
    await _fileWatcher.stop();
    await _processManager.stop();
  }

  /// Handle file changes
  Future<void> _onFileChanged() async {
    if (_isReloading) {
      return; // Already reloading
    }

    _isReloading = true;

    try {
      print('📝 File change detected');
      print('🔄 Restarting server...');
      print('');

      final stopwatch = Stopwatch()..start();

      await _processManager.restart();

      stopwatch.stop();
      print('');
      print('✅ Restart complete (${stopwatch.elapsedMilliseconds}ms)');
      print('');
    } catch (e) {
      print('❌ Error: Failed to restart');
      print('   $e');
      print('');
    } finally {
      _isReloading = false;
    }
  }
}
