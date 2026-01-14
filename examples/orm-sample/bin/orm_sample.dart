import 'package:aim_orm/aim_orm.dart';
import 'package:aim_orm_postgres/aim_orm_postgres.dart';
import 'package:orm_sample/orm_sample.dart' as orm_sample;

part 'orm_sample.g.dart';

@Table("hoge")
abstract class Hoge extends PgTable {
  IntegerColumn get id => integer().primaryKey();
  VarcharColumn get name => varchar(255);
  VarcharColumn get email => varchar(255).unique();
}

@Table('users')
abstract class Users extends PgTable {
  UuidColumn get id => uuid().primaryKey();

  VarcharColumn get username => varchar(150).unique();

  VarcharColumn get passwordHash => varchar(255);
}


void main(List<String> arguments) async {
  final db = await aimDb();
  db.select().from(users);
}
