import 'package:aim_orm/aim_orm.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

class TableGenerator extends GeneratorForAnnotation<Table> {
  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    final tableName = annotation.peek('name')?.stringValue;

    if (tableName == null || tableName.isEmpty) {
      throw InvalidGenerationSourceError(
        'The `name` parameter in `@Table` annotation cannot be null or empty.',
        element: element,
      );
    }

    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        'Generator cannot target `${element.name}`. '
        'Annotation can only be applied to classes.',
        element: element,
      );
    }

    final superType = element.supertype;
    if (superType == null || superType.element.name != 'PgTable') {
      throw InvalidGenerationSourceError(
        'Class `${element.name}` must extend `PgTable` to use the `@Table` annotation.',
        element: element,
      );
    }

    // ASTにアクセスするためにクラス宣言を取得
    final classDeclaration = await _getClassDeclaration(buildStep, element);
    if (classDeclaration == null) {
      throw InvalidGenerationSourceError(
        'Could not find class declaration for `${element.name}`.',
        element: element,
      );
    }

    final result = switch (superType.element.name) {
      'PgTable' => pgTableParser(tableName, element, classDeclaration, buildStep),
      _ => throw InvalidGenerationSourceError(
        'Class `${element.name}` has unsupported superclass `${superType.element.name}` for `@Table` annotation.',
        element: element,
      ),
    };
    return result;
  }

  /// クラス宣言のASTノードを取得
  Future<ClassDeclaration?> _getClassDeclaration(
    BuildStep buildStep,
    ClassElement classElement,
  ) async {
    final resolver = buildStep.resolver;

    // 現在のファイルのCompilationUnitを取得
    final compilationUnit = await resolver.compilationUnitFor(buildStep.inputId);

    // クラス宣言を探す
    for (final declaration in compilationUnit.declarations) {
      if (declaration is ClassDeclaration &&
          declaration.name.lexeme == classElement.name) {
        return declaration;
      }
    }

    return null;
  }
}

String pgTableParser(
  String tableName,
  ClassElement element,
  ClassDeclaration classDeclaration,
  BuildStep buildStep,
) {
  final className = element.name!;

  // カラム情報を収集
  final columns = <ColumnInfo>[];
  for (final member in classDeclaration.members) {
    if (member is MethodDeclaration && member.isGetter) {
      final columnInfo = _parseColumnGetter(member);
      if (columnInfo != null) {
        columns.add(columnInfo);
      }
    }
  }

  final buffer = StringBuffer();

  // $XxxTableクラス
  buffer.writeln('class \$$className extends $className {');
  buffer.writeln('  @override');
  buffer.writeln('  String get tableName => \'$tableName\';');
  buffer.writeln();

  // 各カラムの定義
  for (final column in columns) {
    final columnDef = _generateColumnDefinition(column);
    buffer.writeln('  @override');
    buffer.writeln('  $columnDef');
  }

  buffer.writeln();
  buffer.writeln('  @override');
  buffer.writeln('  List<Column> get columns => [');
  for (final column in columns) {
    buffer.writeln('    ${column.name},');
  }
  buffer.writeln('  ];');
  buffer.writeln('}');
  buffer.writeln();

  // テーブルインスタンス
  final instanceName = _toSnakeCase(className);
  buffer.writeln('/// Table instance for $className');
  buffer.writeln('final $instanceName = \$$className();');
  buffer.writeln();

  // Row型のtypedef
  buffer.writeln('/// Row type for $className');
  buffer.writeln('typedef ${className}Row = ({');
  for (final column in columns) {
    final dartType = _columnToDartType(column);
    buffer.writeln('  $dartType ${column.name},');
  }
  buffer.writeln('});');

  return buffer.toString();
}

