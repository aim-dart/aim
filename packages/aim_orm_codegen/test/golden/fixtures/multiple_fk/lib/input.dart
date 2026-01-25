import 'package:aim_orm/aim_orm.dart';
import 'package:aim_orm_postgres/aim_orm_postgres.dart';
import 'package:aim_postgres/aim_postgres.dart';

part 'input.g.dart';

@PgTable('users')
final users = (
  id: uuid('id').primaryKey(),
  name: varchar('name', length: 255),
);

@PgTable('posts')
final posts = (
  id: uuid('id').primaryKey(),
  title: varchar('title', length: 255),
);

@PgTable('comments')
final comments = (
  id: uuid('id').primaryKey(),
  content: text('content'),
  postId: uuid('post_id').references(() => posts.id),
  userId: uuid('user_id').references(() => users.id),
);
