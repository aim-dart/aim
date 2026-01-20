---
title: UPDATE - Aim ORM
description: Update data with type-safe UPDATE operations.
head:
  - - meta
    - name: keywords
      content: Dart ORM update, database update, type-safe update
---

# UPDATE

Update data with type-safe UPDATE operations.

## Basic Update

Use `.update().set().where()` to update rows:

```dart
await db.users
    .update()
    .set((name: 'Alice Updated'))
    .where(id: users.id.eq('user-123'));
```

## Set Values

The `.set()` method takes a Record with only the fields you want to update:

```dart
// Update only name
await db.users
    .update()
    .set((name: 'New Name'))
    .where(id: users.id.eq('user-123'));

// Update multiple fields
await db.users
    .update()
    .set((name: 'New Name', email: 'new@example.com'))
    .where(id: users.id.eq('user-123'));
```

## WHERE Clause

Always use `.where()` to specify which rows to update:

```dart
// Update single row by ID
await db.users
    .update()
    .set((name: 'Updated'))
    .where(id: users.id.eq('user-123'));

// Update multiple rows
await db.posts
    .update()
    .set((content: 'Archived'))
    .where(userId: posts.userId.eq('deleted-user'));
```

## Return Value

UPDATE returns `Future<int>` - the number of affected rows:

```dart
final affected = await db.users
    .update()
    .set((name: 'Updated Name'))
    .where(id: users.id.eq('user-123'));

print('Updated $affected row(s)');
```

## Examples

### Update User Email

```dart
Future<int> updateEmail({
  required String userId,
  required String newEmail,
}) async {
  return db.users
      .update()
      .set((email: newEmail))
      .where(id: users.id.eq(userId));
}
```

### Update Post Content

```dart
Future<int> updatePost({
  required int postId,
  required String title,
  required String content,
}) async {
  return db.posts
      .update()
      .set((title: title, content: content))
      .where(id: posts.id.eq(postId));
}
```

## Next Steps

- [DELETE](/database/orm/delete) - Delete data
- [Transactions](/database/orm/transactions) - Atomic operations
- [SELECT](/database/orm/select) - Query data
- [INSERT](/database/orm/insert) - Insert data