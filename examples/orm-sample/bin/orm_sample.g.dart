// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orm_sample.dart';

// **************************************************************************
// TableGenerator
// **************************************************************************

class $Hoge extends Hoge {
  @override
  String get tableName => 'hoge';

  @override
  final id = IntegerColumn(isPrimaryKey: true);
  @override
  final name = VarcharColumn(length: 255);
  @override
  final email = VarcharColumn(length: 255, isUnique: true);

  @override
  List<Column> get columns => [id, name, email];
}

/// Table instance for Hoge
final hoge = $Hoge();

/// Row type for Hoge
typedef HogeRow = ({int id, String name, String email});

class $Users extends Users {
  @override
  String get tableName => 'users';

  @override
  final id = UuidColumn(isPrimaryKey: true);
  @override
  final username = VarcharColumn(length: 150, isUnique: true);
  @override
  final passwordHash = VarcharColumn(length: 255);

  @override
  List<Column> get columns => [id, username, passwordHash];
}

/// Table instance for Users
final users = $Users();

/// Row type for Users
typedef UsersRow = ({String id, String username, String passwordHash});
