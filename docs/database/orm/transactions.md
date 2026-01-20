---
title: Transactions - Aim ORM
description: Use transactions for atomic database operations with automatic rollback on errors.
head:
  - - meta
    - name: keywords
      content: Dart ORM transactions, database transactions, atomic operations
---

# Transactions

Use transactions for atomic database operations with automatic rollback on errors.

## Basic Usage

Use `db.transaction()` to execute multiple operations atomically:

```dart
await db.transaction((tx) async {
  await tx.users.insert().values((
    id: 'user-123',
    name: 'Alice',
    email: 'alice@example.com',
    createdAt: DateTime.now(),
  ));

  await tx.posts.insert().values((
    id: 0,
    userId: 'user-123',
    title: 'My First Post',
    content: 'Hello, World!',
    createdAt: DateTime.now(),
  ));
});
```

## Automatic Rollback

If any operation fails, the entire transaction is automatically rolled back:

```dart
try {
  await db.transaction((tx) async {
    await tx.users.insert().values((
      id: 'user-123',
      name: 'Alice',
      email: 'alice@example.com',
      createdAt: DateTime.now(),
    ));

    // If this fails, the user insert above is also rolled back
    await tx.posts.insert().values((
      id: 0,
      userId: 'user-123',
      title: 'Post',
      content: 'Content',
      createdAt: DateTime.now(),
    ));
  });
} catch (e) {
  print('Transaction failed: $e');
  // Both inserts are rolled back
}
```

## Transaction Context

Inside a transaction callback, use `tx` instead of `db`:

```dart
await db.transaction((tx) async {
  // Use tx.users, not db.users
  final users = await tx.users.select();

  await tx.users.update()
      .set((name: 'Updated'))
      .where(id: users.id.eq('user-123'));
});
```

## Return Values

Transactions can return values:

```dart
final newUser = await db.transaction((tx) async {
  await tx.users.insert().values((
    id: 'user-123',
    name: 'Alice',
    email: 'alice@example.com',
    createdAt: DateTime.now(),
  ));

  final result = await tx.users.select()
      .where(id: users.id.eq('user-123'));

  return result.first;
});

print(newUser.name);  // Alice
```

## Examples

### Transfer Operation

```dart
Future<void> transfer({
  required String fromUserId,
  required String toUserId,
  required int amount,
}) async {
  await db.transaction((tx) async {
    // Deduct from sender
    await tx.accounts.update()
        .set((balance: currentBalance - amount))
        .where(userId: accounts.userId.eq(fromUserId));

    // Add to receiver
    await tx.accounts.update()
        .set((balance: currentBalance + amount))
        .where(userId: accounts.userId.eq(toUserId));
  });
}
```

### Create User with Profile

```dart
Future<void> createUserWithProfile({
  required String id,
  required String name,
  required String email,
  required String bio,
}) async {
  await db.transaction((tx) async {
    await tx.users.insert().values((
      id: id,
      name: name,
      email: email,
      createdAt: DateTime.now(),
    ));

    await tx.profiles.insert().values((
      id: 0,
      userId: id,
      bio: bio,
      createdAt: DateTime.now(),
    ));
  });
}
```

### Bulk Insert

```dart
Future<void> bulkInsertUsers(List<Map<String, dynamic>> userData) async {
  await db.transaction((tx) async {
    for (final data in userData) {
      await tx.users.insert().values((
        id: data['id'] as String,
        name: data['name'] as String,
        email: data['email'] as String,
        createdAt: DateTime.now(),
      ));
    }
  });
}
```

## Next Steps

- [SELECT](/database/orm/select) - Query data
- [INSERT](/database/orm/insert) - Insert data
- [UPDATE](/database/orm/update) - Update data
- [DELETE](/database/orm/delete) - Delete data
