import 'dart:io';
import 'package:path/path.dart' as path;

class FileGenerator {
  /// Load template file
  static Future<String> loadTemplate(String templateName) async {
    // Load template from relative path to package lib directory
    // Platform.script points to bin/aim.dart, so go up 2 levels to get package root
    final scriptPath = Platform.script.toFilePath();
    final packageRoot = path.dirname(path.dirname(scriptPath));
    final templatePath = path.join(
      packageRoot,
      'lib',
      'src',
      'templates',
      templateName,
    );

    final file = File(templatePath);

    if (!await file.exists()) {
      throw Exception('Template file not found: $templatePath');
    }

    return await file.readAsString();
  }

  /// Replace variables in template
  static String replaceVariables(
    String template,
    Map<String, String> variables,
  ) {
    var result = template;
    variables.forEach((key, value) {
      result = result.replaceAll('{{$key}}', value);
    });
    return result;
  }

  /// Generate file (automatically create directories)
  static Future<void> writeFile(String filePath, String content) async {
    final file = File(filePath);
    final dir = file.parent;

    // Create directory if it doesn't exist
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }

    await file.writeAsString(content);
  }
}
