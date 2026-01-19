---
title: DELETE - Aim ORM
description: Delete data with type-safe DELETE operations.
head:
  - - meta
    - name: keywords
      content: Dart ORM delete, database delete, type-safe delete
---

# DELETE

Delete data with type-safe DELETE operations.

## Basic Delete

Use `.delete().where()` to delete rows:

```dart
await db.users.delete().where(id: users.id.eq('user-123'));
```

## WHERE Clause

Always use `.where()` to specify which rows to delete:

```dart
// Delete single row by ID
await db.users.delete().where(id: users.id.eq('user-123'));

// Delete with multiple conditions
await db.posts.delete().where(
  userId: posts.userId.eq('user-123'),
  createdAt: posts.createdAt.lt(DateTime(2020, 1, 1)),
);
```

## Return Value

DELETE returns `Future<int>` - the number of deleted rows:

```dart
final deleted = await db.users.delete().where(id: users.id.eq('user-123'));

print('Deleted $deleted row(s)');
```

## Examples

### Delete User

```dart
Future<int> deleteUser(String userId) async {
  return db.users.delete().where(id: users.id.eq(userId));
}
```

### Delete Post

```dart
Future<int> deletePost(int postId) async {
  return db.posts.delete().where(id: posts.id.eq(postId));
}
```

### Delete User's Posts

```dart
Future<int> deleteUserPosts(String userId) async {
  return db.posts.delete().where(userId: posts.userId.eq(userId));
}
```

### Delete Old Records

```dart
Future<int> deleteOldComments() async {
  final cutoff = DateTime.now().subtract(Duration(days: 90));

  return db.comments.delete().where(
    createdAt: comments.createdAt.lt(cutoff),
  );
}
```

## Caution

::: warning
DELETE without WHERE will delete all rows. Always include a WHERE clause.
:::

```dart
// DANGEROUS - deletes all users!
// await db.users.delete();

// SAFE - deletes specific user
await db.users.delete().where(id: users.id.eq('user-123'));
```

## Next Steps

- [SELECT](/database/orm/select) - Query data
- [INSERT](/database/orm/insert) - Insert data
- [UPDATE](/database/orm/update) - Update data