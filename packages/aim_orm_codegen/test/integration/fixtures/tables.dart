import 'package:aim_orm/aim_orm.dart';
import 'package:aim_orm_postgres/aim_orm_postgres.dart';
import 'package:aim_postgres/aim_postgres.dart';

part 'tables.g.dart';

/// Basic table for testing SELECT, INSERT, UPDATE, DELETE
@PgTable('users')
final users = (
  id: uuid('id').primaryKey(),
  name: varchar('name', length: 255),
  age: integer('age').nullable(),
  active: integer('active'), // PostgreSQL doesn't have native bool, using int (0/1)
  createdAt: timestamp('created_at'),
);

/// Table with foreign key for testing relations
@PgTable('posts')
final posts = (
  id: uuid('id').primaryKey(),
  title: varchar('title', length: 255),
  content: text('content'),
  userId: uuid('user_id').references(() => users.id),
  createdAt: timestamp('created_at'),
);

/// Table with nullable foreign key for testing LEFT JOIN
@PgTable('articles')
final articles = (
  id: uuid('id').primaryKey(),
  title: varchar('title', length: 255),
  authorId: uuid('author_id').nullable().references(() => users.id),
  createdAt: timestamp('created_at'),
);

/// Table with multiple foreign keys for testing multiple relations
@PgTable('comments')
final comments = (
  id: uuid('id').primaryKey(),
  content: text('content'),
  postId: uuid('post_id').references(() => posts.id),
  userId: uuid('user_id').references(() => users.id),
  createdAt: timestamp('created_at'),
);
