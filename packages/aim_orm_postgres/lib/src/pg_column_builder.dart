import 'package:aim_orm_postgres/aim_orm_postgres.dart';

SerialColumn serial(String name) => SerialColumn(name: name);
UuidColumn uuid(String name) => UuidColumn(name: name);
JsonbColumn<T> jsonb<T>(String name) => JsonbColumn<T>(name: name);