import 'dart:io';

/// PIDs of every descendant of [pid], deepest first (children before parents).
///
/// Best-effort: processes forked while enumerating may be missed.
Future<List<int>> _descendantPids(int pid) async {
  final result = await Process.run('pgrep', ['-P', '$pid']);
  final children = (result.stdout as String)
      .split('\n')
      .map((s) => s.trim())
      .where((s) => s.isNotEmpty)
      .map(int.parse)
      .toList();
  final ordered = <int>[];
  for (final child in children) {
    ordered.addAll(await _descendantPids(child));
    ordered.add(child);
  }
  return ordered;
}

/// Kills [pid] and all of its descendants.
///
/// Descendants are enumerated and killed before the root so that they are
/// not reparented and left running (npx -> wrangler -> workerd).
Future<void> killProcessTree(int pid) async {
  for (final descendant in await _descendantPids(pid)) {
    await Process.run('kill', ['-9', '$descendant']);
  }
  await Process.run('kill', ['-9', '$pid']);
}
