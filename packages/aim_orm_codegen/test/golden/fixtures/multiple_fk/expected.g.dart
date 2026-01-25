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

typedef PostsRow = ({String id, String title});

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
        return (id: row['id'] as String, title: row['title'] as String);
      }).toList();
    });
  }

  PostsSelectBuilder where({Condition? id, Condition? title}) {
    final newConditions = [...config.where];
    if (id != null) newConditions.add(id);
    if (title != null) newConditions.add(title);

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

  PostsInsertBuilder(this.db, {String? id, String? title})
    : _id = id,
      _title = title;

  PostsInsertBuilder values({required String id, required String title}) {
    return PostsInsertBuilder(db, id: id, title: title);
  }

  @override
  Future<int> execute() {
    if (_id == null) {
      throw StateError('Field `id` is required but not set');
    }
    if (_title == null) {
      throw StateError('Field `title` is required but not set');
    }
    final sql = 'INSERT INTO posts (id, title) VALUES (:id, :title)';
    final params = {'id': _id, 'title': _title};
    return db.execute(sql, params: params);
  }
}

class PostsUpdateBuilder extends QueryFuture<int> with FutureMixin<int> {
  final PostgresQueryable db;
  final String? _id;
  final String? _title;
  final List<Condition> _where;

  PostsUpdateBuilder(
    this.db, {
    String? id,
    String? title,
    List<Condition>? where,
  }) : _id = id,
       _title = title,
       _where = where ?? [];

  // SET句（更新するカラムを指定）
  PostsUpdateBuilder set({String? id, String? title}) {
    return PostsUpdateBuilder(db, where: _where, id: id, title: title);
  }

  // WHERE句（SelectBuilderと同じ仕組み）
  PostsUpdateBuilder where({Condition? id, Condition? title}) {
    final newConditions = [..._where];
    if (id != null) newConditions.add(id);
    if (title != null) newConditions.add(title);
    return PostsUpdateBuilder(db, where: newConditions, id: _id, title: _title);
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
  PostsDeleteBuilder where({Condition? id, Condition? title}) {
    final newConditions = [..._where];
    if (id != null) newConditions.add(id);
    if (title != null) newConditions.add(title);
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

extension PostgresCommentsDatabaseX on PostgresDatabase {
  CommentsQueryBuilder get comments => CommentsQueryBuilder(this);
}

extension PostgresCommentsTransactionX on PostgresTransaction {
  CommentsQueryBuilder get comments => CommentsQueryBuilder(this);
}

// Query Builder for table: comments
class CommentsQueryBuilder {
  final PostgresQueryable db;

  CommentsQueryBuilder(this.db);

  CommentsSelectBuilder select() {
    return CommentsSelectBuilder(
      db,
      CommentsSelectConfig(where: null, limit: null, offset: null),
    );
  }

  CommentsInsertBuilder insert() {
    return CommentsInsertBuilder(db);
  }

  CommentsUpdateBuilder update() {
    return CommentsUpdateBuilder(db);
  }

  CommentsDeleteBuilder delete() {
    return CommentsDeleteBuilder(db);
  }
}

typedef CommentsRow = ({
  String id,
  String content,
  String postId,
  String userId,
});

class CommentsSelectBuilder extends QueryFuture<List<CommentsRow>>
    with FutureMixin<List<CommentsRow>> {
  final PostgresQueryable db;
  final CommentsSelectConfig config;

  CommentsSelectBuilder(this.db, this.config);

  @override
  Future<List<CommentsRow>> execute() {
    final sqlBuffer = StringBuffer('SELECT * FROM comments');
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
          content: row['content'] as String,
          postId: row['post_id'] as String,
          userId: row['user_id'] as String,
        );
      }).toList();
    });
  }

  CommentsWithPostSelectBuilder withPost() {
    return CommentsWithPostSelectBuilder(
      db,
      CommentsWithPostSelectConfig(
        where: config.where,
        limit: config.limit,
        offset: config.offset,
      ),
    );
  }

  CommentsWithUserSelectBuilder withUser() {
    return CommentsWithUserSelectBuilder(
      db,
      CommentsWithUserSelectConfig(
        where: config.where,
        limit: config.limit,
        offset: config.offset,
      ),
    );
  }

  CommentsSelectBuilder where({
    Condition? id,
    Condition? content,
    Condition? postId,
    Condition? userId,
  }) {
    final newConditions = [...config.where];
    if (id != null) newConditions.add(id);
    if (content != null) newConditions.add(content);
    if (postId != null) newConditions.add(postId);
    if (userId != null) newConditions.add(userId);

    return CommentsSelectBuilder(
      db,
      CommentsSelectConfig(
        where: newConditions,
        limit: config.limit,
        offset: config.offset,
      ),
    );
  }

  CommentsSelectBuilder limit(int limit) {
    return CommentsSelectBuilder(
      db,
      CommentsSelectConfig(
        where: config.where,
        limit: limit,
        offset: config.offset,
      ),
    );
  }

  CommentsSelectBuilder offset(int offset) {
    return CommentsSelectBuilder(
      db,
      CommentsSelectConfig(
        where: config.where,
        limit: config.limit,
        offset: offset,
      ),
    );
  }
}

