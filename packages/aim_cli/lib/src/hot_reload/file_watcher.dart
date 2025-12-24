import 'dart:async';
import 'dart:io';
import 'package:watcher/watcher.dart';

/// Class to watch file changes and perform debounce processing
class FileWatcher {
  final List<String> _watchPaths;
  final Duration _debounceDuration;
  final void Function() _onChanged;

  final List<StreamSubscription<WatchEvent>> _subscriptions = [];
  Timer? _debounceTimer;

  FileWatcher({
    required List<String> watchPaths,
    required void Function() onChanged,
    Duration debounceDuration = const Duration(milliseconds: 500),
  })  : _watchPaths = watchPaths,
        _onChanged = onChanged,
        _debounceDuration = debounceDuration;

  /// Start watching
  Future<void> start() async {
    for (final watchPath in _watchPaths) {
      final dir = Directory(watchPath);

      if (!await dir.exists()) {
        print('⚠️  Warning: Watch directory "$watchPath" not found');
        continue;
      }

      final watcher = DirectoryWatcher(watchPath);
      final subscription = watcher.events.listen(
        _handleChange,
        onError: (error) {
          print('⚠️  File watch error: $error');
        },
      );
      _subscriptions.add(subscription);
    }

    if (_subscriptions.isEmpty) {
      print('⚠️  Warning: No valid watch directories');
    }
  }

  /// Stop watching
  Future<void> stop() async {
    _debounceTimer?.cancel();
    _debounceTimer = null;

    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();
  }

  /// Check if file should be watched
  bool _shouldWatch(String path) {
    return path.endsWith('.dart') || path.endsWith('pubspec.yaml');
  }

  /// Debounce processing
  void _handleChange(WatchEvent event) {
    if (!_shouldWatch(event.path)) {
      return;
    }

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      _onChanged();
    });
  }
}
