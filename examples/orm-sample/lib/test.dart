import 'dart:async';

import 'package:aim_orm/aim_orm.dart';
import 'package:aim_orm_postgres/aim_orm_postgres.dart';
import 'package:aim_postgres/aim_postgres.dart';
import 'package:uuid/uuid.dart';

part 'test.g.dart';

@PgTable('users')
final users = (
  id: uuid('id').primaryKey(),
  name: varchar('name', length: 100).unique().indexed(),
  email: varchar('email', length: 255).unique().indexed(),
  age: integer('age').nullable(),
  gender: varchar('gender').nullable(),
  createdAt: timestamp('created_at').withDefault(DateTime.now()),
);

@PgTable('posts')
final posts = (
  id: integer('id').primaryKey(),
  userId: uuid('user_id').references(() => users.id),
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

  await db.transaction((tx) async {
    final sameUuid = Uuid().v4();
    await tx.users.insert().values((
      id: sameUuid,
      name: 'user1',
      email: 'user1@example.com',
      createdAt: DateTime.now(),
    ));

    await tx.users.insert().values((
      id: Uuid().v4(),
      name: 'user2',
      email: 'user2@example.com',
      createdAt: DateTime.now(),
    ));
  });

  await db.close();
}
