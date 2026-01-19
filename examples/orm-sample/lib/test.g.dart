// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test.dart';

// **************************************************************************
// RecordPgTableGenerator
// **************************************************************************

extension PostgresUsersDatabaseX on PostgresDatabase {
  UsersQueryBuilder get users => UsersQueryBuilder(this);
}

extension PostgresUsersTransactionX on PostgresTransaction {
  UsersQueryBuilder get users => UsersQueryBuilder(this);
}

// Query Builder for table: users
class UsersQueryBuilder {
  final PostgresQueryable db;

  UsersQueryBuilder(this.db);

  UsersSelectBuilder select() {
    return UsersSelectBuilder(
      db,
      UsersSelectConfig(where: null, limit: null, offset: null),
    );
  }

  UsersInsertBuilder insert() {
    return UsersInsertBuilder(db);
  }

  UsersUpdateBuilder update() {
    return UsersUpdateBuilder(db);
  }

  UsersDeleteBuilder delete() {
    return UsersDeleteBuilder(db);
  }
}

typedef UsersRow = ({String id, String name, String email, DateTime createdAt});

class UsersSelectBuilder extends QueryFuture<List<UsersRow>>
    with FutureMixin<List<UsersRow>> {
  final PostgresQueryable db;
  final UsersSelectConfig config;

  UsersSelectBuilder(this.db, this.config);

  @override
  Future<List<UsersRow>> execute() {
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
      sqlBuffer.write(' LIMIT ${config.limit}');
    }

    if (config.offset != null) {
      sqlBuffer.write(' OFFSET ${config.offset}');
    }

    final sql = sqlBuffer.toString();
    return db.query(sql, params: params).then((result) {
      return result.map((row) {
        return (
          id: row['id'] as String,
          name: row['name'] as String,
          email: row['email'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
        );
      }).toList();
    });
  }

  UsersSelectBuilder where({
    Condition? id,
    Condition? name,
    Condition? email,
    Condition? createdAt,
  }) {
    final newConditions = [...config.where];
    if (id != null) newConditions.add(id);
    if (name != null) newConditions.add(name);
    if (email != null) newConditions.add(email);
    if (createdAt != null) newConditions.add(createdAt);

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
    return 'UsersSelectConfig(where: $where, limit: $limit, offset: $offset)';
  }
}

class UsersInsertBuilder extends QueryFuture<int> with FutureMixin<int> {
  final PostgresQueryable db;
  final ({String id, String name, String email, DateTime createdAt})? _values;

  UsersInsertBuilder(
    this.db, {
    ({String id, String name, String email, DateTime createdAt})? values,
  }) : _values = values;

  UsersInsertBuilder values(
    ({String id, String name, String email, DateTime createdAt}) record,
  ) {
    return UsersInsertBuilder(db, values: record);
  }

  @override
  Future<int> execute() {
    if (_values == null) {
      throw StateError('No values set');
    }
    final sql =
        'INSERT INTO users (id, name, email, created_at) VALUES (:id, :name, :email, :created_at)';
    final params = {
      'id': _values.id,
      'name': _values.name,
      'email': _values.email,
      'created_at': _values.createdAt,
    };
    return db.execute(sql, params: params);
  }
}

class UsersUpdateBuilder extends QueryFuture<int> with FutureMixin<int> {
  final PostgresQueryable db;
  final ({String? id, String? name, String? email, DateTime? createdAt})?
  _values;
  final List<Condition> _where;

  UsersUpdateBuilder(
    this.db, {
    ({String? id, String? name, String? email, DateTime? createdAt})? values,
    List<Condition>? where,
  }) : _where = where ?? [],
       _values = values;

  // SET句（更新するカラムを指定）
  UsersUpdateBuilder set(
    ({String? id, String? name, String? email, DateTime? createdAt}) values,
  ) {
    return UsersUpdateBuilder(db, values: values, where: _where);
  }

  // WHERE句（SelectBuilderと同じ仕組み）
  UsersUpdateBuilder where({
    Condition? id,
    Condition? name,
    Condition? email,
    Condition? createdAt,
  }) {
    final newConditions = [..._where];
    if (id != null) newConditions.add(id);
    if (name != null) newConditions.add(name);
    if (email != null) newConditions.add(email);
    if (createdAt != null) newConditions.add(createdAt);
    return UsersUpdateBuilder(db, values: _values, where: newConditions);
  }

