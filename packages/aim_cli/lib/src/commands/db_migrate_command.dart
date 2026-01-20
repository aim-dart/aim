import 'dart:convert';
import 'dart:io';

import 'package:aim_postgres/aim_postgres.dart';
import 'package:args/command_runner.dart';
import 'package:crypto/crypto.dart';
import 'package:yaml/yaml.dart';

class DbMigrateCommand extends Command<void> {
  @override
  String get name => 'db:migrate';

  @override
  String get description => 'Apply pending migrations to the database';

  DbMigrateCommand() {
    argParser.addOption(
      'target',
      abbr: 't',
      help: 'Apply migrations up to this target (e.g., 20260120094025_add_users)',
    );
  }

  @override
  Future<void> run() async {
    // 1. DB接続情報を取得
    final dbUrl = await _getDatabaseUrl();
    if (dbUrl == null) {
      print('Error: Database URL not found');
      print('Set aim.database.url in pubspec.yaml');
      exit(1);
    }

    // 2. マイグレーションファイルを取得
    final migrationsDir = Directory('db/migrations');
    if (!await migrationsDir.exists()) {
      print('No migrations directory found');
      return;
    }

    final migrationFiles = await migrationsDir
        .list()
        .where((f) => f is File && f.path.endsWith('.sql'))
        .cast<File>()
        .toList();

    if (migrationFiles.isEmpty) {
      print('No migration files found');
      return;
    }

    // ファイル名でソート
    migrationFiles.sort((a, b) => _fileName(a).compareTo(_fileName(b)));

    // 3. DB接続
    print('🔌 Connecting to database...');
    final db = await PostgresDatabase.connect(dbUrl);

    try {
      // 4. マイグレーションテーブルを作成（なければ）
      await _ensureMigrationsTable(db);

      // 5. 適用済みマイグレーションを取得
      final applied = await _getAppliedMigrations(db);

      // 6. 未適用のマイグレーションをフィルタ
      final target = argResults?['target'] as String?;
      final pending = <File>[];

      for (final file in migrationFiles) {
        final name = _migrationName(file);
        if (applied.contains(name)) continue;

        pending.add(file);

        // --target が指定されていて、そこに到達したら終了
        if (target != null && name.startsWith(target)) {
          break;
        }
      }

      if (pending.isEmpty) {
        print('✅ No pending migrations');
        return;
      }

      print('📦 Found ${pending.length} pending migration(s)');
      print('');

      // 7. マイグレーションを適用
      for (final file in pending) {
        final name = _migrationName(file);
        final content = await file.readAsString();
        final checksum = _calculateChecksum(content);

        print('  Applying: $name');

        try {
          // 複数のSQL文を分割して実行
          final statements = _splitStatements(content);
          for (final stmt in statements) {
            if (stmt.trim().isNotEmpty) {
              await db.execute(stmt);
            }
          }
          await _recordMigration(db, name, checksum);
          print('  ✅ Applied: $name');
        } catch (e) {
          print('  ❌ Failed: $name');
          print('  Error: $e');
          print('');
          print('Migration stopped. Please fix the error and retry.');
          // TODO: ロールバック対応
          exit(1);
        }
      }

      print('');
      print('✅ All migrations applied successfully');
    } finally {
      await db.close();
    }
  }

  Future<String?> _getDatabaseUrl() async {
    final pubspecFile = File('pubspec.yaml');
    if (!await pubspecFile.exists()) return null;

    final content = await pubspecFile.readAsString();
    final yaml = loadYaml(content);

    if (yaml is! YamlMap) return null;
    final aim = yaml['aim'];
    if (aim is! YamlMap) return null;
    final database = aim['database'];
    if (database is! YamlMap) return null;

    return database['url'] as String?;
  }

  String _fileName(File file) {
    return file.path.split('/').last;
  }

  String _migrationName(File file) {
    // 拡張子を除いたファイル名
    final name = _fileName(file);
    return name.endsWith('.sql') ? name.substring(0, name.length - 4) : name;
  }

  String _calculateChecksum(String content) {
    return md5.convert(utf8.encode(content)).toString();
  }

  /// SQL文を分割（セミコロンで区切る、ただしコメント内は無視）
  List<String> _splitStatements(String sql) {
    final statements = <String>[];
    final buffer = StringBuffer();
    bool inSingleLineComment = false;
    bool inMultiLineComment = false;

    for (var i = 0; i < sql.length; i++) {
      final char = sql[i];
      final nextChar = i + 1 < sql.length ? sql[i + 1] : '';

      // 単一行コメント開始
      if (!inMultiLineComment && char == '-' && nextChar == '-') {
        inSingleLineComment = true;
        buffer.write(char);
        continue;
      }

      // 単一行コメント終了
      if (inSingleLineComment && char == '\n') {
        inSingleLineComment = false;
        buffer.write(char);
        continue;
      }

      // 複数行コメント開始
      if (!inSingleLineComment && char == '/' && nextChar == '*') {
        inMultiLineComment = true;
        buffer.write(char);
        continue;
      }

      // 複数行コメント終了
      if (inMultiLineComment && char == '*' && nextChar == '/') {
        inMultiLineComment = false;
        buffer.write(char);
        continue;
      }

      // セミコロンで文を分割（コメント外のみ）
      if (char == ';' && !inSingleLineComment && !inMultiLineComment) {
        final stmt = buffer.toString().trim();
        if (stmt.isNotEmpty) {
          statements.add(stmt);
        }
        buffer.clear();
        continue;
      }

      buffer.write(char);
    }

    // 最後の文（セミコロンなし）
    final lastStmt = buffer.toString().trim();
    if (lastStmt.isNotEmpty) {
      statements.add(lastStmt);
    }

    return statements;
  }

  Future<void> _ensureMigrationsTable(PostgresDatabase db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS _aim_migrations (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) NOT NULL UNIQUE,
        checksum VARCHAR(32) NOT NULL,
        applied_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
      )
    ''');
  }

  Future<Set<String>> _getAppliedMigrations(PostgresDatabase db) async {
    final result = await db.query(
      'SELECT name FROM _aim_migrations ORDER BY name',
    );
    return result.map((row) => row['name'] as String).toSet();
  }

  Future<void> _recordMigration(
    PostgresDatabase db,
    String name,
    String checksum,
  ) async {
    await db.execute(
      'INSERT INTO _aim_migrations (name, checksum) VALUES (:name, :checksum)',
      params: {'name': name, 'checksum': checksum},
    );
  }
}