class CommentsSelectConfig {
  final List<Condition> where;
  final int? limit;
  final int? offset;

  CommentsSelectConfig({
    required List<Condition>? where,
    required this.limit,
    required this.offset,
  }) : where = where ?? [];

  @override
  String toString() {
    return 'CommentsSelectConfig(where: $where, limit: $limit, offset: $offset)';
  }
}

class CommentsInsertBuilder extends QueryFuture<int> with FutureMixin<int> {
  final PostgresQueryable db;
  final String? _id;
  final String? _content;
  final String? _postId;
  final String? _userId;

  CommentsInsertBuilder(
    this.db, {
    String? id,
    String? content,
    String? postId,
    String? userId,
  }) : _id = id,
       _content = content,
       _postId = postId,
       _userId = userId;

  CommentsInsertBuilder values({
    required String id,
    required String content,
    required String postId,
    required String userId,
  }) {
    return CommentsInsertBuilder(
      db,
      id: id,
      content: content,
      postId: postId,
      userId: userId,
    );
  }

  @override
  Future<int> execute() {
    if (_id == null) {
      throw StateError('Field `id` is required but not set');
    }
    if (_content == null) {
      throw StateError('Field `content` is required but not set');
    }
    if (_postId == null) {
      throw StateError('Field `postId` is required but not set');
    }
    if (_userId == null) {
      throw StateError('Field `userId` is required but not set');
    }
    final sql =
        'INSERT INTO comments (id, content, post_id, user_id) VALUES (:id, :content, :post_id, :user_id)';
    final params = {
      'id': _id,
      'content': _content,
      'post_id': _postId,
      'user_id': _userId,
    };
    return db.execute(sql, params: params);
  }
}

class CommentsUpdateBuilder extends QueryFuture<int> with FutureMixin<int> {
  final PostgresQueryable db;
  final String? _id;
  final String? _content;
  final String? _postId;
  final String? _userId;
  final List<Condition> _where;

  CommentsUpdateBuilder(
    this.db, {
    String? id,
    String? content,
    String? postId,
    String? userId,
    List<Condition>? where,
  }) : _id = id,
       _content = content,
       _postId = postId,
       _userId = userId,
       _where = where ?? [];

  // SET句（更新するカラムを指定）
  CommentsUpdateBuilder set({
    String? id,
    String? content,
    String? postId,
    String? userId,
  }) {
    return CommentsUpdateBuilder(
      db,
      where: _where,
      id: id,
      content: content,
      postId: postId,
      userId: userId,
    );
  }

