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

/// Whether [pid] is still alive, per `kill -0`.
Future<bool> _isAlive(int pid) async {
  final result = await Process.run('kill', ['-0', '$pid']);
  return result.exitCode == 0;
}

/// Kills [pid] and all of its descendants.
///
/// Descendants are enumerated and killed before the root so that they are
/// not reparented and left running (npx -> wrangler -> workerd).
///
/// Terminates gently first: `SIGTERM` is sent to every descendant (deepest
/// first) and then to the root, and this waits up to 2 seconds (polling
/// every 200ms) for `pgrep -P <root>` to report no children and for
/// `kill -0 <root>` to fail. Whatever is still alive after that — checked
/// individually, deepest descendants first, then the root — is force-killed
/// with `SIGKILL`.
Future<void> killProcessTree(int pid) async {
  final descendants = await _descendantPids(pid);

  for (final descendant in descendants) {
    await Process.run('kill', ['-TERM', '$descendant']);
  }
  await Process.run('kill', ['-TERM', '$pid']);

  const pollInterval = Duration(milliseconds: 200);
  const maxWait = Duration(seconds: 2);
  var waited = Duration.zero;
  while (waited < maxWait) {
    final pgrepResult = await Process.run('pgrep', ['-P', '$pid']);
    final noChildren = (pgrepResult.stdout as String).trim().isEmpty;
    if (noChildren && !await _isAlive(pid)) break;
    await Future.delayed(pollInterval);
    waited += pollInterval;
  }

  for (final descendant in descendants) {
    if (await _isAlive(descendant)) {
      await Process.run('kill', ['-9', '$descendant']);
    }
  }
  if (await _isAlive(pid)) {
    await Process.run('kill', ['-9', '$pid']);
  }
}
