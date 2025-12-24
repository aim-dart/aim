import 'dart:io';
import 'package:args/command_runner.dart';
import 'package:path/path.dart' as path;
import '../utils/validators.dart';
import '../utils/file_generator.dart';
import '../templates/templates.dart';

class CreateCommand extends Command {
  @override
  final name = 'create';

  @override
  final description = 'Create a new Aim framework project';

  @override
  String get invocation => 'aim create <project_name>';

  CreateCommand();

  @override
  Future<void> run() async {
    // Get project name
    if (argResults?.rest.isEmpty ?? true) {
      throw UsageException(
        'Please specify a project name',
        invocation,
      );
    }

    final projectName = argResults!.rest.first;

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
      await _createProjectStructure(projectName);

      print('');
      print('✅ Project created successfully!');
      print('');
      print('Next steps:');
      print('  cd $projectName');
      print('  dart pub get');
      print('  aim dev');
      print('');
    } catch (e) {
      throw Exception('Failed to create project: $e');
    }
  }

  Future<void> _createProjectStructure(String projectName) async {
    final variables = {
      'projectName': projectName,
    };

    // Get templates from string constants and generate
    final templates = {
      'pubspec.yaml': Templates.projectPubspec,
      'README.md': Templates.projectReadme,
      'bin/server.dart': Templates.binServer,
      'lib/src/server.dart': Templates.libSrcServer,
      'test/${projectName}_test.dart': Templates.testTest,
      '.gitignore': Templates.gitignore,
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
