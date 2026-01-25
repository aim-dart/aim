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

extension PostgresArticlesDatabaseX on PostgresDatabase {
  ArticlesQueryBuilder get articles => ArticlesQueryBuilder(this);
}

extension PostgresArticlesTransactionX on PostgresTransaction {
  ArticlesQueryBuilder get articles => ArticlesQueryBuilder(this);
}

// Query Builder for table: articles
class ArticlesQueryBuilder {
  final PostgresQueryable db;

  ArticlesQueryBuilder(this.db);

  ArticlesSelectBuilder select() {
    return ArticlesSelectBuilder(
      db,
      ArticlesSelectConfig(where: null, limit: null, offset: null),
    );
  }

  ArticlesInsertBuilder insert() {
    return ArticlesInsertBuilder(db);
  }

  ArticlesUpdateBuilder update() {
    return ArticlesUpdateBuilder(db);
  }

  ArticlesDeleteBuilder delete() {
    return ArticlesDeleteBuilder(db);
  }
}

typedef ArticlesRow = ({String id, String title, String? authorId});

class ArticlesSelectBuilder extends QueryFuture<List<ArticlesRow>>
    with FutureMixin<List<ArticlesRow>> {
  final PostgresQueryable db;
  final ArticlesSelectConfig config;

  ArticlesSelectBuilder(this.db, this.config);

  @override
  Future<List<ArticlesRow>> execute() {
    final sqlBuffer = StringBuffer('SELECT * FROM articles');
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
          authorId: row['author_id'] as String?,
        );
      }).toList();
    });
  }

  ArticlesWithAuthorSelectBuilder withAuthor() {
    return ArticlesWithAuthorSelectBuilder(
      db,
      ArticlesWithAuthorSelectConfig(
        where: config.where,
        limit: config.limit,
        offset: config.offset,
      ),
    );
  }

  ArticlesSelectBuilder where({
    Condition? id,
    Condition? title,
    Condition? authorId,
  }) {
    final newConditions = [...config.where];
    if (id != null) newConditions.add(id);
    if (title != null) newConditions.add(title);
    if (authorId != null) newConditions.add(authorId);

    return ArticlesSelectBuilder(
      db,
      ArticlesSelectConfig(
        where: newConditions,
        limit: config.limit,
        offset: config.offset,
      ),
    );
  }

  ArticlesSelectBuilder limit(int limit) {
    return ArticlesSelectBuilder(
      db,
      ArticlesSelectConfig(
        where: config.where,
        limit: limit,
        offset: config.offset,
      ),
    );
  }

  ArticlesSelectBuilder offset(int offset) {
    return ArticlesSelectBuilder(
      db,
      ArticlesSelectConfig(
        where: config.where,
        limit: config.limit,
        offset: offset,
      ),
    );
  }
}

class ArticlesSelectConfig {
  final List<Condition> where;
  final int? limit;
  final int? offset;

  ArticlesSelectConfig({
    required List<Condition>? where,
    required this.limit,
    required this.offset,
  }) : where = where ?? [];

  @override
  String toString() {
    return 'ArticlesSelectConfig(where: $where, limit: $limit, offset: $offset)';
  }
}

class ArticlesInsertBuilder extends QueryFuture<int> with FutureMixin<int> {
  final PostgresQueryable db;
  final String? _id;
  final String? _title;
  final String? _authorId;

  ArticlesInsertBuilder(this.db, {String? id, String? title, String? authorId})
    : _id = id,
      _title = title,
      _authorId = authorId;

  ArticlesInsertBuilder values({
    required String id,
    required String title,
    String? authorId,
  }) {
    return ArticlesInsertBuilder(db, id: id, title: title, authorId: authorId);
  }

  @override
  Future<int> execute() {
    if (_id == null) {
      throw StateError('Field `id` is required but not set');
    }
    if (_title == null) {
      throw StateError('Field `title` is required but not set');
    }
    final sql =
        'INSERT INTO articles (id, title, author_id) VALUES (:id, :title, :author_id)';
    final params = {'id': _id, 'title': _title, 'author_id': _authorId};
    return db.execute(sql, params: params);
  }
}

class ArticlesUpdateBuilder extends QueryFuture<int> with FutureMixin<int> {
  final PostgresQueryable db;
  final String? _id;
  final String? _title;
  final String? _authorId;
  final List<Condition> _where;

  ArticlesUpdateBuilder(
    this.db, {
    String? id,
    String? title,
    String? authorId,
    List<Condition>? where,
  }) : _id = id,
       _title = title,
       _authorId = authorId,
       _where = where ?? [];

