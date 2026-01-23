import 'package:aim_orm_postgres/aim_orm_postgres.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

class RecordPgTableGenerator extends GeneratorForAnnotation<PgTable> {
  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    final tableName = annotation.peek('name')?.stringValue;

    if (tableName == null || tableName.isEmpty) {
      throw InvalidGenerationSourceError(
        'The `name` parameter in `@PgTable` annotation cannot be null or empty.',
        element: element,
      );
    }

    if (element is! TopLevelVariableElement) {
      throw InvalidGenerationSourceError(
        '`@PgTable` can only be applied to top-level variables.',
        element: element,
      );
    }

    final type = element.type;
    if (type is! RecordType) {
      throw InvalidGenerationSourceError(
        'The variable `${element.name}` must be of a record type to use the `@Table` annotation.',
        element: element,
      );
    }

    if (element.name == null || element.name!.isEmpty) {
      throw InvalidGenerationSourceError(
        'The variable name cannot be null or empty.',
        element: element,
      );
    }

    final libraryReader = await buildStep.resolver.compilationUnitFor(
      buildStep.inputId,
    );
    final recordVisitor = RecordVisitor(element.name!);
    libraryReader.accept(recordVisitor);
    final recordLiteral = recordVisitor.foundRecord;

    final fields = <({String name, Expression expression})>[];
    if (recordLiteral != null) {
      for (final field in recordLiteral.fields) {
        if (field is NamedExpression) {
          final fieldName = field.name.label.name;
          final expression = field.expression;
          fields.add((name: fieldName, expression: expression));
        }
      }
    }

    final records = fields.map((field) {
      final record = analyzeField(field.name, field.expression);
      return record;
    }).toList();

    final buffer = StringBuffer();
    generateExtensionForTable(buffer, tableName);
    generateTransactionExtensionForTable(buffer, tableName);
    generateQueryBuilder(buffer, tableName);
    generateSelectRowBuilder(buffer, tableName, records);
    generateSelectBuilder(buffer, tableName, records);
    generateSelectConfig(buffer, tableName);
    generateInsertBuilder(buffer, tableName, records);
    generateUpdateBuilder(buffer, tableName, records);
    generateDeleteBuilder(buffer, tableName, records);
    generateRelationSelectBuilder(buffer, tableName, records);

