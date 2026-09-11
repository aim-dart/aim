import 'dart:io';

import 'package:test/test.dart';

/// The public barrel may export aim_core, the Bindings/CfProperties value
/// types, and the two adapter extensions only, and must never make a
/// package:web type reachable.
void main() {
  test('lib/aim_edge.dart exports only the allowed surface', () {
    final source = File('lib/aim_edge.dart').readAsStringSync();
    final exports =
        RegExp(
              r'''^export\s+['"]([^'"]+)['"](\s+show\s+([^;]+))?;''',
              multiLine: true,
            )
            .allMatches(source)
            .map((m) => (uri: m.group(1)!, show: m.group(3)?.trim()))
            .toList();

    expect(exports, hasLength(5));
    expect(exports[0], (uri: 'package:aim_core/aim_core.dart', show: null));
    expect(exports[1], (uri: 'src/bindings.dart', show: 'Bindings'));
    expect(exports[2], (uri: 'src/cf_properties.dart', show: 'CfProperties'));
    expect(exports[3], (uri: 'src/edge_context.dart', show: 'EdgeContext'));
    expect(exports[4], (uri: 'src/serve_edge.dart', show: 'AimEdge'));
    expect(source, isNot(contains('package:web')));
  });

  test('exported extensions expose no package:web types', () {
    final context = File('lib/src/edge_context.dart').readAsStringSync();
    final serve = File('lib/src/serve_edge.dart').readAsStringSync();
    final publicMembers = RegExp(
      r'^\s{2}(?:JSObject\?|Bindings\?|CfProperties\?|void)\s+(?:get\s+)?\w+',
      multiLine: true,
    );
    // Any two-space-indented line that looks like the start of a member
    // declaration (starts with a letter, so doc comments starting with
    // `//`/`///` are excluded automatically since they start with `/`).
    final declarationLines = RegExp(r'^  [A-Za-z_][^\n]*$', multiLine: true);
    // Every member of the two exported extensions returns JSObject?,
    // Bindings?, CfProperties? or void.
    final extensionBodies = [
      _extensionBody(context, 'EdgeContext'),
      _extensionBody(serve, 'AimEdge'),
    ];
    for (final body in extensionBodies) {
      // Restrict the "no package:web type" check to member *signatures*
      // (two-space-indented lines starting with a return type), not the
      // full method body: AimEdge.serveEdge()'s implementation references
      // web.Request inside an internal closure, which is fine as long as
      // that type never appears in the member's public signature.
      final signatures = publicMembers
          .allMatches(body)
          .map((m) => m.group(0)!)
          .join('\n');
      expect(
        signatures,
        isNot(contains('web.')),
        reason:
            'exported extension member signature mentions a '
            'package:web type:\n$signatures',
      );
      expect(publicMembers.hasMatch(body), isTrue);
      // Every top-level declaration line in the extension body must be one
      // of the JSObject?/Bindings?/CfProperties?/void-returning members
      // matched above: if the two counts diverge, some member has snuck in
      // with a different return type that publicMembers failed to catch.
      expect(
        declarationLines.allMatches(body).length,
        equals(publicMembers.allMatches(body).length),
        reason:
            'every exported member must return JSObject?, Bindings?, '
            'CfProperties? or void',
      );
    }
  });

  test('Bindings and CfProperties expose no package:web types', () {
    final bindings = File('lib/src/bindings.dart').readAsStringSync();
    final cfProperties = File('lib/src/cf_properties.dart').readAsStringSync();
    const allowedReturnTypes = {
      'String?',
      'double?',
      'int?',
      'bool',
      'JSObject?',
      'JSObject',
    };
    // Matches the head of any public member declaration line: an optional
    // `final`, a return-type token, an optional `get`, then an identifier
    // that does NOT start with `_` (excludes the private `_string`/`_double`/
    // `_int` helpers). Deliberately permissive about the return type itself
    // -- it matches a member whose return type is one of the allowed ones
    // just as readily as e.g. a hypothetical `Object? get bogus`. A
    // constructor line (`Bindings(this.raw);`) never matches: there is no
    // whitespace between the class name and `(`, so the required `[ \t]+`
    // after the leading token can't be satisfied. A doc-comment line is
    // excluded by the `(?!/)` lookahead right after the indent. The gaps
    // use `[ \t]+` rather than `\s+` so a match can never cross a newline:
    // `\s+` would let a private helper's closing `}` chain across the
    // blank line into the next member's return-type token, fabricating a
    // phantom match.
    final publicDeclarationHead = RegExp(
      r'^  (?!/)(?:final[ \t]+)?\S+[ \t]+(?:get[ \t]+)?[A-Za-z]\w*\b',
      multiLine: true,
    );
    // Same shape, but the return-type token is restricted to the allowed
    // set. If every public member has an allowed return type, this matches
    // exactly as many lines as [publicDeclarationHead]; if some public
    // member's return type is NOT in the allowed set, this regex silently
    // fails to match that line while [publicDeclarationHead] still does,
    // so the counts diverge below and the test fails.
    final typedPublicDeclarationHead = RegExp(
      r'^  (?!/)(?:final[ \t]+)?(String\?|double\?|int\?|bool|JSObject\?|JSObject)'
      r'[ \t]+(?:get[ \t]+)?[A-Za-z]\w*\b',
      multiLine: true,
    );

    for (final entry in {
      'Bindings': bindings,
      'CfProperties': cfProperties,
    }.entries) {
      final className = entry.key;
      final source = entry.value;
      expect(source, isNot(contains('package:web')));

      final body = _classBody(source, className);

      // No public member line mentions a package:web type.
      final publicLines = publicDeclarationHead
          .allMatches(body)
          .map((m) => m.group(0)!)
          .toList();
      for (final line in publicLines) {
        expect(
          line,
          isNot(contains('web.')),
          reason:
              'public member of $className mentions a package:web '
              'type: $line',
        );
      }

      // Every public member's declared return type is one of the allowed
      // types: if the two counts diverge, some public member has a return
      // type outside [allowedReturnTypes].
      expect(
        typedPublicDeclarationHead.allMatches(body).length,
        equals(publicDeclarationHead.allMatches(body).length),
        reason:
            'every public member of $className must return one of '
            '$allowedReturnTypes',
      );
    }
  });
}

String _classBody(String source, String name) {
  final start = source.indexOf(RegExp('class $name\\b'));
  expect(start, greaterThanOrEqualTo(0), reason: 'class $name not found');
  var depth = 0;
  for (var i = source.indexOf('{', start); i < source.length; i++) {
    if (source[i] == '{') depth++;
    if (source[i] == '}') depth--;
    if (depth == 0) return source.substring(start, i + 1);
  }
  fail('unbalanced braces in $name');
}

String _extensionBody(String source, String name) {
  final start = source.indexOf(RegExp('extension $name\\b'));
  expect(start, greaterThanOrEqualTo(0), reason: 'extension $name not found');
  var depth = 0;
  for (var i = source.indexOf('{', start); i < source.length; i++) {
    if (source[i] == '{') depth++;
    if (source[i] == '}') depth--;
    if (depth == 0) return source.substring(start, i + 1);
  }
  fail('unbalanced braces in $name');
}