  @override
  Future<int> execute() {
    if (_values == null) throw StateError('No values set');

    // SET句の構築
    final updates = <String>[];
    final params = <String, dynamic>{};
    if (_values.id != null) {
      updates.add('id = :set_id');
      params['set_id'] = _values.id;
    }
    if (_values.name != null) {
      updates.add('name = :set_name');
      params['set_name'] = _values.name;
    }
    if (_values.email != null) {
      updates.add('email = :set_email');
      params['set_email'] = _values.email;
    }
    if (_values.createdAt != null) {
      updates.add('created_at = :set_created_at');
      params['set_created_at'] = _values.createdAt;
    }

    if (updates.isEmpty) throw StateError('No fields to update');

    final sqlBuffer = StringBuffer('UPDATE users SET ${updates.join(', ')}');

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
  final PostgresQueryable db;
  final List<Condition> _where;

  UsersDeleteBuilder(this.db, [List<Condition>? where]) : _where = where ?? [];

  // WHERE句（SelectBuilderと同じ仕組み）
  UsersDeleteBuilder where({
    Condition? id,
    Condition? name,
    Condition? email,
    Condition? createdAt,
  }) {
    final newConditions = [..._where];
    if (id != null) newConditions.add(id);
    if (name != null) newConditions.add(name);
    if (email != null) newConditions.add(email);
    if (createdAt != null) newConditions.add(createdAt);
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

extension PostgresPostsDatabaseX on PostgresDatabase {
  PostsQueryBuilder get posts => PostsQueryBuilder(this);
}

extension PostgresPostsTransactionX on PostgresTransaction {
  PostsQueryBuilder get posts => PostsQueryBuilder(this);
}

// Query Builder for table: posts
class PostsQueryBuilder {
  final PostgresQueryable db;

  PostsQueryBuilder(this.db);

  PostsSelectBuilder select() {
    return PostsSelectBuilder(
      db,
      PostsSelectConfig(where: null, limit: null, offset: null),
    );
  }

  PostsInsertBuilder insert() {
    return PostsInsertBuilder(db);
  }

  PostsUpdateBuilder update() {
    return PostsUpdateBuilder(db);
  }

  PostsDeleteBuilder delete() {
    return PostsDeleteBuilder(db);
  }
}

typedef PostsRow = ({
  int id,
  int userId,
  String title,
  String content,
  DateTime createdAt,
});

class PostsSelectBuilder extends QueryFuture<List<PostsRow>>
    with FutureMixin<List<PostsRow>> {
  final PostgresQueryable db;
  final PostsSelectConfig config;

  PostsSelectBuilder(this.db, this.config);

  @override
  Future<List<PostsRow>> execute() {
    final sqlBuffer = StringBuffer('SELECT * FROM posts');
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
      sqlBuffer.write(' LIMIT ${config.limit}');
    }

    if (config.offset != null) {
      sqlBuffer.write(' OFFSET ${config.offset}');
    }

    final sql = sqlBuffer.toString();
    return db.query(sql, params: params).then((result) {
      return result.map((row) {
        return (
          id: int.parse(row['id'] as String),
          userId: int.parse(row['user_id'] as String),
          title: row['title'] as String,
          content: row['content'] as String,
          createdAt: DateTime.parse(row['created_at'] as String),
        );
      }).toList();
    });
  }

  PostsSelectBuilder where({
    Condition? id,
    Condition? userId,
    Condition? title,
    Condition? content,
    Condition? createdAt,
  }) {
    final newConditions = [...config.where];
    if (id != null) newConditions.add(id);
    if (userId != null) newConditions.add(userId);
    if (title != null) newConditions.add(title);
    if (content != null) newConditions.add(content);
    if (createdAt != null) newConditions.add(createdAt);

    return PostsSelectBuilder(
      db,
      PostsSelectConfig(
        where: newConditions,
        limit: config.limit,
        offset: config.offset,
      ),
    );
  }

  PostsSelectBuilder limit(int limit) {
    return PostsSelectBuilder(
      db,
      PostsSelectConfig(
        where: config.where,
        limit: limit,
        offset: config.offset,
      ),
    );
  }

  PostsSelectBuilder offset(int offset) {
    return PostsSelectBuilder(
      db,
      PostsSelectConfig(
        where: config.where,
        limit: config.limit,
        offset: offset,
      ),
    );
  }
}

class PostsSelectConfig {
  final List<Condition> where;
  final int? limit;
  final int? offset;

  PostsSelectConfig({
    required List<Condition>? where,
    required this.limit,
    required this.offset,
  }) : where = where ?? [];

  @override
  String toString() {
    return 'PostsSelectConfig(where: $where, limit: $limit, offset: $offset)';
  }
}

class PostsInsertBuilder extends QueryFuture<int> with FutureMixin<int> {
  final PostgresQueryable db;
  final ({
    int id,
    int userId,
    String title,
    String content,
    DateTime createdAt,
  })?
  _values;

  PostsInsertBuilder(
    this.db, {
    ({int id, int userId, String title, String content, DateTime createdAt})?
    values,
  }) : _values = values;

  PostsInsertBuilder values(
    ({int id, int userId, String title, String content, DateTime createdAt})
    record,
  ) {
    return PostsInsertBuilder(db, values: record);
  }

  @override
  Future<int> execute() {
    if (_values == null) {
      throw StateError('No values set');
    }
    final sql =
        'INSERT INTO posts (id, user_id, title, content, created_at) VALUES (:id, :user_id, :title, :content, :created_at)';
    final params = {
      'id': _values.id,
      'user_id': _values.userId,
      'title': _values.title,
      'content': _values.content,
      'created_at': _values.createdAt,
    };
    return db.execute(sql, params: params);
  }
}

class PostsUpdateBuilder extends QueryFuture<int> with FutureMixin<int> {
  final PostgresQueryable db;
  final ({
    int? id,
    int? userId,
    String? title,
    String? content,
    DateTime? createdAt,
  })?
  _values;
  final List<Condition> _where;

  PostsUpdateBuilder(
    this.db, {
    ({
      int? id,
      int? userId,
      String? title,
      String? content,
      DateTime? createdAt,
    })?
    values,
    List<Condition>? where,
  }) : _where = where ?? [],
       _values = values;

  // SET句（更新するカラムを指定）
  PostsUpdateBuilder set(
    ({
      int? id,
      int? userId,
      String? title,
      String? content,
      DateTime? createdAt,
    })
    values,
  ) {
    return PostsUpdateBuilder(db, values: values, where: _where);
  }

  // WHERE句（SelectBuilderと同じ仕組み）
  PostsUpdateBuilder where({
    Condition? id,
    Condition? userId,
    Condition? title,
    Condition? content,
    Condition? createdAt,
  }) {
    final newConditions = [..._where];
    if (id != null) newConditions.add(id);
    if (userId != null) newConditions.add(userId);
    if (title != null) newConditions.add(title);
    if (content != null) newConditions.add(content);
    if (createdAt != null) newConditions.add(createdAt);
    return PostsUpdateBuilder(db, values: _values, where: newConditions);
  }

  @override
  Future<int> execute() {
    if (_values == null) throw StateError('No values set');

    // SET句の構築
    final updates = <String>[];
    final params = <String, dynamic>{};
    if (_values.id != null) {
      updates.add('id = :set_id');
      params['set_id'] = _values.id;
    }
    if (_values.userId != null) {
      updates.add('user_id = :set_user_id');
      params['set_user_id'] = _values.userId;
    }
    if (_values.title != null) {
      updates.add('title = :set_title');
      params['set_title'] = _values.title;
    }
    if (_values.content != null) {
      updates.add('content = :set_content');
      params['set_content'] = _values.content;
    }
    if (_values.createdAt != null) {
      updates.add('created_at = :set_created_at');
      params['set_created_at'] = _values.createdAt;
    }

    if (updates.isEmpty) throw StateError('No fields to update');

    final sqlBuffer = StringBuffer('UPDATE posts SET ${updates.join(', ')}');

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

class PostsDeleteBuilder extends QueryFuture<int> with FutureMixin<int> {
  final PostgresQueryable db;
  final List<Condition> _where;

  PostsDeleteBuilder(this.db, [List<Condition>? where]) : _where = where ?? [];

  // WHERE句（SelectBuilderと同じ仕組み）
  PostsDeleteBuilder where({
    Condition? id,
    Condition? userId,
    Condition? title,
    Condition? content,
    Condition? createdAt,
  }) {
    final newConditions = [..._where];
    if (id != null) newConditions.add(id);
    if (userId != null) newConditions.add(userId);
    if (title != null) newConditions.add(title);
    if (content != null) newConditions.add(content);
    if (createdAt != null) newConditions.add(createdAt);
    return PostsDeleteBuilder(db, newConditions);
  }

  @override
  Future<int> execute() {
    final sqlBuffer = StringBuffer('DELETE FROM posts');
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
