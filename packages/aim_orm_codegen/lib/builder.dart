import 'package:aim_orm_codegen/src/table_generator.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

Builder tableBuilder(BuilderOptions options) {
  return SharedPartBuilder([TableGenerator()], 'aim_table');
}
