import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;
import 'package:aim_cli/src/utils/validators.dart';
import 'package:aim_cli/src/utils/file_generator.dart';
import 'package:aim_cli/src/templates/templates.dart';

class CreateCommand extends Command {
  @override
  final name = 'create';

  @override
  final description = 'Create a new Aim framework project';

  @override
  String get invocation => 'aim create <project_name>';

  CreateCommand() {
    argParser.addOption(
      'target',
      allowed: ['server', 'edge'],
      defaultsTo: 'server',
      help: 'Runtime target: server (dart:io) or edge (Cloudflare workerd)',
    );
  }

  @override
  Future<void> run() async {
    // Get project name
    if (argResults?.rest.isEmpty ?? true) {
      throw UsageException('Please specify a project name', invocation);
    }

    final projectName = argResults!.rest.first;
    final target = argResults!['target'] as String;

    // Validation
    if (!ProjectNameValidator.isValid(projectName)) {
      throw UsageException(
        ProjectNameValidator.getErrorMessage(projectName),
        invocation,
      );
    }

    // Create project directory
    final projectDir = Directory(projectName);

    if (await projectDir.exists()) {
      throw UsageException(
        'Directory "$projectName" already exists',
        invocation,
      );
    }

    print('📦 Creating project "$projectName"...');

    try {
      // Create directory structure
      await _createProjectStructure(projectName, target);

      print('');
      print('✅ Project created successfully!');
      print('');
      print('Next steps:');
      print('  cd $projectName');
      print('  dart pub get');
      print('  aim dev');
      if (target == 'edge') {
        print('  # requires Node: npx wrangler@4 is downloaded on first run');
      }
      print('');
    } catch (e) {
      throw Exception('Failed to create project: $e');
    }
  }

  Future<void> _createProjectStructure(
    String projectName,
    String target,
  ) async {
    final workerName = projectName.replaceAll('_', '-');
    final variables = {'projectName': projectName, 'workerName': workerName};

    // Get templates from string constants and generate
    final templates = target == 'edge'
        ? {
            'pubspec.yaml': Templates.edgePubspec,
            'README.md': Templates.edgeReadme,
            'lib/main.dart': Templates.edgeMain,
            'src/index.mjs': Templates.edgeIndexMjs,
            'wrangler.jsonc': Templates.edgeWranglerJsonc,
            '.gitignore': Templates.edgeGitignore,
          }
        : {
            'pubspec.yaml': Templates.projectPubspec,
            'README.md': Templates.projectReadme,
            'bin/server.dart': Templates.binServer,
            'lib/src/server.dart': Templates.libSrcServer,
            'test/${projectName}_test.dart': Templates.testTest,
            '.gitignore': Templates.gitignore,
            'Dockerfile': Templates.dockerfile,
            '.dockerignore': Templates.dockerignore,
          };

    for (final entry in templates.entries) {
      final filePath = path.join(projectName, entry.key);
      final template = entry.value;

      print('  Creating: $filePath');

      final content = FileGenerator.replaceVariables(template, variables);
      await FileGenerator.writeFile(filePath, content);
    }
  }
}
