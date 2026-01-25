import 'package:aim_orm/aim_orm.dart';
import 'package:aim_orm_postgres/aim_orm_postgres.dart';
import 'package:aim_postgres/aim_postgres.dart';

part 'input.g.dart';

@PgTable('users')
final users = (
  id: uuid('id').primaryKey(),
  name: varchar('name', length: 255),
);

@PgTable('articles')
final articles = (
  id: uuid('id').primaryKey(),
  title: varchar('title', length: 255),
  authorId: uuid('author_id').nullable().references(() => users.id),
);
