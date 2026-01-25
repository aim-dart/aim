// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'input.dart';

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

typedef UsersRow = ({String id, String name});

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
        return (id: row['id'] as String, name: row['name'] as String);
      }).toList();
    });
  }

  UsersSelectBuilder where({Condition? id, Condition? name}) {
    final newConditions = [...config.where];
    if (id != null) newConditions.add(id);
    if (name != null) newConditions.add(name);

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
  final String? _id;
  final String? _name;

  UsersInsertBuilder(this.db, {String? id, String? name})
    : _id = id,
      _name = name;

  UsersInsertBuilder values({required String id, required String name}) {
    return UsersInsertBuilder(db, id: id, name: name);
  }

  @override
  Future<int> execute() {
    if (_id == null) {
      throw StateError('Field `id` is required but not set');
    }
    if (_name == null) {
      throw StateError('Field `name` is required but not set');
    }
    final sql = 'INSERT INTO users (id, name) VALUES (:id, :name)';
    final params = {'id': _id, 'name': _name};
    return db.execute(sql, params: params);
  }
}

class UsersUpdateBuilder extends QueryFuture<int> with FutureMixin<int> {
  final PostgresQueryable db;
  final String? _id;
  final String? _name;
  final List<Condition> _where;

  UsersUpdateBuilder(
    this.db, {
    String? id,
    String? name,
    List<Condition>? where,
  }) : _id = id,
       _name = name,
       _where = where ?? [];

  // SET句（更新するカラムを指定）
  UsersUpdateBuilder set({String? id, String? name}) {
    return UsersUpdateBuilder(db, where: _where, id: id, name: name);
  }

  // WHERE句（SelectBuilderと同じ仕組み）
  UsersUpdateBuilder where({Condition? id, Condition? name}) {
    final newConditions = [..._where];
    if (id != null) newConditions.add(id);
    if (name != null) newConditions.add(name);
    return UsersUpdateBuilder(db, where: newConditions, id: _id, name: _name);
  }

  @override
  Future<int> execute() {
    // SET句の構築
    final updates = <String>[];
    final params = <String, dynamic>{};
    if (_id != null) {
      updates.add('id = :set_id');
      params['set_id'] = _id;
    }
    if (_name != null) {
      updates.add('name = :set_name');
      params['set_name'] = _name;
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
  UsersDeleteBuilder where({Condition? id, Condition? name}) {
    final newConditions = [..._where];
    if (id != null) newConditions.add(id);
    if (name != null) newConditions.add(name);
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

typedef PostsRow = ({String id, String title, String userId});

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
          id: row['id'] as String,
          title: row['title'] as String,
          userId: row['user_id'] as String,
        );
      }).toList();
    });
  }

  PostsWithUserSelectBuilder withUser() {
    return PostsWithUserSelectBuilder(
      db,
      PostsWithUserSelectConfig(
        where: config.where,
        limit: config.limit,
        offset: config.offset,
      ),
    );
  }

  PostsSelectBuilder where({
    Condition? id,
    Condition? title,
    Condition? userId,
  }) {
    final newConditions = [...config.where];
    if (id != null) newConditions.add(id);
    if (title != null) newConditions.add(title);
    if (userId != null) newConditions.add(userId);

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
  final String? _id;
  final String? _title;
  final String? _userId;

  PostsInsertBuilder(this.db, {String? id, String? title, String? userId})
    : _id = id,
      _title = title,
      _userId = userId;

  PostsInsertBuilder values({
    required String id,
    required String title,
    required String userId,
  }) {
    return PostsInsertBuilder(db, id: id, title: title, userId: userId);
  }

  @override
  Future<int> execute() {
    if (_id == null) {
      throw StateError('Field `id` is required but not set');
    }
    if (_title == null) {
      throw StateError('Field `title` is required but not set');
    }
    if (_userId == null) {
      throw StateError('Field `userId` is required but not set');
    }
    final sql =
        'INSERT INTO posts (id, title, user_id) VALUES (:id, :title, :user_id)';
    final params = {'id': _id, 'title': _title, 'user_id': _userId};
    return db.execute(sql, params: params);
  }
}