  // WHERE句（SelectBuilderと同じ仕組み）
  CommentsUpdateBuilder where({
    Condition? id,
    Condition? content,
    Condition? postId,
    Condition? userId,
  }) {
    final newConditions = [..._where];
    if (id != null) newConditions.add(id);
    if (content != null) newConditions.add(content);
    if (postId != null) newConditions.add(postId);
    if (userId != null) newConditions.add(userId);
    return CommentsUpdateBuilder(
      db,
      where: newConditions,
      id: _id,
      content: _content,
      postId: _postId,
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
    if (_content != null) {
      updates.add('content = :set_content');
      params['set_content'] = _content;
    }
    if (_postId != null) {
      updates.add('post_id = :set_post_id');
      params['set_post_id'] = _postId;
    }
    if (_userId != null) {
      updates.add('user_id = :set_user_id');
      params['set_user_id'] = _userId;
    }

    if (updates.isEmpty) throw StateError('No fields to update');

    final sqlBuffer = StringBuffer('UPDATE comments SET ${updates.join(', ')}');

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

class CommentsDeleteBuilder extends QueryFuture<int> with FutureMixin<int> {
  final PostgresQueryable db;
  final List<Condition> _where;

  CommentsDeleteBuilder(this.db, [List<Condition>? where])
    : _where = where ?? [];

  // WHERE句（SelectBuilderと同じ仕組み）
  CommentsDeleteBuilder where({
    Condition? id,
    Condition? content,
    Condition? postId,
    Condition? userId,
  }) {
    final newConditions = [..._where];
    if (id != null) newConditions.add(id);
    if (content != null) newConditions.add(content);
    if (postId != null) newConditions.add(postId);
    if (userId != null) newConditions.add(userId);
    return CommentsDeleteBuilder(db, newConditions);
  }

  @override
  Future<int> execute() {
    final sqlBuffer = StringBuffer('DELETE FROM comments');
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

typedef CommentsWithPostRow = ({CommentsRow comment, PostsRow post});

class CommentsWithPostSelectConfig {
  final List<Condition> where;
  final int? limit;
  final int? offset;

  CommentsWithPostSelectConfig({
    required List<Condition>? where,
    required this.limit,
    required this.offset,
  }) : where = where ?? [];
}

class CommentsWithPostSelectBuilder
    extends QueryFuture<List<CommentsWithPostRow>>
    with FutureMixin<List<CommentsWithPostRow>> {
  final PostgresQueryable db;
  final CommentsWithPostSelectConfig config;

  CommentsWithPostSelectBuilder(this.db, this.config);

  @override
  Future<List<CommentsWithPostRow>> execute() {
    final sqlBuffer = StringBuffer(
      'SELECT comments.id AS comments_id, comments.content AS comments_content, comments.post_id AS comments_post_id, comments.user_id AS comments_user_id, posts.id AS posts_id, posts.title AS posts_title FROM comments',
    );
    sqlBuffer.write(' INNER JOIN posts ON comments.post_id = posts.id');
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
          comment: (
            id: row['comments_id'] as String,
            content: row['comments_content'] as String,
            postId: row['comments_post_id'] as String,
            userId: row['comments_user_id'] as String,
          ),
          post: (
            id: row['posts_id'] as String,
            title: row['posts_title'] as String,
          ),
        );
      }).toList();
    });
  }

  CommentsWithPostWithUserSelectBuilder withUser() {
    return CommentsWithPostWithUserSelectBuilder(
      db,
      CommentsWithPostWithUserSelectConfig(
        where: config.where,
        limit: config.limit,
        offset: config.offset,
      ),
    );
  }

  CommentsWithPostSelectBuilder where({
    Condition? id,
    Condition? content,
    Condition? postId,
    Condition? userId,
  }) {
    final newConditions = [...config.where];
    if (id != null) newConditions.add(id);
    if (content != null) newConditions.add(content);
    if (postId != null) newConditions.add(postId);
    if (userId != null) newConditions.add(userId);
    return CommentsWithPostSelectBuilder(
      db,
      CommentsWithPostSelectConfig(
        where: newConditions,
        limit: config.limit,
        offset: config.offset,
      ),
    );
  }

  CommentsWithPostSelectBuilder limit(int limit) {
    return CommentsWithPostSelectBuilder(
      db,
      CommentsWithPostSelectConfig(
        where: config.where,
        limit: limit,
        offset: config.offset,
      ),
    );
  }

  CommentsWithPostSelectBuilder offset(int offset) {
    return CommentsWithPostSelectBuilder(
      db,
      CommentsWithPostSelectConfig(
        where: config.where,
        limit: config.limit,
        offset: offset,
      ),
    );
  }
}

typedef CommentsWithUserRow = ({CommentsRow comment, UsersRow user});

class CommentsWithUserSelectConfig {
  final List<Condition> where;
  final int? limit;
  final int? offset;

  CommentsWithUserSelectConfig({
    required List<Condition>? where,
    required this.limit,
    required this.offset,
  }) : where = where ?? [];
}