/// カラム定義を生成
String _generateColumnDefinition(ColumnInfo column) {
  final columnClass = _methodToColumnClass(column.typeMethod);
  final params = <String>[];

  // 型引数の処理（例：varchar(255) → length: 255）
  if (column.typeMethod == 'varchar' && column.typeArguments.isNotEmpty) {
    params.add('length: ${column.typeArguments.first}');
  }

  // 修飾子の処理
  if (column.modifiers.contains('primaryKey')) {
    params.add('isPrimaryKey: true');
  }
  if (column.modifiers.contains('unique')) {
    params.add('isUnique: true');
  }
  if (column.modifiers.contains('nullable')) {
    params.add('isNullable: true');
  }

  final paramsStr = params.isEmpty ? '' : params.join(', ');
  return 'final ${column.name} = $columnClass($paramsStr);';
}

/// メソッド名からColumnクラス名に変換
String _methodToColumnClass(String method) {
  return switch (method) {
    'integer' => 'IntegerColumn',
    'varchar' => 'VarcharColumn',
    'text' => 'TextColumn',
    'timestamp' => 'TimestampColumn',
    'serial' => 'SerialColumn',
    'jsonb' => 'JsonbColumn',
    'uuid' => 'UuidColumn',
    _ => '${_capitalize(method)}Column',
  };
}

/// カラム情報からDart型を推測
String _columnToDartType(ColumnInfo column) {
  final nullable = column.modifiers.contains('nullable') ? '?' : '';

  return switch (column.typeMethod) {
    'integer' || 'serial' => 'int$nullable',
    'varchar' || 'text' || 'uuid' => 'String$nullable',
    'timestamp' => 'DateTime$nullable',
    'jsonb' => 'Map<String, dynamic>$nullable',
    _ => 'dynamic$nullable',
  };
}

/// 文字列をスネークケースに変換
String _toSnakeCase(String text) {
  return text
      .replaceAllMapped(RegExp(r'[A-Z]'), (match) => '_${match.group(0)!.toLowerCase()}')
      .replaceFirst(RegExp(r'^_'), '');
}

/// 先頭文字を大文字に
String _capitalize(String text) {
  if (text.isEmpty) return text;
  return text[0].toUpperCase() + text.substring(1);
}

/// カラム情報を保持するクラス
class ColumnInfo {
  final String name;
  final String typeMethod;
  final List<String> typeArguments;
  final List<String> modifiers;

  ColumnInfo({
    required this.name,
    required this.typeMethod,
    required this.typeArguments,
    required this.modifiers,
  });
}

/// ゲッターからカラム情報を解析
ColumnInfo? _parseColumnGetter(MethodDeclaration getter) {
  final name = getter.name.lexeme;
  final body = getter.body;

  if (body is! ExpressionFunctionBody) {
    return null;
  }

  final calls = _extractDetailedMethodCalls(body.expression);

  if (calls.isEmpty) {
    return null;
  }

  // 最初の呼び出しが型定義（integer(), varchar()など）
  final typeCall = calls.first;

  // それ以降が修飾子（primaryKey(), unique()など）
  final modifierCalls = calls.skip(1).toList();

  return ColumnInfo(
    name: name,
    typeMethod: typeCall.methodName,
    typeArguments: typeCall.arguments,
    modifiers: modifierCalls.map((c) => c.methodName).toList(),
  );
}

/// メソッド呼び出しの詳細情報
class MethodCallInfo {
  final String methodName;
  final List<String> arguments;

  MethodCallInfo({
    required this.methodName,
    required this.arguments,
  });
}

/// メソッド呼び出しチェーンを詳細に抽出
List<MethodCallInfo> _extractDetailedMethodCalls(Expression? expr) {
  final calls = <MethodCallInfo>[];

  void visit(Expression? e) {
    if (e == null) return;

    if (e is MethodInvocation) {
      // 左側（target）を先に処理
      visit(e.target);

      // 引数を抽出
      final args = <String>[];
      for (final arg in e.argumentList.arguments) {
        args.add(arg.toString());
      }

      calls.add(MethodCallInfo(
        methodName: e.methodName.name,
        arguments: args,
      ));
    }
  }

  visit(expr);
  return calls;
}
