## 0.1.0

See [Release Notes](https://github.com/aim-dart/aim/releases/tag/v0.1.0)


## 0.0.1

Initial release of aim_orm_codegen - Code generation for aim_orm.

### Features

- Record Syntax Support:
  - `@PgTable` annotation processing
  - Dart Record field analysis
  - Column type detection (integer, varchar, text, timestamp, uuid, serial, jsonb)
- Generated Code:
  - Row typedef with named fields
  - QueryBuilder class for table access
  - SelectBuilder with WHERE, LIMIT, OFFSET support
  - InsertBuilder with type-safe values
  - UpdateBuilder with SET and WHERE
  - DeleteBuilder with WHERE
  - PostgresDatabase extension methods
  - PostgresTransaction extension methods
- Builders:
  - `record_pg_table` - For Record syntax with `@PgTable`
  - `table` - For class-based definitions (legacy)

### Supported

- Dart SDK: `^3.10.0`
- build_runner: `^2.4.0`
- analyzer: `^10.0.1`

### What's Included

- `RecordPgTableGenerator` - Main generator for Record syntax tables
- `TableGenerator` - Generator for class-based tables
- Builder configuration for build_runner integration
