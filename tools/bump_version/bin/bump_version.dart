import 'dart:io';

import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Aim packages that should be versioned together.
const aimPackagePrefixes = ['aim_'];

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run bump_version <version>');
    stderr.writeln('Example: dart run bump_version 0.1.0');
    exit(1);
  }

  final newVersion = args[0];

  if (!_isValidVersion(newVersion)) {
    stderr.writeln('Invalid version format: $newVersion');
    stderr.writeln('Expected format: x.y.z (e.g., 0.1.0, 1.0.0)');
    exit(1);
  }

  final packagesDir = Directory('packages');
  if (!packagesDir.existsSync()) {
    stderr.writeln('packages directory not found. Run from repository root.');
    exit(1);
  }

  final pubspecFiles = <File>[];
  for (final entity in packagesDir.listSync()) {
    if (entity is Directory) {
      final pubspec = File('${entity.path}/pubspec.yaml');
      if (pubspec.existsSync()) {
        pubspecFiles.add(pubspec);
      }
    }
  }

  if (pubspecFiles.isEmpty) {
    stderr.writeln('No pubspec.yaml files found in packages/');
    exit(1);
  }

  stdout.writeln('Bumping version to $newVersion\n');

  for (final file in pubspecFiles) {
    _updatePubspec(file, newVersion);
    _updateChangelog(file.parent, newVersion);
  }

  // Update docs version
  _updateDocsVersion(newVersion);

  stdout.writeln('\nDone! Updated ${pubspecFiles.length} packages to $newVersion');
  stdout.writeln('\nNext steps:');
  stdout.writeln('  1. Review changes: git diff');
  stdout.writeln('  2. Commit: git commit -am "chore: bump version to $newVersion"');
  stdout.writeln('  3. Tag: git tag v$newVersion');
}

bool _isValidVersion(String version) {
  final regex = RegExp(r'^\d+\.\d+\.\d+(-[\w.]+)?(\+[\w.]+)?$');
  return regex.hasMatch(version);
}

void _updatePubspec(File file, String newVersion) {
  final content = file.readAsStringSync();
  final yaml = loadYaml(content) as YamlMap;
  final editor = YamlEditor(content);

  final packageName = yaml['name'] as String;
  final oldVersion = yaml['version'] as String?;

  // Update version
  if (oldVersion != null) {
    editor.update(['version'], newVersion);
    stdout.writeln('$packageName: $oldVersion → $newVersion');
  }

  // Update aim_* dependencies
  final dependencies = yaml['dependencies'];
  if (dependencies is YamlMap) {
    for (final dep in dependencies.keys) {
      final depName = dep as String;
      if (_isAimPackage(depName)) {
        final currentVersion = dependencies[depName];
        if (currentVersion is String) {
          editor.update(['dependencies', depName], '^$newVersion');
          stdout.writeln('  └─ $depName: $currentVersion → ^$newVersion');
        }
      }
    }
  }

  // Update aim_* dev_dependencies
  final devDependencies = yaml['dev_dependencies'];
  if (devDependencies is YamlMap) {
    for (final dep in devDependencies.keys) {
      final depName = dep as String;
      if (_isAimPackage(depName)) {
        final currentVersion = devDependencies[depName];
        if (currentVersion is String) {
          editor.update(['dev_dependencies', depName], '^$newVersion');
          stdout.writeln('  └─ $depName (dev): $currentVersion → ^$newVersion');
        }
      }
    }
  }

  file.writeAsStringSync(editor.toString());
}

bool _isAimPackage(String packageName) {
  return aimPackagePrefixes.any((prefix) => packageName.startsWith(prefix));
}

const _repoUrl = 'https://github.com/aim-dart/aim';

void _updateChangelog(Directory packageDir, String newVersion) {
  final changelogFile = File('${packageDir.path}/CHANGELOG.md');
  final newEntry = '''## $newVersion

See [Release Notes]($_repoUrl/releases/tag/v$newVersion)
''';

  if (changelogFile.existsSync()) {
    final content = changelogFile.readAsStringSync();

    // Check if this version already exists
    if (content.contains('## $newVersion')) {
      return;
    }

    // Insert at the beginning, or after # Changelog header if exists
    final lines = content.split('\n');
    final headerIndex = lines.indexWhere((line) => line.startsWith('# '));

    if (headerIndex != -1) {
      lines.insert(headerIndex + 1, '\n$newEntry');
    } else {
      // No header, insert at beginning
      lines.insert(0, '$newEntry\n');
    }
    changelogFile.writeAsStringSync(lines.join('\n'));
  } else {
    // Create new CHANGELOG.md
    final content = '''# Changelog

$newEntry''';
    changelogFile.writeAsStringSync(content);
  }
}

void _updateDocsVersion(String newVersion) {
  final configFile = File('docs/.vitepress/config.mts');
  if (!configFile.existsSync()) {
    return;
  }

  var content = configFile.readAsStringSync();
  var updated = false;

  // Update softwareVersion in JSON-LD
  final softwareVersionRegex = RegExp(r'"softwareVersion":\s*"[^"]*"');
  if (softwareVersionRegex.hasMatch(content)) {
    content = content.replaceFirst(
      softwareVersionRegex,
      '"softwareVersion": "$newVersion"',
    );
    updated = true;
  }

  // Update nav version (e.g., text: 'v0.0.6')
  final navVersionRegex = RegExp(r"text:\s*'v[\d.]+'");
  if (navVersionRegex.hasMatch(content)) {
    content = content.replaceFirst(navVersionRegex, "text: 'v$newVersion'");
    updated = true;
  }

  if (updated) {
    configFile.writeAsStringSync(content);
    stdout.writeln('docs: config.mts → v$newVersion');
  }
}
