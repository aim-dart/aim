import 'dart:io';
import 'package:aim_cli/src/config/aim_config.dart';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;

class BuildCommand extends Command {
  @override
  final name = 'build';

  @override
  final description = 'Compile the server for production deployment';

  @override
  String get invocation => 'aim build [options]';

  BuildCommand() {
    argParser.addOption(
      'entry',
      abbr: 'e',
      help:
          'Server entry point (default: pubspec.yaml aim.entry or bin/server.dart)',
    );

    argParser.addOption(
      'output',
      abbr: 'o',
      help: 'Output file path (default: build/server)',
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
    final config = await AimConfig.load();
    final entryPoint = config.resolveEntry(argResults?['entry'] as String?);

    // Check if entry point file exists
    final entryFile = File(entryPoint);
    if (!await entryFile.exists()) {
      print('Error: Entry point "$entryPoint" not found');
      exit(1);
    }

    // Determine output path
    String outputPath = argResults?['output'] as String? ?? 'build/server';

    // Create output directory if it doesn't exist
    final outputDir = Directory(path.dirname(outputPath));
    if (!await outputDir.exists()) {
      await outputDir.create(recursive: true);
    }

    // Build compile command
    final compileArgs = ['compile', 'exe', entryPoint, '-o', outputPath];

    // Display build information
    print('🔨 Compiling for production...');
    print('📁 Entry point: $entryPoint');
    print('📦 Output: $outputPath');
    print('');

    // Execute compilation
    final process = await Process.start(
      'dart',
      compileArgs,
      mode: ProcessStartMode.inheritStdio,
    );

    final exitCode = await process.exitCode;

    if (exitCode != 0) {
      print('');
      print('❌ Compilation failed');
      exit(exitCode);
    }

    // Success message
    print('');
    print('✅ Build successful!');
    print('');
    print('📦 Executable: $outputPath');
    print('');
    print('Next steps:');
    print('  # Run locally');
    print('  ./$outputPath');
    print('');
    print('  # Build Docker image');
    print('  docker build -t my-app .');
    print('');
  }
}
