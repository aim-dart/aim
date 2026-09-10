import 'dart:io';

import 'package:test/test.dart';

/// The public barrel may export aim_core and the two adapter extensions only,
/// and must never make a package:web type reachable.
void main() {
  test('lib/aim_edge.dart exports only the allowed surface', () {
    final source = File('lib/aim_edge.dart').readAsStringSync();
    final exports = RegExp(r'''^export\s+['"]([^'"]+)['"](\s+show\s+([^;]+))?;''',
            multiLine: true)
        .allMatches(source)
        .map((m) => (uri: m.group(1)!, show: m.group(3)?.trim()))
        .toList();

    expect(exports, hasLength(3));
    expect(exports[0], (uri: 'package:aim_core/aim_core.dart', show: null));
    expect(exports[1], (uri: 'src/edge_request.dart', show: 'EdgeRequestAccess'));
    expect(exports[2], (uri: 'src/serve_edge.dart', show: 'AimEdge'));
    expect(source, isNot(contains('package:web')));
  });

  test('exported extensions expose no package:web types', () {
    final request = File('lib/src/edge_request.dart').readAsStringSync();
    final serve = File('lib/src/serve_edge.dart').readAsStringSync();
    final publicMembers = RegExp(r'^\s{2}(?:JSObject\?|void)\s+(?:get\s+)?\w+',
        multiLine: true);
    // Every member of the two exported extensions returns JSObject? or void.
    final extensionBodies = [
      _extensionBody(request, 'EdgeRequestAccess'),
      _extensionBody(serve, 'AimEdge'),
    ];
    for (final body in extensionBodies) {
      // Restrict the "no package:web type" check to member *signatures*
      // (two-space-indented lines starting with a return type), not the
      // full method body: AimEdge.serveEdge()'s implementation references
      // web.Request inside an internal closure, which is fine as long as
      // that type never appears in the member's public signature.
      final signatures =
          publicMembers.allMatches(body).map((m) => m.group(0)!).join('\n');
      expect(signatures, isNot(contains('web.')),
          reason: 'exported extension member signature mentions a '
              'package:web type:\n$signatures');
      expect(publicMembers.hasMatch(body), isTrue);
    }
  });
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
