import 'package:aim_orm_codegen/src/record_table_generator.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

Builder recordPgTableBuilder(BuilderOptions options) {
  return SharedPartBuilder([RecordPgTableGenerator()], 'aim_record_table');
}
