import 'dart:async';
import 'dart:convert';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:build/build.dart';

/// Phase 1: Collect all @PgTable definitions and output as JSON
class TableCollectorBuilder implements Builder {
  @override
  Map<String, List<String>> get buildExtensions => {
        '.dart': ['.aim_tables.json'],
      };

  @override
  Future<void> build(BuildStep buildStep) async {
    final resolver = buildStep.resolver;

    if (!await resolver.isLibrary(buildStep.inputId)) {
      return;
    }

    final compilationUnit =
        await resolver.compilationUnitFor(buildStep.inputId);

    // AST visitor で @PgTable アノテーション付きのテーブルを収集
    final visitor = _PgTableVisitor();
    compilationUnit.accept(visitor);

    if (visitor.tables.isEmpty) {
      return;
    }

    final tables = <String, dynamic>{};

    for (final entry in visitor.tables.entries) {
      final variableName = entry.key;
      final tableData = entry.value;

      final fields = <Map<String, dynamic>>[];
      for (final field in tableData.record.fields) {
        if (field is NamedExpression) {
          final fieldName = field.name.label.name;
          final fieldInfo = _analyzeField(fieldName, field.expression);
          fields.add(fieldInfo);
        }
      }

      tables[variableName] = {
        'tableName': tableData.tableName,
        'fields': fields,
      };
    }

    if (tables.isNotEmpty) {
      final outputId = buildStep.inputId.changeExtension('.aim_tables.json');
      await buildStep.writeAsString(
        outputId,
        const JsonEncoder.withIndent('  ').convert(tables),
      );
    }
  }

  Map<String, dynamic> _analyzeField(String fieldName, Expression expression) {
    bool isPrimaryKey = false;
    bool isUnique = false;
    bool isNullable = false;
    String? columnType;
    String? columnName;
    String? returnType;
    int? varcharLength;
    String? refTable;
    String? refColumn;

    final methods = <MethodInvocation>[];
    Expression? current = expression;
    while (current is MethodInvocation) {
      methods.add(current);
      current = current.target;
    }

    for (final method in methods.reversed) {
      final methodName = method.methodName.name;

      final column = _matchColumnType(methodName);
      if (column != null) {
        columnType = column['type'];
        returnType = column['dartType'];

        if (method.argumentList.arguments.isNotEmpty) {
          final firstArg = method.argumentList.arguments.first;
          if (firstArg is SimpleStringLiteral) {
            columnName = firstArg.value;
          }
        }

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
        for (final arg in method.argumentList.arguments) {
          if (arg is FunctionExpression) {
            final body = arg.body;
            if (body is ExpressionFunctionBody) {
              final refExpr = body.expression;
              if (refExpr is PropertyAccess) {
                refTable = refExpr.target.toString();
                refColumn = refExpr.propertyName.name;
              }
              if (refExpr is PrefixedIdentifier) {
                refTable = refExpr.prefix.name;
                refColumn = refExpr.identifier.name;
              }
            }
          }
        }
      }
    }

    return {
      'fieldName': fieldName,
      'columnType': columnType ?? 'unknown',
      'columnName': columnName ?? fieldName,
      'returnType': returnType ?? 'dynamic',
      'isPrimaryKey': isPrimaryKey,
      'isUnique': isUnique,
      'isNullable': isNullable,
      'varcharLength': varcharLength,
      'refTable': refTable,
      'refColumn': refColumn,
    };
  }

  Map<String, String>? _matchColumnType(String methodName) {
    const columnTypes = {
      'integer': {'type': 'integer', 'dartType': 'int'},
      'varchar': {'type': 'varchar', 'dartType': 'String'},
      'text': {'type': 'text', 'dartType': 'String'},
      'timestamp': {'type': 'timestamp', 'dartType': 'DateTime'},
      'serial': {'type': 'serial', 'dartType': 'int'},
      'jsonb': {'type': 'jsonb', 'dartType': 'Map<String, dynamic>'},
      'uuid': {'type': 'uuid', 'dartType': 'String'},
    };
    return columnTypes[methodName];
  }
}

/// @PgTable アノテーション付きのテーブル定義を収集する Visitor
class _PgTableVisitor extends RecursiveAstVisitor<void> {
  final Map<String, ({String tableName, RecordLiteral record})> tables = {};

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    // @PgTable アノテーションを探す
    String? tableName;
    for (final annotation in node.metadata) {
      if (annotation.name.name == 'PgTable') {
        // アノテーションの引数からテーブル名を取得
        final args = annotation.arguments?.arguments;
        if (args != null && args.isNotEmpty) {
          final firstArg = args.first;
          if (firstArg is SimpleStringLiteral) {
            tableName = firstArg.value;
          }
        }
        break;
      }
    }

    if (tableName != null) {
      for (final variable in node.variables.variables) {
        if (variable.initializer is RecordLiteral) {
          tables[variable.name.lexeme] = (
            tableName: tableName,
            record: variable.initializer as RecordLiteral,
          );
        }
      }
    }

    super.visitTopLevelVariableDeclaration(node);
  }
}
