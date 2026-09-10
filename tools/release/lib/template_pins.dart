/// Rewrites `aim_*: ^x.y.z` dependency pins inside the aim_cli scaffold
/// templates (Dart string constants) to `^newVersion`.
///
/// Only lines that consist of optional indentation, an `aim_` package name,
/// `: ^`, and a semver (with optional pre-release/build) are touched.
String bumpTemplatePins(String source, String newVersion) {
  final pinRegex = RegExp(
    r'^(\s*)(aim_\w+): \^\d+\.\d+\.\d+(?:-[\w.]+)?(?:\+[\w.]+)?$',
    multiLine: true,
  );
  return source.replaceAllMapped(
    pinRegex,
    (m) => '${m[1]}${m[2]}: ^$newVersion',
  );
}