class CommentsWithUserSelectBuilder
    extends QueryFuture<List<CommentsWithUserRow>>
    with FutureMixin<List<CommentsWithUserRow>> {
  final PostgresQueryable db;
  final CommentsWithUserSelectConfig config;

  CommentsWithUserSelectBuilder(this.db, this.config);

  @override
  Future<List<CommentsWithUserRow>> execute() {
    final sqlBuffer = StringBuffer(
      'SELECT comments.id AS comments_id, comments.content AS comments_content, comments.post_id AS comments_post_id, comments.user_id AS comments_user_id, users.id AS users_id, users.name AS users_name FROM comments',
    );
    sqlBuffer.write(' INNER JOIN users ON comments.user_id = users.id');
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
          comment: (
            id: row['comments_id'] as String,
            content: row['comments_content'] as String,
            postId: row['comments_post_id'] as String,
            userId: row['comments_user_id'] as String,
          ),
          user: (
            id: row['users_id'] as String,
            name: row['users_name'] as String,
          ),
        );
      }).toList();
    });
  }

  CommentsWithPostWithUserSelectBuilder withPost() {
    return CommentsWithPostWithUserSelectBuilder(
      db,
      CommentsWithPostWithUserSelectConfig(
        where: config.where,
        limit: config.limit,
        offset: config.offset,
      ),
    );
  }

  CommentsWithUserSelectBuilder where({
    Condition? id,
    Condition? content,
    Condition? postId,
    Condition? userId,
  }) {
    final newConditions = [...config.where];
    if (id != null) newConditions.add(id);
    if (content != null) newConditions.add(content);
    if (postId != null) newConditions.add(postId);
    if (userId != null) newConditions.add(userId);
    return CommentsWithUserSelectBuilder(
      db,
      CommentsWithUserSelectConfig(
        where: newConditions,
        limit: config.limit,
        offset: config.offset,
      ),
    );
  }

  CommentsWithUserSelectBuilder limit(int limit) {
    return CommentsWithUserSelectBuilder(
      db,
      CommentsWithUserSelectConfig(
        where: config.where,
        limit: limit,
        offset: config.offset,
      ),
    );
  }

  CommentsWithUserSelectBuilder offset(int offset) {
    return CommentsWithUserSelectBuilder(
      db,
      CommentsWithUserSelectConfig(
        where: config.where,
        limit: config.limit,
        offset: offset,
      ),
    );
  }
}

typedef CommentsWithPostWithUserRow = ({
  CommentsRow comment,
  PostsRow post,
  UsersRow user,
});

class CommentsWithPostWithUserSelectConfig {
  final List<Condition> where;
  final int? limit;
  final int? offset;

  CommentsWithPostWithUserSelectConfig({
    required List<Condition>? where,
    required this.limit,
    required this.offset,
  }) : where = where ?? [];
}

class CommentsWithPostWithUserSelectBuilder
    extends QueryFuture<List<CommentsWithPostWithUserRow>>
    with FutureMixin<List<CommentsWithPostWithUserRow>> {
  final PostgresQueryable db;
  final CommentsWithPostWithUserSelectConfig config;

  CommentsWithPostWithUserSelectBuilder(this.db, this.config);

  @override
  Future<List<CommentsWithPostWithUserRow>> execute() {
    final sqlBuffer = StringBuffer(
      'SELECT comments.id AS comments_id, comments.content AS comments_content, comments.post_id AS comments_post_id, comments.user_id AS comments_user_id, posts.id AS posts_id, posts.title AS posts_title, users.id AS users_id, users.name AS users_name FROM comments',
    );
    sqlBuffer.write(' INNER JOIN posts ON comments.post_id = posts.id');
    sqlBuffer.write(' INNER JOIN users ON comments.user_id = users.id');
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
          comment: (
            id: row['comments_id'] as String,
            content: row['comments_content'] as String,
            postId: row['comments_post_id'] as String,
            userId: row['comments_user_id'] as String,
          ),
          post: (
            id: row['posts_id'] as String,
            title: row['posts_title'] as String,
          ),
          user: (
            id: row['users_id'] as String,
            name: row['users_name'] as String,
          ),
        );
      }).toList();
    });
  }

  CommentsWithPostWithUserSelectBuilder where({
    Condition? id,
    Condition? content,
    Condition? postId,
    Condition? userId,
  }) {
    final newConditions = [...config.where];
    if (id != null) newConditions.add(id);
    if (content != null) newConditions.add(content);
    if (postId != null) newConditions.add(postId);
    if (userId != null) newConditions.add(userId);
    return CommentsWithPostWithUserSelectBuilder(
      db,
      CommentsWithPostWithUserSelectConfig(
        where: newConditions,
        limit: config.limit,
        offset: config.offset,
      ),
    );
  }

  CommentsWithPostWithUserSelectBuilder limit(int limit) {
    return CommentsWithPostWithUserSelectBuilder(
      db,
      CommentsWithPostWithUserSelectConfig(
        where: config.where,
        limit: limit,
        offset: config.offset,
      ),
    );
  }

  CommentsWithPostWithUserSelectBuilder offset(int offset) {
    return CommentsWithPostWithUserSelectBuilder(
      db,
      CommentsWithPostWithUserSelectConfig(
        where: config.where,
        limit: config.limit,
        offset: offset,
      ),
    );
  }
}