    return buffer.toString();
  }

  void generateExtensionForTable(StringBuffer buffer, String tableName) {
    final className = '${capitalize(tableName)}QueryBuilder';
    buffer.writeln(
      'extension Postgres${capitalize(tableName)}DatabaseX on PostgresDatabase {',
    );
    buffer.writeln('  $className get $tableName => $className(this);');
    buffer.writeln('}');
    buffer.writeln();
  }

  void generateTransactionExtensionForTable(
    StringBuffer buffer,
    String tableName,
  ) {
    final className = '${capitalize(tableName)}QueryBuilder';
    buffer.writeln(
      'extension Postgres${capitalize(tableName)}TransactionX on PostgresTransaction {',
    );
    buffer.writeln('  $className get $tableName => $className(this);');
    buffer.writeln('}');
    buffer.writeln();
  }

  void generateQueryBuilder(StringBuffer buffer, String tableName) {
    buffer.writeln('// Query Builder for table: $tableName');
    buffer.writeln('class ${capitalize(tableName)}QueryBuilder {');
    buffer.writeln('  final PostgresQueryable db;');
    buffer.writeln();
    buffer.writeln('  ${capitalize(tableName)}QueryBuilder(this.db);');
    buffer.writeln();
    buffer.writeln('${capitalize(tableName)}SelectBuilder select() {');
    buffer.writeln('  return ${capitalize(tableName)}SelectBuilder(');
    buffer.writeln('    db,');
    buffer.writeln(
      '    ${capitalize(tableName)}SelectConfig(where: null, limit: null, offset: null),',
    );
    buffer.writeln('  );');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('${capitalize(tableName)}InsertBuilder insert() {');
    buffer.writeln('  return ${capitalize(tableName)}InsertBuilder(db);');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('${capitalize(tableName)}UpdateBuilder update() {');
    buffer.writeln('  return ${capitalize(tableName)}UpdateBuilder(db);');
    buffer.writeln('}');
    buffer.writeln();
    buffer.writeln('${capitalize(tableName)}DeleteBuilder delete() {');
    buffer.writeln('  return ${capitalize(tableName)}DeleteBuilder(db);');
    buffer.writeln('}');
    buffer.writeln('}');
    buffer.writeln();
  }

  void generateSelectRowBuilder(
    StringBuffer buffer,
    String tableName,
    List<AnalyzedField> fields,
  ) {
    buffer.writeln('typedef ${capitalize(tableName)}Row = ({');
    buffer.writeln(
      fields
          .map(
            (f) => '${f.returnType}${f.isNullable ? '?' : ''} ${f.fieldName}',
          )
          .join(','),
    );
    buffer.writeln('});');
    buffer.writeln();
  }

  void generateSelectBuilder(
    StringBuffer buffer,
    String tableName,
    List<AnalyzedField> fields,
  ) {
    buffer.writeln(
      'class ${capitalize(tableName)}SelectBuilder extends QueryFuture<List<${capitalize(tableName)}Row>> with FutureMixin<List<${capitalize(tableName)}Row>> {',
    );
    buffer.writeln('  final PostgresQueryable db;');
    buffer.writeln('  final ${capitalize(tableName)}SelectConfig config;');
    buffer.writeln();
    buffer.writeln(
      '  ${capitalize(tableName)}SelectBuilder(this.db, this.config);',
    );
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  Future<List<${capitalize(tableName)}Row>> execute() {');
    buffer.writeln(
      '    final sqlBuffer = StringBuffer(\'SELECT * FROM $tableName\');',
    );
    buffer.writeln('    final params = <String, dynamic>{};');
    buffer.writeln();
    buffer.writeln('    if (config.where.isNotEmpty) {');
    buffer.writeln('      sqlBuffer.write(\' WHERE \');');
    buffer.writeln('      final whereClauses = <String>[];');
    buffer.writeln();
    buffer.writeln('      for (var i = 0; i < config.where.length; i++) {');
    buffer.writeln('        final condition = config.where[i];');
    buffer.writeln('        whereClauses.add(condition.toSql(i));');
    buffer.writeln('        params.addAll(condition.toParams(i));');
    buffer.writeln('      }');
    buffer.writeln();
    buffer.writeln('      sqlBuffer.write(whereClauses.join(\' AND \'));');
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln('    if (config.limit != null) {');
    buffer.writeln('      sqlBuffer.write(\' LIMIT \${config.limit}\');');
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln('    if (config.offset != null) {');
    buffer.writeln('      sqlBuffer.write(\' OFFSET \${config.offset}\');');
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln('    final sql = sqlBuffer.toString();');
    buffer.writeln('    return db.query(sql, params: params).then((result) {');
    buffer.writeln('      return result.map((row) {');
    buffer.writeln('        return (');
    for (final field in fields) {
      switch (field.columnMapper) {
        case PgColumnMapper.integer:
        case PgColumnMapper.serial:
          if (field.isNullable) {
            buffer.writeln(
              '  ${field.fieldName}: row[\'${field.columnName}\'] != null ? int.parse(row[\'${field.columnName}\'] as String) : null,',
            );
            break;
          } else {
            buffer.writeln(
              '  ${field.fieldName}: int.parse(row[\'${field.columnName}\'] as String),',
            );
            break;
          }
        case PgColumnMapper.varchar:
        case PgColumnMapper.text:
        case PgColumnMapper.uuid:
          buffer.writeln(
            '  ${field.fieldName}: row[\'${field.columnName}\'] as String${field.isNullable ? '?' : ''},',
          );
          break;
        case PgColumnMapper.timestamp:
          if (field.isNullable) {
            buffer.writeln(
              '  ${field.fieldName}: row[\'${field.columnName}\'] != null ? DateTime.parse(row[\'${field.columnName}\'] as String) : null,',
            );
            break;
          } else {
            buffer.writeln(
              '  ${field.fieldName}: DateTime.parse(row[\'${field.columnName}\'] as String),',
            );
            break;
          }
        case PgColumnMapper.jsonb:
          buffer.writeln(
            '  ${field.fieldName}: row[\'${field.columnName}\'] as Map<String, dynamic>${field.isNullable ? '?' : ''},',
          );
          break;
        case PgColumnMapper.unknown:
          buffer.writeln('  ${field.fieldName}: row[\'${field.columnName}\'],');
      }
    }
    buffer.writeln('        );');
    buffer.writeln('      }).toList();');
    buffer.writeln('    });');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  ${capitalize(tableName)}SelectBuilder where({');
    for (final field in fields) {
      buffer.writeln('    Condition? ${field.fieldName},');
    }
    buffer.writeln('  }) {');
    buffer.writeln('    final newConditions = [...config.where];');
    for (final field in fields) {
      buffer.writeln('    if (${field.fieldName} != null) ');
      buffer.writeln('      newConditions.add(${field.fieldName});');
    }
    buffer.writeln();
    buffer.writeln('    return ${capitalize(tableName)}SelectBuilder(');
    buffer.writeln('      db,');
    buffer.writeln('      ${capitalize(tableName)}SelectConfig(');
    buffer.writeln('        where: newConditions,');
    buffer.writeln('        limit: config.limit,');
    buffer.writeln('        offset: config.offset,');
    buffer.writeln('      ),');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln(
      '  ${capitalize(tableName)}SelectBuilder limit(int limit) {',
    );
    buffer.writeln('    return ${capitalize(tableName)}SelectBuilder(');
    buffer.writeln('      db,');
    buffer.writeln('      ${capitalize(tableName)}SelectConfig(');
    buffer.writeln('        where: config.where,');
    buffer.writeln('        limit: limit,');
    buffer.writeln('        offset: config.offset,');
    buffer.writeln('      ),');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln(
      '  ${capitalize(tableName)}SelectBuilder offset(int offset) {',
    );
    buffer.writeln('    return ${capitalize(tableName)}SelectBuilder(');
    buffer.writeln('      db,');
    buffer.writeln('      ${capitalize(tableName)}SelectConfig(');
    buffer.writeln('        where: config.where,');
    buffer.writeln('        limit: config.limit,');
    buffer.writeln('        offset: offset,');
    buffer.writeln('      ),');
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln();
  }

  void generateSelectConfig(StringBuffer buffer, String tableName) {
    buffer.writeln('class ${capitalize(tableName)}SelectConfig {');
    buffer.writeln('  final List<Condition> where;');
    buffer.writeln('  final int? limit;');
    buffer.writeln('  final int? offset;');
    buffer.writeln();
    buffer.writeln('  ${capitalize(tableName)}SelectConfig({');
    buffer.writeln('    required List<Condition>? where,');
    buffer.writeln('    required this.limit,');
    buffer.writeln('    required this.offset,');
    buffer.writeln('  }) : where = where ?? [];');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  String toString() {');
    buffer.writeln(
      "    return '${capitalize(tableName)}SelectConfig(where: \$where, limit: \$limit, offset: \$offset)';",
    );
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln();
  }

  void generateInsertBuilder(
    StringBuffer buffer,
    String tableName,
    List<AnalyzedField> fields,
  ) {
    buffer.writeln(
      'class ${capitalize(tableName)}InsertBuilder extends QueryFuture<int> with FutureMixin<int> {',
    );
    buffer.writeln('  final PostgresQueryable db;');
    for (final field in fields) {
      buffer.writeln('  final ${field.returnType}? _${field.fieldName};');
    }
    buffer.writeln();
    buffer.writeln('  ${capitalize(tableName)}InsertBuilder(this.db, {');
    for (final field in fields) {
      buffer.writeln('    ${field.returnType}? ${field.fieldName},');
    }
    buffer.writeln(
      '  }): ${fields.map((f) => '_${f.fieldName} = ${f.fieldName}').join(', ')};',
    );
    buffer.writeln();
    buffer.writeln('  ${capitalize(tableName)}InsertBuilder values({');
    for (final field in fields) {
      buffer.writeln(
        '    ${field.isNullable ? '' : 'required'} ${field.returnType}${field.isNullable ? '?' : ''} ${field.fieldName},',
      );
    }
    buffer.writeln('  }) {');
    buffer.writeln('    return ${capitalize(tableName)}InsertBuilder(db,');
    for (final field in fields) {
      buffer.writeln('      ${field.fieldName}: ${field.fieldName},');
    }
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  Future<int> execute() {');
    for (final field in fields) {
      if (!field.isNullable) {
        buffer.writeln('    if (_${field.fieldName} == null) {');
        buffer.writeln(
          "      throw StateError('Field `${field.fieldName}` is required but not set');",
        );
        buffer.writeln('    }');
      }
    }
    final columnNames = fields.map((r) => r.columnName).toList();
    buffer.writeln(
      "    final sql = 'INSERT INTO $tableName (${columnNames.join(', ')}) "
      "VALUES (${columnNames.map((name) => ':$name').join(', ')})';",
    );
    buffer.writeln('    final params = {');
    for (final field in fields) {
      buffer.writeln("      '${field.columnName}': _${field.fieldName},");
    }
    buffer.writeln('    };');
    buffer.writeln('    return db.execute(sql, params: params);');
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln();
  }

  void generateUpdateBuilder(
    StringBuffer buffer,
    String tableName,
    List<AnalyzedField> fields,
  ) {
    buffer.writeln(
      'class ${capitalize(tableName)}UpdateBuilder extends QueryFuture<int> with FutureMixin<int> {',
    );
    buffer.writeln('  final PostgresQueryable db;');
    for (final field in fields) {
      buffer.writeln('  final ${field.returnType}? _${field.fieldName};');
    }
    buffer.writeln('  final List<Condition> _where;');
    buffer.writeln();
    buffer.writeln(
      '  ${capitalize(tableName)}UpdateBuilder(this.db, {${fields.map((r) => '${r.returnType}? ${r.fieldName}').join(', ')}, List<Condition>? where})',
    );
    buffer.writeln(
      '    : ${fields.map((f) => '_${f.fieldName} = ${f.fieldName}').join(', ')}, _where = where ?? [];',
    );
    buffer.writeln();
    buffer.writeln('  // SET句（更新するカラムを指定）');
    buffer.writeln('  ${capitalize(tableName)}UpdateBuilder set({');
    for (final record in fields) {
      buffer.writeln('    ${record.returnType}? ${record.fieldName},');
    }
    buffer.writeln('  }) {');
    buffer.writeln(
      '    return ${capitalize(tableName)}UpdateBuilder(db, where: _where,',
    );
    for (final record in fields) {
      buffer.writeln('      ${record.fieldName}: ${record.fieldName},');
    }
    buffer.writeln(');');
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  // WHERE句（SelectBuilderと同じ仕組み）');
    buffer.writeln('  ${capitalize(tableName)}UpdateBuilder where({');
    for (final record in fields) {
      buffer.writeln('    Condition? ${record.fieldName},');
    }
    buffer.writeln('  }) {');
    buffer.writeln('    final newConditions = [..._where];');
    for (final record in fields) {
      buffer.writeln('    if (${record.fieldName} != null) ');
      buffer.writeln('      newConditions.add(${record.fieldName});');
    }
    buffer.writeln(
      '    return ${capitalize(tableName)}UpdateBuilder(db, where: newConditions,',
    );
    for (final record in fields) {
      buffer.writeln('      ${record.fieldName}: _${record.fieldName},');
    }
    buffer.writeln(');');
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  Future<int> execute() {');
    buffer.writeln();
    buffer.writeln('    // SET句の構築');
    buffer.writeln('    final updates = <String>[];');
    buffer.writeln('    final params = <String, dynamic>{};');
    for (final record in fields) {
      buffer.writeln('    if (_${record.fieldName} != null) {');
      buffer.writeln(
        "      updates.add('${record.columnName} = :set_${record.columnName}');",
      );
      buffer.writeln(
        '      params[\'set_${record.columnName}\'] = _${record.fieldName};',
      );
      buffer.writeln('    }');
    }
    buffer.writeln();
    buffer.writeln(
      '    if (updates.isEmpty) throw StateError(\'No fields to update\');',
    );
    buffer.writeln();
    buffer.writeln(
      "    final sqlBuffer = StringBuffer('UPDATE $tableName SET \${updates.join(', ')}');",
    );
    buffer.writeln();
    buffer.writeln('    // WHERE句の構築');
    buffer.writeln('    if (_where.isNotEmpty) {');
    buffer.writeln("      sqlBuffer.write(' WHERE ');");
    buffer.writeln('      final whereClauses = <String>[];');
    buffer.writeln('      for (var i = 0; i < _where.length; i++) {');
    buffer.writeln('        final condition = _where[i];');
    buffer.writeln('        whereClauses.add(condition.toSql(i));');
    buffer.writeln('        params.addAll(condition.toParams(i));');
    buffer.writeln('      }');
    buffer.writeln("      sqlBuffer.write(whereClauses.join(' AND '));");
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln(
      '    return db.execute(sqlBuffer.toString(), params: params);',
    );
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln();
  }

  void generateDeleteBuilder(
    StringBuffer buffer,
    String tableName,
    List<AnalyzedField> fields,
  ) {
    buffer.writeln(
      'class ${capitalize(tableName)}DeleteBuilder extends QueryFuture<int> with FutureMixin<int> {',
    );
    buffer.writeln('  final PostgresQueryable db;');
    buffer.writeln('  final List<Condition> _where;');
    buffer.writeln();
    buffer.writeln(
      '  ${capitalize(tableName)}DeleteBuilder(this.db, [List<Condition>? where]) : _where = where ?? [];',
    );
    buffer.writeln();
    buffer.writeln('  // WHERE句（SelectBuilderと同じ仕組み）');
    buffer.writeln('  ${capitalize(tableName)}DeleteBuilder where({');
    for (final record in fields) {
      buffer.writeln('    Condition? ${record.fieldName},');
    }
    buffer.writeln('  }) {');
    buffer.writeln('    final newConditions = [..._where];');
    for (final record in fields) {
      buffer.writeln('    if (${record.fieldName} != null) ');
      buffer.writeln('      newConditions.add(${record.fieldName});');
    }
    buffer.writeln(
      '    return ${capitalize(tableName)}DeleteBuilder(db, newConditions);',
    );
    buffer.writeln('  }');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln('  Future<int> execute() {');
    buffer.writeln(
      "    final sqlBuffer = StringBuffer('DELETE FROM $tableName');",
    );
    buffer.writeln('    final params = <String, dynamic>{};');
    buffer.writeln();
    buffer.writeln('    // WHERE句の構築');
    buffer.writeln('    if (_where.isNotEmpty) {');
    buffer.writeln("      sqlBuffer.write(' WHERE ');");
    buffer.writeln('      final whereClauses = <String>[];');
    buffer.writeln('      for (var i = 0; i < _where.length; i++) {');
    buffer.writeln('        final condition = _where[i];');
    buffer.writeln('        whereClauses.add(condition.toSql(i));');
    buffer.writeln('        params.addAll(condition.toParams(i));');
    buffer.writeln('      }');
    buffer.writeln("      sqlBuffer.write(whereClauses.join(' AND '));");
    buffer.writeln('    }');
    buffer.writeln();
    buffer.writeln(
      '    return db.execute(sqlBuffer.toString(), params: params);',
    );
    buffer.writeln('  }');
    buffer.writeln('}');
    buffer.writeln();
  }

  void generateRelationSelectBuilder(
    StringBuffer buffer,
    String tableName,
    List<AnalyzedField> fields,
  ) {}

  void analyzeMethodChain(Expression expression) {
    if (expression is MethodInvocation) {
      final methodName = expression.methodName.name;
      print('Method: $methodName');
      for (final arg in expression.argumentList.arguments) {
        if (arg is IntegerLiteral) {
          print('  Argument: ${arg.value}');
        }
      }

      if (expression.target != null) {
        analyzeMethodChain(expression.target!);
      }
    }
  }

  AnalyzedField analyzeField(String fieldName, Expression expression) {
    bool isPrimaryKey = false;
    bool isUnique = false;
    bool isNullable = false;
    String? columnType;
    String? columnName;
    PgColumnMapper? columnMapper;
    String? returnType;
    int? varcharLength;
    String? refTable;
    String? refColumn;

    // メソッドチェーンを全部集める
    final methods = <MethodInvocation>[];
    Expression? current = expression;
    while (current is MethodInvocation) {
      methods.add(current);
      current = current.target;
    }

    // 逆順（起点から）で解析
    for (final method in methods.reversed) {
      final methodName = method.methodName.name;

      final column = PgColumnMapper.match(methodName);
      if (column != null) {
        columnMapper = column;
        columnType = column.name;
        returnType = column.dartType;

        // 第一引数からカラム名を取得
        if (method.argumentList.arguments.isNotEmpty) {
          final firstArg = method.argumentList.arguments.first;
          if (firstArg is SimpleStringLiteral) {
            columnName = firstArg.value; // 'created_at' を取得
          }
        }

        // varcharの場合、名前付きパラメータ 'length' を取得
        if (methodName == 'varchar') {
          for (final arg in method.argumentList.arguments) {
            if (arg is NamedExpression && arg.name.label.name == 'length') {
              if (arg.expression is IntegerLiteral) {
                varcharLength = (arg.expression as IntegerLiteral).value;
              }
            }
          }
        }
      } else if (methodName == 'primaryKey') {
        isPrimaryKey = true;
      } else if (methodName == 'unique') {
        isUnique = true;
      } else if (methodName == 'nullable') {
        isNullable = true;
      } else if (methodName == 'references') {
        print('Found references() method - foreign key detected.');
        for (final arg in method.argumentList.arguments) {
          print('  Argument: $arg, type: ${arg.runtimeType}');
          if (arg is FunctionExpression) {
            final body = arg.body;
            print('    Function body: $body, type: ${body.runtimeType}');
            if (body is ExpressionFunctionBody) {
              final refExpr = body.expression;
              print(
                '    Returned expression: $refExpr, type: ${refExpr.runtimeType}',
              );
              if (refExpr is PropertyAccess) {
                refTable = refExpr.target.toString();
                refColumn = refExpr.propertyName.name;
                print('      Target: $refTable, Property: $refColumn');
              }
              if (refExpr is PrefixedIdentifier) {
                refTable = refExpr.prefix.name;
                refColumn = refExpr.identifier.name;
                print('      Foreign key references $refTable.$refColumn');
              }
            }
          }
        }
      }
    }

    return (
      fieldName: fieldName,
      columnType: columnType ?? 'unknown',
      columnName: columnName ?? fieldName,
      returnType: returnType ?? 'dynamic',
      columnMapper: columnMapper ?? PgColumnMapper.unknown,
      isPrimaryKey: isPrimaryKey,
      isUnique: isUnique,
      isNullable: isNullable,
      varcharLength: varcharLength,
      refTable: refTable,
      refColumn: refColumn,
    );
  }
}

typedef AnalyzedField = ({
  String fieldName,
  String columnType, // 'integer', 'varchar' など
  String columnName,
  String returnType, // 'int', 'String' など
  PgColumnMapper columnMapper,
  bool isPrimaryKey,
  bool isUnique,
  bool isNullable,
  int? varcharLength,
  String? refTable,
  String? refColumn,
});

class RecordVisitor extends RecursiveAstVisitor<void> {
  final String targetName;
  RecordLiteral? foundRecord;

  RecordVisitor(this.targetName);

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    for (final variable in node.variables.variables) {
      if (variable.name.lexeme == targetName) {
        if (variable.initializer is RecordLiteral) {
          foundRecord = variable.initializer as RecordLiteral;
        }
      }
    }
    super.visitTopLevelVariableDeclaration(node);
  }
}

String capitalize(String s) {
  if (s.isEmpty) return s;
  return s[0].toUpperCase() + s.substring(1);
}

enum PgColumnMapper {
  integer('int'),
  varchar('String'),
  text('String'),
  timestamp('DateTime'),
  serial('int'),
  jsonb('Map<String, dynamic>'),
  uuid('String'),
  unknown('dynamic');

  // 未対応（共通カラム型 - aim_orm）
  // bigint('int'),           // BIGINT - 大きな整数
  // smallint('int'),         // SMALLINT - 小さな整数
  // decimal('double'),       // DECIMAL/NUMERIC - 精密な数値（金額など）
  // double('double'),        // DOUBLE PRECISION/FLOAT
  // boolean('bool'),         // BOOLEAN/BOOL
  // date('DateTime'),        // DATE - 日付のみ
  // time('Duration'),        // TIME - 時刻のみ
  // blob('Uint8List'),       // BYTEA/BLOB - バイナリデータ
  // json('Map<String, dynamic>'), // JSON

  // 未対応（PostgreSQL固有 - aim_orm_postgres）
  // bigserial('int'),        // BIGSERIAL
  // timestamptz('DateTime'), // TIMESTAMP WITH TIME ZONE
  // timetz('Duration'),      // TIME WITH TIME ZONE
  // array('List<dynamic>'),  // ARRAY[]
  // inet('String'),          // INET - IPアドレス
  // cidr('String'),          // CIDR
  // macaddr('String'),       // MACADDR
  // money('double'),         // MONEY
  // xml('String'),           // XML
  // hstore('Map<String, String>'), // HSTORE

  final String dartType;

  const PgColumnMapper(this.dartType);

  static String? toDartType(String columnType) {
    for (final mapper in PgColumnMapper.values) {
      if (mapper.name == columnType) {
        return mapper.dartType;
      }
    }
    return null;
  }

  static PgColumnMapper? match(String value) {
    for (final mapper in PgColumnMapper.values) {
      if (mapper.name == value) {
        return mapper;
      }
    }
    return null;
  }
}