class PostsUpdateBuilder extends QueryFuture<int> with FutureMixin<int> {
  final PostgresQueryable db;
  final String? _id;
  final String? _title;
  final String? _userId;
  final List<Condition> _where;

  PostsUpdateBuilder(
    this.db, {
    String? id,
    String? title,
    String? userId,
    List<Condition>? where,
  }) : _id = id,
       _title = title,
       _userId = userId,
       _where = where ?? [];

  // SET句（更新するカラムを指定）
  PostsUpdateBuilder set({String? id, String? title, String? userId}) {
    return PostsUpdateBuilder(
      db,
      where: _where,
      id: id,
      title: title,
      userId: userId,
    );
  }

  // WHERE句（SelectBuilderと同じ仕組み）
  PostsUpdateBuilder where({
    Condition? id,
    Condition? title,
    Condition? userId,
  }) {
    final newConditions = [..._where];
    if (id != null) newConditions.add(id);
    if (title != null) newConditions.add(title);
    if (userId != null) newConditions.add(userId);
    return PostsUpdateBuilder(
      db,
      where: newConditions,
      id: _id,
      title: _title,
      userId: _userId,
    );
  }

  @override
  Future<int> execute() {
    // SET句の構築
    final updates = <String>[];
    final params = <String, dynamic>{};
    if (_id != null) {
      updates.add('id = :set_id');
      params['set_id'] = _id;
    }
    if (_title != null) {
      updates.add('title = :set_title');
      params['set_title'] = _title;
    }
    if (_userId != null) {
      updates.add('user_id = :set_user_id');
      params['set_user_id'] = _userId;
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
    Condition? title,
    Condition? userId,
  }) {
    final newConditions = [..._where];
    if (id != null) newConditions.add(id);
    if (title != null) newConditions.add(title);
    if (userId != null) newConditions.add(userId);
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

typedef PostsWithUserRow = ({PostsRow post, UsersRow user});

class PostsWithUserSelectConfig {
  final List<Condition> where;
  final int? limit;
  final int? offset;

  PostsWithUserSelectConfig({
    required List<Condition>? where,
    required this.limit,
    required this.offset,
  }) : where = where ?? [];
}

class PostsWithUserSelectBuilder extends QueryFuture<List<PostsWithUserRow>>
    with FutureMixin<List<PostsWithUserRow>> {
  final PostgresQueryable db;
  final PostsWithUserSelectConfig config;

  PostsWithUserSelectBuilder(this.db, this.config);

  @override
  Future<List<PostsWithUserRow>> execute() {
    final sqlBuffer = StringBuffer(
      'SELECT posts.id AS posts_id, posts.title AS posts_title, posts.user_id AS posts_user_id, users.id AS users_id, users.name AS users_name FROM posts',
    );
    sqlBuffer.write(' INNER JOIN users ON posts.user_id = users.id');
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
    return db.query(sqlBuffer.toString(), params: params).then((result) {
      return result.map((row) {
        return (
          post: (
            id: row['posts_id'] as String,
            title: row['posts_title'] as String,
            userId: row['posts_user_id'] as String,
          ),
          user: (
            id: row['users_id'] as String,
            name: row['users_name'] as String,
          ),
        );
      }).toList();
    });
  }

  PostsWithUserSelectBuilder where({
    Condition? id,
    Condition? title,
    Condition? userId,
  }) {
    final newConditions = [...config.where];
    if (id != null) newConditions.add(id);
    if (title != null) newConditions.add(title);
    if (userId != null) newConditions.add(userId);
    return PostsWithUserSelectBuilder(
      db,
      PostsWithUserSelectConfig(
        where: newConditions,
        limit: config.limit,
        offset: config.offset,
      ),
    );
  }

  PostsWithUserSelectBuilder limit(int limit) {
    return PostsWithUserSelectBuilder(
      db,
      PostsWithUserSelectConfig(
        where: config.where,
        limit: limit,
        offset: config.offset,
      ),
    );
  }

  PostsWithUserSelectBuilder offset(int offset) {
    return PostsWithUserSelectBuilder(
      db,
      PostsWithUserSelectConfig(
        where: config.where,
        limit: config.limit,
        offset: offset,
      ),
    );
  }
}
