/// SQL comparison operators used in WHERE clauses.
///
/// These operators are used to build conditions for filtering query results.
///
/// ## Example
///
/// ```dart
/// // Using operators through Column methods
/// final condition = column.eq(5);     // column = 5
/// final condition = column.gt(10);    // column > 10
/// final condition = column.inList([1, 2, 3]); // column IN (1, 2, 3)
/// ```
enum ConditionOperator {
  /// Equality operator (=).
  equal('='),

  /// Greater-than operator (>).
  greaterThan('>'),

  /// Less-than operator (<).
  lessThan('<'),

  /// Greater-than-or-equal operator (>=).
  greaterThanOrEqual('>='),

  /// Less-than-or-equal operator (<=).
  lessThanOrEqual('<='),

  /// IN list operator for matching against multiple values.
  inList('IN');

  /// The SQL representation of this operator.
  final String operator;

  const ConditionOperator(this.operator);
}

/// Represents a SQL WHERE condition.
///
/// A condition consists of a column name, an operator, and a value.
/// It is used to filter query results in SELECT, UPDATE, and DELETE statements.
///
/// ## Example
///
/// ```dart
/// // Create a condition directly
/// final condition = Condition('age', ConditionOperator.greaterThan, 18);
///
/// // Or use column methods (preferred)
/// final condition = users.age.gt(18);
/// ```
class Condition {
  /// The name of the column being compared.
  final String column;

  /// The comparison operator.
  final ConditionOperator operator;

  /// The value to compare against.
  final dynamic value;

  /// Creates a new condition with the given [column], [operator], and [value].
  Condition(this.column, this.operator, this.value);

  /// Converts this condition to a SQL string with parameter placeholders.
  ///
  /// The [paramIndex] is used to generate unique parameter names to avoid
  /// conflicts when multiple conditions use the same column.
  ///
  /// Returns a SQL fragment like `column = :column_0` or `column IN (:column_0)`.
  String toSql(int paramIndex) {
    if (operator == ConditionOperator.inList) {
      return '$column ${operator.operator} (:${column}_$paramIndex)';
    }
    return '$column ${operator.operator} :${column}_$paramIndex';
  }

  /// Converts this condition's value to a parameter map.
  ///
  /// The [paramIndex] is used to generate the parameter name matching
  /// the placeholder in [toSql].
  ///
  /// Returns a map like `{'column_0': value}`.
  Map<String, dynamic> toParams(int paramIndex) {
    return {'${column}_$paramIndex': value};
  }
}
