---
title: SELECT - Aim ORM
description: Query data with type-safe SELECT operations. Filtering, pagination, and conditions.
head:
  - - meta
    - name: keywords
      content: Dart ORM select, query builder, where clause, pagination
---

# SELECT

Query data with type-safe SELECT operations.

## Basic Select

```dart
// Select all rows
final allUsers = await db.users.select();

// Iterate with type safety
for (var user in allUsers) {
  print(user.name);   // String
  print(user.email);  // String
}
```

## Filtering with WHERE

Use the `.where()` method with condition operators:

```dart
// Single condition
final user = await db.users
    .select()
    .where(id: users.id.eq('abc-123'));

// Multiple conditions (AND)
final filtered = await db.users
    .select()
    .where(
      name: users.name.eq('Alice'),
      email: users.email.eq('alice@example.com'),
    );
```

## Condition Operators

| Operator | Description | Example |
|----------|-------------|---------|
| `.eq(value)` | Equal | `users.id.eq('abc')` |
| `.gt(value)` | Greater than | `posts.id.gt(10)` |
| `.lt(value)` | Less than | `posts.id.lt(100)` |
| `.gte(value)` | Greater than or equal | `posts.id.gte(10)` |
| `.lte(value)` | Less than or equal | `posts.id.lte(100)` |
| `.inList(values)` | IN clause | `posts.id.inList([1, 2, 3])` |

## Pagination

Use `.limit()` and `.offset()` for pagination:

```dart
// First 10 users
final page1 = await db.users
    .select()
    .limit(10);

// Next 10 users (skip first 10)
final page2 = await db.users
    .select()
    .limit(10)
    .offset(10);

// Combined with filtering
final recentPosts = await db.posts
    .select()
    .where(userId: posts.userId.eq('user-123'))
    .limit(20)
    .offset(0);
```

## Chaining

Methods can be chained in any order:

```dart
final results = await db.posts
    .select()
    .where(userId: posts.userId.eq('user-123'))
    .limit(10)
    .offset(20);
```

## Result Type

SELECT returns a `Future<List<Row>>` where `Row` is the generated type:

```dart
// UsersRow = ({String id, String name, String email, DateTime createdAt})
final List<UsersRow> users = await db.users.select();

// Type-safe field access
for (var user in users) {
  String id = user.id;
  String name = user.name;
  String email = user.email;
  DateTime createdAt = user.createdAt;
}
```

## Await Directly

Query builders implement `Future`, so you can await directly:

```dart
// These are equivalent:
final users = await db.users.select();
final users = await db.users.select().execute();
```

## Examples

### Get User by ID

```dart
final result = await db.users
    .select()
    .where(id: users.id.eq('user-123'));

if (result.isNotEmpty) {
  final user = result.first;
  print('Found: ${user.name}');
}
```

### Paginated List

```dart
Future<List<PostsRow>> getPosts({
  required int page,
  int perPage = 20,
}) async {
  return db.posts
      .select()
      .limit(perPage)
      .offset((page - 1) * perPage);
}
```

### Filter by Foreign Key

```dart
// Get all posts by a user
final userPosts = await db.posts
    .select()
    .where(userId: posts.userId.eq('user-123'));

// Get all comments on a post
final postComments = await db.comments
    .select()
    .where(postId: comments.postId.eq(42));
```

## Next Steps

- [INSERT](/database/orm/insert) - Insert data
- [UPDATE](/database/orm/update) - Update data
- [DELETE](/database/orm/delete) - Delete data
- [Transactions](/database/orm/transactions) - Atomic operations