import 'dart:async';

import 'package:aim_orm/aim_orm.dart';
import 'package:aim_orm_postgres/aim_orm_postgres.dart';
import 'package:aim_postgres/aim_postgres.dart';

part 'test.g.dart';

@PgTable('users')
final users = (
  id: integer('id').primaryKey(),
  name: varchar('name', length: 255),
  email: varchar('email', length: 255).unique(),
  createdAt: timestamp('created_at').withDefault(DateTime.now()),
);

@PgTable('posts')
final posts = (
  id: integer('id').primaryKey(),
  userId: integer('user_id'),
  title: varchar('title', length: 255),
  content: text('content'),
  createdAt: timestamp('created_at').withDefault(DateTime.now()),
);

void main() async {
  final db = await PostgresDatabase.connect(
    'postgres://test:test@localhost:5432/test_db',
  );

  final result = await db.users.select();

  for (var row in result) {
    print(row);
  }

  await db.users.delete().where(id: users.id.eq(4));
}