  // SET句（更新するカラムを指定）
  ArticlesUpdateBuilder set({String? id, String? title, String? authorId}) {
    return ArticlesUpdateBuilder(
      db,
      where: _where,
      id: id,
      title: title,
      authorId: authorId,
    );
  }

  // WHERE句（SelectBuilderと同じ仕組み）
  ArticlesUpdateBuilder where({
    Condition? id,
    Condition? title,
    Condition? authorId,
  }) {
    final newConditions = [..._where];
    if (id != null) newConditions.add(id);
    if (title != null) newConditions.add(title);
    if (authorId != null) newConditions.add(authorId);
    return ArticlesUpdateBuilder(
      db,
      where: newConditions,
      id: _id,
      title: _title,
      authorId: _authorId,
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
    if (_authorId != null) {
      updates.add('author_id = :set_author_id');
      params['set_author_id'] = _authorId;
    }

    if (updates.isEmpty) throw StateError('No fields to update');

    final sqlBuffer = StringBuffer('UPDATE articles SET ${updates.join(', ')}');

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

class ArticlesDeleteBuilder extends QueryFuture<int> with FutureMixin<int> {
  final PostgresQueryable db;
  final List<Condition> _where;

  ArticlesDeleteBuilder(this.db, [List<Condition>? where])
    : _where = where ?? [];

  // WHERE句（SelectBuilderと同じ仕組み）
  ArticlesDeleteBuilder where({
    Condition? id,
    Condition? title,
    Condition? authorId,
  }) {
    final newConditions = [..._where];
    if (id != null) newConditions.add(id);
    if (title != null) newConditions.add(title);
    if (authorId != null) newConditions.add(authorId);
    return ArticlesDeleteBuilder(db, newConditions);
  }

  @override
  Future<int> execute() {
    final sqlBuffer = StringBuffer('DELETE FROM articles');
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

typedef ArticlesWithAuthorRow = ({ArticlesRow article, UsersRow? author});

class ArticlesWithAuthorSelectConfig {
  final List<Condition> where;
  final int? limit;
  final int? offset;

  ArticlesWithAuthorSelectConfig({
    required List<Condition>? where,
    required this.limit,
    required this.offset,
  }) : where = where ?? [];
}

class ArticlesWithAuthorSelectBuilder
    extends QueryFuture<List<ArticlesWithAuthorRow>>
    with FutureMixin<List<ArticlesWithAuthorRow>> {
  final PostgresQueryable db;
  final ArticlesWithAuthorSelectConfig config;

  ArticlesWithAuthorSelectBuilder(this.db, this.config);

  @override
  Future<List<ArticlesWithAuthorRow>> execute() {
    final sqlBuffer = StringBuffer(
      'SELECT articles.id AS articles_id, articles.title AS articles_title, articles.author_id AS articles_author_id, users.id AS users_id, users.name AS users_name FROM articles',
    );
    sqlBuffer.write(' LEFT JOIN users ON articles.author_id = users.id');
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
          article: (
            id: row['articles_id'] as String,
            title: row['articles_title'] as String,
            authorId: row['articles_author_id'] as String?,
          ),
          author: row['users_id'] == null
              ? null
              : (
                  id: row['users_id'] as String,
                  name: row['users_name'] as String,
                ),
        );
      }).toList();
    });
  }

  ArticlesWithAuthorSelectBuilder where({
    Condition? id,
    Condition? title,
    Condition? authorId,
  }) {
    final newConditions = [...config.where];
    if (id != null) newConditions.add(id);
    if (title != null) newConditions.add(title);
    if (authorId != null) newConditions.add(authorId);
    return ArticlesWithAuthorSelectBuilder(
      db,
      ArticlesWithAuthorSelectConfig(
        where: newConditions,
        limit: config.limit,
        offset: config.offset,
      ),
    );
  }

  ArticlesWithAuthorSelectBuilder limit(int limit) {
    return ArticlesWithAuthorSelectBuilder(
      db,
      ArticlesWithAuthorSelectConfig(
        where: config.where,
        limit: limit,
        offset: config.offset,
      ),
    );
  }

  ArticlesWithAuthorSelectBuilder offset(int offset) {
    return ArticlesWithAuthorSelectBuilder(
      db,
      ArticlesWithAuthorSelectConfig(
        where: config.where,
        limit: config.limit,
        offset: offset,
      ),
    );
  }
}
