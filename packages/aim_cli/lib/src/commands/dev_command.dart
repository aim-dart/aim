import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:aim_cli/src/utils/env_expander.dart';
import 'package:aim_cli/src/hot_reload/hot_reloader.dart';

class DevCommand extends Command {
  @override
  final name = 'dev';

  @override
  final description = 'Start development server (with hot reload support)';

  @override
  String get invocation => 'aim dev';

  DevCommand() {
    argParser.addOption(
      'entry',
      abbr: 'e',
      help: 'Server entry point (default: bin/server.dart)',
    );
    argParser.addOption('host', help: 'Server host (if configured)');
    argParser.addOption('port', abbr: 'p', help: 'Server port (if configured)');
    argParser.addFlag(
      'hot-reload',
      defaultsTo: true,
      negatable: true,
      help: 'Automatically restart server on file changes (default: enabled)',
    );
    argParser.addOption(
      'watch',
      help: 'Comma-separated list of directories to watch (default: lib,bin)',
    );
  }

  @override
  Future<void> run() async {
    // Check pubspec.yaml in current directory
    final pubspecFile = File('pubspec.yaml');

    if (!await pubspecFile.exists()) {
      print('Error: pubspec.yaml not found');
      print('Please run from the root directory of an Aim project');
      exit(1);
    }

    // Determine entry point
    String entryPoint = argResults?['entry'] as String? ?? 'bin/server.dart';

    // Read aim configuration from pubspec.yaml
    final pubspecContent = await pubspecFile.readAsString();
    final aimEntryPoint = _extractAimEntry(pubspecContent);
    if (aimEntryPoint != null) {
      entryPoint = aimEntryPoint;
    }

    // Check if entry point file exists
    final entryFile = File(entryPoint);
    if (!await entryFile.exists()) {
      print('Error: Entry point "$entryPoint" not found');
      exit(1);
    }

    // Get environment variables
    final envVars = _extractAimEnv(pubspecContent);

    // Get current environment variables and merge with aim.env settings
    final environment = Map<String, String>.from(Platform.environment);
    environment.addAll(envVars);

    // Hot reload configuration
    final hotReloadEnabled = argResults?['hot-reload'] as bool? ?? true;
    final watchPathsArg = argResults?['watch'] as String?;
    final watchPaths = watchPathsArg?.split(',') ?? ['lib', 'bin'];

    if (hotReloadEnabled) {
      await _runWithHotReload(
        entryPoint: entryPoint,
        environment: environment,
        envVars: envVars,
        watchPaths: watchPaths,
      );
    } else {
      await _runWithoutHotReload(
        entryPoint: entryPoint,
        environment: environment,
        envVars: envVars,
      );
    }
  }

  /// Run with hot reload
  Future<void> _runWithHotReload({
    required String entryPoint,
    required Map<String, String> environment,
    required Map<String, String> envVars,
    required List<String> watchPaths,
  }) async {
    print('🚀 Starting development server...');
    print('📁 Entry point: $entryPoint');
    if (envVars.isNotEmpty) {
      print('🔧 Environment variables: ${envVars.keys.join(', ')}');
    }
    print('👀 Watching files: ${watchPaths.join(', ')}');
    print('');

    final reloader = HotReloader(
      entryPoint: entryPoint,
      environment: environment,
      watchPaths: watchPaths,
    );

    // Ctrl+C handler
    ProcessSignal.sigint.watch().listen((signal) async {
      print('\n🛑 Stopping server...');
      await reloader.stop();
      print('✅ Server stopped');
      exit(0);
    });

    try {
      await reloader.start();
    } catch (e) {
      print('❌ Error: $e');
      exit(1);
    }
  }

  /// Run without hot reload (existing behavior)
  Future<void> _runWithoutHotReload({
    required String entryPoint,
    required Map<String, String> environment,
    required Map<String, String> envVars,
  }) async {
    print('🚀 Starting development server...');
    print('📁 Entry point: $entryPoint');
    if (envVars.isNotEmpty) {
      print('🔧 Environment variables: ${envVars.keys.join(', ')}');
    }
    print('');

    // Start server with dart run
    final process = await Process.start(
      'dart',
      ['run', entryPoint],
      mode: ProcessStartMode.inheritStdio,
      environment: environment,
    );

    // Wait for process to exit
    final exitCode = await process.exitCode;
    exit(exitCode);
  }

  /// Extract aim configuration from pubspec.yaml
  String? _extractAimEntry(String content) {
    // Simple YAML parsing (look for aim.entry)
    final lines = content.split('\n');
    bool inAimSection = false;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Start of aim: section
      if (line.trim().startsWith('aim:')) {
        inAimSection = true;
        continue;
      }

      // Look for entry in aim section
      if (inAimSection) {
        if (line.startsWith('  entry:') || line.startsWith('    entry:')) {
          final parts = line.split(':');
          if (parts.length >= 2) {
            final entry = parts[1]
                .trim()
                .replaceAll('"', '')
                .replaceAll("'", '');
            if (entry.isNotEmpty) {
              return entry;
            }
          }
        }

        // End aim section if next top-level section starts
        if (line.isNotEmpty &&
            !line.startsWith(' ') &&
            !line.startsWith('\t')) {
          inAimSection = false;
        }
      }
    }

    return null;
  }

  /// Extract environment variables from pubspec.yaml
  Map<String, String> _extractAimEnv(String content) {
    final envVars = <String, String>{};
    final lines = content.split('\n');
    bool inAimSection = false;
    bool inEnvSection = false;

    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];

      // Start of aim: section
      if (line.trim().startsWith('aim:')) {
        inAimSection = true;
        continue;
      }

      if (inAimSection) {
        // Start of env: section
        if (line.startsWith('  env:') || line.startsWith('    env:')) {
          inEnvSection = true;
          continue;
        }

        // Read environment variables in env section
        if (inEnvSection) {
          // End env section if indentation decreases
          if (line.isNotEmpty &&
              !line.startsWith('    ') &&
              !line.startsWith('\t\t')) {
            inEnvSection = false;

            // End aim section if top-level section
            if (!line.startsWith(' ') && !line.startsWith('\t')) {
              inAimSection = false;
            }
            continue;
          }

          // Read environment variable key: value
          final trimmed = line.trim();
          if (trimmed.contains(':')) {
            final parts = trimmed.split(':');
            if (parts.length >= 2) {
              final key = parts[0].trim();
              var value = parts
                  .sublist(1)
                  .join(':')
                  .trim()
                  .replaceAll('"', '')
                  .replaceAll("'", '');

              if (key.isNotEmpty && value.isNotEmpty) {
                // Expand environment variables
                value = EnvExpander.expand(value);
                envVars[key] = value;
              }
            }
          }
        }

        // End aim section if next top-level section starts
        if (!inEnvSection &&
            line.isNotEmpty &&
            !line.startsWith(' ') &&
            !line.startsWith('\t')) {
          inAimSection = false;
        }
      }
    }

    return envVars;
  }
}
