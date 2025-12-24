/// Validates project names
class ProjectNameValidator {
  /// Check if valid as Dart package name
  static bool isValid(String name) {
    // Check for empty string
    if (name.isEmpty) return false;

    // Allow only lowercase letters, numbers, and underscores
    final validPattern = RegExp(r'^[a-z][a-z0-9_]*$');
    if (!validPattern.hasMatch(name)) return false;

    // Check for reserved words
    const reservedWords = ['dart', 'test', 'lib', 'bin'];
    if (reservedWords.contains(name)) return false;

    return true;
  }

  /// Generate error message
  static String getErrorMessage(String name) {
    if (name.isEmpty) {
      return 'Please specify a project name';
    }

    if (!RegExp(r'^[a-z]').hasMatch(name)) {
      return 'Project name must start with a lowercase letter';
    }

    if (!RegExp(r'^[a-z0-9_]+$').hasMatch(name)) {
      return 'Project name can only contain lowercase letters, numbers, and underscores';
    }

    const reservedWords = ['dart', 'test', 'lib', 'bin'];
    if (reservedWords.contains(name)) {
      return 'Cannot use reserved words as project name (dart, test, lib, bin)';
    }

    return 'Invalid project name';
  }
}
