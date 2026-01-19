---
title: INSERT - Aim ORM
description: Insert data with type-safe INSERT operations.
head:
  - - meta
    - name: keywords
      content: Dart ORM insert, database insert, type-safe insert
---

# INSERT

Insert data with type-safe INSERT operations.

## Basic Insert

Use `.insert().values()` to insert a row:

```dart
await db.users.insert().values((
  id: 'uuid-here',
  name: 'Alice',
  email: 'alice@example.com',
  createdAt: DateTime.now(),
));
```

## Values Record

The `.values()` method takes a Record matching the table schema:

```dart
// All fields are required (except nullable ones)
await db.users.insert().values((
  id: 'user-123',
  name: 'Bob',
  email: 'bob@example.com',
  createdAt: DateTime.now(),
));
```

## Return Value

INSERT returns `Future<int>` - the number of affected rows:

```dart
final affected = await db.users.insert().values((
  id: 'user-456',
  name: 'Charlie',
  email: 'charlie@example.com',
  createdAt: DateTime.now(),
));

print('Inserted $affected row(s)');  // Inserted 1 row(s)
```

## Examples

### Insert User

```dart
Future<void> createUser({
  required String id,
  required String name,
  required String email,
}) async {
  await db.users.insert().values((
    id: id,
    name: name,
    email: email,
    createdAt: DateTime.now(),
  ));
}
```

### Insert Post

```dart
Future<void> createPost({
  required String userId,
  required String title,
  required String content,
}) async {
  await db.posts.insert().values((
    id: 0,  // SERIAL auto-increments
    userId: userId,
    title: title,
    content: content,
    createdAt: DateTime.now(),
  ));
}
```

## Next Steps

- [UPDATE](/database/orm/update) - Update data
- [DELETE](/database/orm/delete) - Delete data
- [SELECT](/database/orm/select) - Query data