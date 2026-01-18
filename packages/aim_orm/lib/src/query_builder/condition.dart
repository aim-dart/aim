enum ConditionOperator {
  equal('='),
  greaterThan('>'),
  lessThan('<'),
  greaterThanOrEqual('>='),
  lessThanOrEqual('<='),
  inList('IN');

  final String operator;

  const ConditionOperator(this.operator);
}

class Condition {
  final String column;
  final ConditionOperator operator;
  final dynamic value;

  Condition(this.column, this.operator, this.value);

  String toSql(int paramIndex) {
    if (operator == ConditionOperator.inList) {
      return '$column ${operator.operator} (:${column}_$paramIndex)';
    }
    return '$column ${operator.operator} :${column}_$paramIndex';
  }

  Map<String, dynamic> toParams(int paramIndex) {
    return {'${column}_$paramIndex': value};
  }
}