import 'dart:io';

import 'package:release/changelog.dart';
import 'package:release/template_pins.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';

/// Aim packages that should be versioned together.
const aimPackagePrefixes = ['aim_'];

void main(List<String> args) {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run release:bump <version>');
    stderr.writeln('Example: dart run release:bump 0.1.0');
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

  // Update aim_* pins embedded in the aim_cli scaffold templates
  _updateCliTemplates(newVersion);

  // Update docs version
  _updateDocsVersion(newVersion);

  stdout.writeln('\nDone! Updated ${pubspecFiles.length} packages to $newVersion');
  stdout.writeln('\nNext steps:');
  stdout.writeln('  1. Review changes: git diff');
  stdout.writeln('  2. Commit: git commit -am "chore: bump version to $newVersion"');
  stdout.writeln(
    '  3. Tag: git tag $newVersion  (no "v" prefix: docs deploy and create_release expect 0.2.0-style tags)',
  );
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

final _unreleasedHeadingPattern = RegExp(
  r'^\s*##\s*unreleased\s*$',
  multiLine: true,
  caseSensitive: false,
);

void _updateChangelog(Directory packageDir, String newVersion) {
  final changelogFile = File('${packageDir.path}/CHANGELOG.md');
  final packageName = packageDir.path
      .split(Platform.pathSeparator)
      .where((segment) => segment.isNotEmpty)
      .last;

  if (!changelogFile.existsSync()) {
    // Create new CHANGELOG.md
    final content = '''# Changelog

## $newVersion

See [Release Notes]($_repoUrl/releases/tag/$newVersion)
''';
    changelogFile.writeAsStringSync(content);
    stdout.writeln('$packageName: CHANGELOG + $newVersion');
    return;
  }

  final content = changelogFile.readAsStringSync();
  final hadUnreleased = _unreleasedHeadingPattern.hasMatch(content);
  final updated = bumpChangelog(content, newVersion, repoUrl: _repoUrl);

  if (updated == content) {
    return;
  }

  changelogFile.writeAsStringSync(updated);
  if (hadUnreleased) {
    stdout.writeln('$packageName: CHANGELOG Unreleased → $newVersion');
  } else {
    stdout.writeln('$packageName: CHANGELOG + $newVersion');
  }
}

void _updateCliTemplates(String newVersion) {
  final templatesFile = File(
    'packages/aim_cli/lib/src/templates/templates.dart',
  );
  if (!templatesFile.existsSync()) {
    stdout.writeln(
      'Warning: aim_cli templates file not found, skipping template pins update.',
    );
    return;
  }

  final content = templatesFile.readAsStringSync();
  final pinRegex = RegExp(
    r'^(\s*)(aim_\w+): \^(\d+\.\d+\.\d+(?:-[\w.]+)?(?:\+[\w.]+)?)$',
    multiLine: true,
  );

  for (final match in pinRegex.allMatches(content)) {
    final depName = match[2]!;
    final oldVersion = match[3]!;
    if (oldVersion != newVersion) {
      stdout.writeln(
        'aim_cli templates: $depName ^$oldVersion → ^$newVersion',
      );
    }
  }

  final updated = bumpTemplatePins(content, newVersion);
  if (updated != content) {
    templatesFile.writeAsStringSync(updated);
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
