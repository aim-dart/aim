import 'package:aim_core/src/app.dart';
import 'package:aim_core/src/env.dart';

/// Internal class representing a route with path pattern matching.
///
/// Supports:
/// - Named parameters: `/users/:id`
/// - Regex constraints: `/users/:id(\\d+)`
/// - Wildcard: `/posts/*`
/// - Wildcard parameter: `/static/*filepath`
class Route<E extends Env> {
  /// The path pattern for this route.
  final String path;

  /// The HTTP method for this route (e.g., 'GET', 'POST').
  final String method;

  /// The handler function for this route.
  final Handler<E> handler;

  /// Optional metadata for this route (e.g., OpenAPI spec, rate limiting config).
  final Object? metadata;

  /// Regular expression pattern for matching the route
  late final RegExp? _pattern;

  /// Names of path parameters in order
  late final List<String> _paramNames;

  Route({
    required this.path,
    required this.method,
    required this.handler,
    this.metadata,
  }) {
    _paramNames = [];

    // Parse path pattern and extract parameter names
    // Supports:
    // - Named parameters: /users/:id
    // - Regex constraints: /users/:id(\\d+)
    // - Wildcard: /posts/*
    // - Wildcard parameter: /static/*filepath
    final segments = path.split('/');
    final patternSegments = <String>[];
    var hasPattern = false;

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];

      if (segment.startsWith('*')) {
        // Wildcard or wildcard parameter
        hasPattern = true;

        if (segment.length > 1) {
          // Wildcard parameter like *filepath
          final paramName = segment.substring(1);
          _paramNames.add(paramName);
          // Match everything including slashes
          patternSegments.add('(.*)');
        } else {
          // Plain wildcard *
          // Match everything including slashes but don't capture
          patternSegments.add('.*');
        }
        // Wildcard should be the last segment
        break;
      } else if (segment.startsWith(':')) {
        // Named parameter with optional regex constraint
        hasPattern = true;
        final paramContent = segment.substring(1);

        // Check for regex constraint like :id(\\d+)
        final regexMatch = RegExp(r'^(\w+)\((.+)\)$').firstMatch(paramContent);

        if (regexMatch != null) {
          // Parameter with regex constraint
          final paramName = regexMatch.group(1)!;
          final regexPattern = regexMatch.group(2)!;
          _paramNames.add(paramName);
          patternSegments.add('($regexPattern)');
        } else {
          // Simple parameter like :id
          final paramName = paramContent;
          _paramNames.add(paramName);
          patternSegments.add('([^/]+)'); // Match any non-slash characters
        }
      } else {
        // Literal segment
        patternSegments.add(RegExp.escape(segment));
      }
    }

    // Create regex pattern if there are parameters or wildcards
    if (hasPattern || _paramNames.isNotEmpty) {
      final pattern = '^${patternSegments.join('/')}\$';
      _pattern = RegExp(pattern);
    } else {
      _pattern = null;
    }
  }

  /// Matches the given path and extracts parameters
  /// Returns a map of parameter names to values, or null if no match
  Map<String, String>? match(String requestPath) {
    // If no parameters, do exact match
    final pattern = _pattern;
    if (pattern == null) {
      return requestPath == path ? {} : null;
    }

    // Try to match the pattern
    final match = pattern.firstMatch(requestPath);
    if (match == null) return null;

    // Extract parameters
    final params = <String, String>{};
    for (var i = 0; i < _paramNames.length; i++) {
      params[_paramNames[i]] = match.group(i + 1)!;
    }

    return params;
  }
}
