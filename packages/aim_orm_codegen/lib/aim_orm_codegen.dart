import 'package:aim_orm_codegen/src/record_table_generator.dart';
import 'package:aim_orm_codegen/src/table_collector_builder.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

/// Phase 1: Collect all @PgTable definitions into JSON
Builder tableCollectorBuilder(BuilderOptions options) {
  return TableCollectorBuilder();
}

/// Phase 2: Generate ORM code using collected table info
Builder recordPgTableBuilder(BuilderOptions options) {
  return SharedPartBuilder([RecordPgTableGenerator()], 'aim_record_table');
}
