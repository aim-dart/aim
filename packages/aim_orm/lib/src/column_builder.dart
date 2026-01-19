import 'package:aim_orm/aim_orm.dart';

IntegerColumn integer(String name) {
  return IntegerColumn(name: name);
}

VarcharColumn varchar(String name, {int? length}) {
  return VarcharColumn(name: name, length: length);
}

TextColumn text(String name) {
  return TextColumn(name: name);
}

TimestampColumn timestamp(String name) {
  return TimestampColumn(name: name);
}