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

    for (final field in fields) {
      final expression = field.expression;
      if (expression is MethodInvocation) {
        final methodName = expression.methodName.name;
        print('Field: ${field.name}, Method: $methodName');
      }
    }

    for (final field in fields) {
      final record = analyzeField(field.name, field.expression);
      print(
        'Field: ${record.fieldName}, Type: ${record.columnType}, '
        'PrimaryKey: ${record.isPrimaryKey}, Unique: ${record.isUnique}, '
        'Nullable: ${record.isNullable}, VarcharLength: ${record.varcharLength}',
      );
    }

    final buffer = StringBuffer();
    generateExtensionForTable(buffer, tableName);
    generateQueryBuilder(buffer, tableName);
    buffer.writeln('typedef UserRow = ({int id, String name, String email});');

    final preset = """
class UsersSelectBuilder extends QueryFuture<List<UserRow>>
    with FutureMixin<List<UserRow>> {
  final PostgresDatabase db;
  final UsersSelectConfig config;

  UsersSelectBuilder(this.db, this.config);

  @override
  Future<List<UserRow>> execute() {
    final sqlBuffer = StringBuffer('SELECT * FROM users');
    final params = <String, dynamic>{};

    if (config.where.isNotEmpty) {
      sqlBuffer.write(' WHERE ');
      final whereClauses = <String>[];

      for (var i = 0; i < config.where.length; i++) {
        final condition = config.where[i];
        whereClauses.add(condition.toSql(i));
        params.addAll(condition.toParams(i));
      }

      sqlBuffer.write(whereClauses.join(' AND '));
    }

    if (config.limit != null) {
      sqlBuffer.write(' LIMIT \${config.limit}');
    }

    if (config.offset != null) {
      sqlBuffer.write(' OFFSET \${config.offset}');
    }

    final sql = sqlBuffer.toString();
    return db.query(sql, params: params).then((result) {
      return result.map((row) {
        return (
          id: int.parse(row['id'] as String),
          name: row['name'] as String,
          email: row['email'] as String,
        );
      }).toList();
    });
  }

  UsersSelectBuilder where({Condition? id, Condition? name, Condition? email}) {
    final newConditions = [...config.where];
    if (id != null) newConditions.add(id);
    if (name != null) newConditions.add(name);
    if (email != null) newConditions.add(email);

    return UsersSelectBuilder(
      db,
      UsersSelectConfig(
        where: newConditions,
        limit: config.limit,
        offset: config.offset,
      ),
    );
  }

  UsersSelectBuilder limit(int limit) {
    return UsersSelectBuilder(
      db,
      UsersSelectConfig(
        where: config.where,
        limit: limit,
        offset: config.offset,
      ),
    );
  }

  UsersSelectBuilder offset(int offset) {
    return UsersSelectBuilder(
      db,
      UsersSelectConfig(
        where: config.where,
        limit: config.limit,
        offset: offset,
      ),
    );
  }
}

class UsersSelectConfig {
  final List<Condition> where;
  final int? limit;
  final int? offset;

  UsersSelectConfig({
    required List<Condition>? where,
    required this.limit,
    required this.offset,
  }) : where = where ?? [];

  @override
  String toString() {
    return 'UsersSelectConfig(where: \$where, limit: \$limit, offset: \$offset)';
  }
}

class UsersInsertBuilder extends QueryFuture<int> with FutureMixin<int> {
  final PostgresDatabase db;
  final ({int id, String name, String email})? _values;

  UsersInsertBuilder(this.db, {({String email, int id, String name})? values})
    : _values = values;

  UsersInsertBuilder values(({int id, String name, String email}) user) {
    return UsersInsertBuilder(db, values: user);
  }

  @override
  Future<int> execute() {
    if (_values == null) {
      throw StateError('No values set');
    }
    final sql =
        'INSERT INTO users (id, name, email) VALUES (:id, :name, :email)';
    final params = {
      'id': _values.id,
      'name': _values.name,
      'email': _values.email,
    };
    return db.execute(sql, params: params);
  }
}

class UsersUpdateBuilder extends QueryFuture<int> with FutureMixin<int> {
  final PostgresDatabase db;
  final ({String? name, String? email})? _values;
  final List<Condition> _where;

  UsersUpdateBuilder(this.db, [this._values, List<Condition>? where])
    : _where = where ?? [];

  // SET句（更新するカラムを指定）
  UsersUpdateBuilder set({String? name, String? email}) {
    return UsersUpdateBuilder(db, (name: name, email: email), _where);
  }

  // WHERE句（SelectBuilderと同じ仕組み）
  UsersUpdateBuilder where({Condition? id, Condition? name, Condition? email}) {
    final newConditions = [..._where];
    if (id != null) newConditions.add(id);
    if (name != null) newConditions.add(name);
    if (email != null) newConditions.add(email);
    return UsersUpdateBuilder(db, _values, newConditions);
  }

  @override
  Future<int> execute() {
    if (_values == null) throw StateError('No values set');

    // SET句の構築
    final updates = <String>[];
    final params = <String, dynamic>{};

    if (_values.name != null) {
      updates.add('name = :set_name');
      params['set_name'] = _values.name;
    }
    if (_values.email != null) {
      updates.add('email = :set_email');
      params['set_email'] = _values.email;
    }

    if (updates.isEmpty) throw StateError('No fields to update');

    final sqlBuffer = StringBuffer('UPDATE users SET \${updates.join(', ')}');

    // WHERE句の構築
    if (_where.isNotEmpty) {
      sqlBuffer.write(' WHERE ');
      final whereClauses = <String>[];
      for (var i = 0; i < _where.length; i++) {
        final condition = _where[i];
        whereClauses.add(condition.toSql(i));
        params.addAll(condition.toParams(i));
      }
      sqlBuffer.write(whereClauses.join(' AND '));
    }

    return db.execute(sqlBuffer.toString(), params: params);
  }
}

class UsersDeleteBuilder extends QueryFuture<int> with FutureMixin<int> {
  final PostgresDatabase db;
  final List<Condition> _where;

  UsersDeleteBuilder(this.db, [List<Condition>? where]) : _where = where ?? [];

  // WHERE句（SelectBuilderと同じ仕組み）
  UsersDeleteBuilder where({Condition? id, Condition? name, Condition? email}) {
    final newConditions = [..._where];
    if (id != null) newConditions.add(id);
    if (name != null) newConditions.add(name);
    if (email != null) newConditions.add(email);
    return UsersDeleteBuilder(db, newConditions);
  }

  @override
  Future<int> execute() {
    final sqlBuffer = StringBuffer('DELETE FROM users');
    final params = <String, dynamic>{};

    // WHERE句の構築
    if (_where.isNotEmpty) {
      sqlBuffer.write(' WHERE ');
      final whereClauses = <String>[];
      for (var i = 0; i < _where.length; i++) {
        final condition = _where[i];
        whereClauses.add(condition.toSql(i));
        params.addAll(condition.toParams(i));
      }
      sqlBuffer.write(whereClauses.join(' AND '));
    }

    return db.execute(sqlBuffer.toString(), params: params);
  }
}

    """;

    buffer.writeln(preset);
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

  void generateQueryBuilder(StringBuffer buffer, String tableName) {
    buffer.writeln('// Query Builder for table: $tableName');
    buffer.writeln('class ${capitalize(tableName)}QueryBuilder {');
    buffer.writeln('  final PostgresDatabase db;');
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

  ({
    String fieldName,
    String columnType, // 'integer', 'varchar' など
    bool isPrimaryKey,
    bool isUnique,
    bool isNullable,
    int? varcharLength,
  })
  analyzeField(String fieldName, Expression expression) {
    bool isPrimaryKey = false;
    bool isUnique = false;
    bool isNullable = false;
    String? columnType;
    int? varcharLength;

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

      if (methodName == 'integer' ||
          methodName == 'varchar' ||
          methodName == 'text' ||
          methodName == 'timestamp') {
        columnType = methodName;

        // varcharの引数を取得
        if (methodName == 'varchar' &&
            method.argumentList.arguments.isNotEmpty) {
          final arg = method.argumentList.arguments.first;
          if (arg is IntegerLiteral) {
            varcharLength = arg.value;
          }
        }
      } else if (methodName == 'primaryKey') {
        isPrimaryKey = true;
      } else if (methodName == 'unique') {
        isUnique = true;
      } else if (methodName == 'nullable') {
        isNullable = true;
      }
    }

    return (
      fieldName: fieldName,
      columnType: columnType ?? 'unknown',
      isPrimaryKey: isPrimaryKey,
      isUnique: isUnique,
      isNullable: isNullable,
      varcharLength: varcharLength,
    );
  }
}

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
