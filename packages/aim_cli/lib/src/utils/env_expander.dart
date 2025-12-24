import 'dart:io';

/// Utility class for expanding environment variables
class EnvExpander {
  /// Expand environment variables
  ///
  /// Supported formats:
  /// - $VAR_NAME - Expand environment variable
  /// - ${VAR_NAME} - Expand environment variable
  /// - ${VAR_NAME:default_value} - With default value
  static String expand(String value, [Map<String, String>? environment]) {
    final env = environment ?? Platform.environment;
    var result = value;

    // ${VAR_NAME:default_value} pattern
    final regexWithDefault = RegExp(r'\$\{([^:}]+):([^}]+)\}');
    result = result.replaceAllMapped(regexWithDefault, (match) {
      final varName = match.group(1)!;
      final defaultValue = match.group(2)!;
      return env[varName] ?? defaultValue;
    });

    // ${VAR_NAME} pattern
    final regexBraces = RegExp(r'\$\{([^}]+)\}');
    result = result.replaceAllMapped(regexBraces, (match) {
      final varName = match.group(1)!;
      return env[varName] ?? '';
    });

    // $VAR_NAME pattern
    final regexSimple = RegExp(r'\$([A-Z_][A-Z0-9_]*)');
    result = result.replaceAllMapped(regexSimple, (match) {
      final varName = match.group(1)!;
      return env[varName] ?? '';
    });

    return result;
  }
}
