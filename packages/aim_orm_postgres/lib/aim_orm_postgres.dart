/// PostgreSQL database driver for the Aim ORM framework.
///
/// This library provides PostgreSQL-specific implementations of the Aim ORM
/// abstractions. It includes support for:
///
/// - SSL/TLS connections with multiple security modes
/// - Cleartext and MD5 password authentication
/// - Simple and Extended Query protocols
/// - Parameter binding and prepared statements
///
/// ## Usage
///
/// ```dart
/// import 'package:aim_orm_postgres/aim_orm_postgres.dart';
///
/// final db = await PostgresDatabase.connect(
///   'postgresql://user:pass@localhost:5432/mydb',
/// );
///
/// final results = await db.query('SELECT * FROM users WHERE id = $1', args: [1]);
/// await db.close();
/// ```
///
/// For SSL/TLS connections:
///
/// ```dart
/// final db = await PostgresDatabase.connect(
///   'postgresql://user:pass@localhost:5432/mydb?sslmode=require',
/// );
/// ```
library;

export 'src/pgtable.dart';