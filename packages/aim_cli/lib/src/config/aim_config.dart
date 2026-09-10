import 'dart:io';

import 'package:aim_cli/src/utils/env_expander.dart';
import 'package:yaml/yaml.dart';

/// Where an Aim application runs. Read from `aim.target` in pubspec.yaml.
enum AimTarget {
  /// Dart VM with `aim_server` (`dart compile exe`, `dart run`).
  server,

  /// Cloudflare workerd with `aim_edge` (`dart compile wasm`, `wrangler dev`).
  edge;

  static AimTarget parse(String value) => switch (value) {
        'server' => AimTarget.server,
        'edge' => AimTarget.edge,
        _ => throw FormatException(
            'Unknown aim.target "$value". Expected "server" or "edge".',
          ),
      };
}

/// The `aim:` section of a project's pubspec.yaml.
class AimConfig {
  final AimTarget target;

  /// `aim.entry` as written, or `null` when not configured.
  final String? configuredEntry;

  /// `aim.env` with `${VAR:default}` / `${VAR}` / `$VAR` expanded.
  final Map<String, String> env;

  const AimConfig({
    this.target = AimTarget.server,
    this.configuredEntry,
    this.env = const {},
  });

  /// Entry point used when neither `--entry` nor `aim.entry` is given.
  String get defaultEntry => switch (target) {
        AimTarget.server => 'bin/server.dart',
        AimTarget.edge => 'lib/main.dart',
      };

  /// `--entry` beats `aim.entry`, which beats [defaultEntry].
  String resolveEntry(String? cliOverride) =>
      cliOverride ?? configuredEntry ?? defaultEntry;

  /// Parses pubspec.yaml source. A missing or non-map `aim:` yields defaults.
  static AimConfig parse(String yamlSource) {
    final doc = loadYaml(yamlSource);
    if (doc is! YamlMap) return const AimConfig();
    final aim = doc['aim'];
    if (aim is! YamlMap) return const AimConfig();

    final targetValue = aim['target'];
    final target = targetValue == null
        ? AimTarget.server
        : AimTarget.parse(targetValue.toString());

    final entryValue = aim['entry'];
    final entry = entryValue == null ? null : entryValue.toString();

    final env = <String, String>{};
    final envValue = aim['env'];
    if (envValue is YamlMap) {
      envValue.forEach((key, value) {
        if (value == null) return;
        env[key.toString()] = EnvExpander.expand(value.toString());
      });
    }

    return AimConfig(target: target, configuredEntry: entry, env: env);
  }

  /// Reads and parses [pubspecPath] (default `pubspec.yaml` in the CWD).
  static Future<AimConfig> load([String pubspecPath = 'pubspec.yaml']) async {
    return parse(await File(pubspecPath).readAsString());
  }
}
