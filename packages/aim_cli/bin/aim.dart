import 'package:args/command_runner.dart';
import 'package:aim_cli/aim_cli.dart';

void main(List<String> arguments) async {
  final runner = CommandRunner('aim', 'Command-line tool for Aim framework')
    ..addCommand(CreateCommand())
    ..addCommand(DevCommand())
    ..addCommand(BuildCommand())
    ..addCommand(DbGenerateCommand())
    ..addCommand(DbMigrateCommand())
    ..addCommand(DbRollbackCommand())
    ..addCommand(DbStatusCommand());

  try {
    await runner.run(arguments);
  } catch (e) {
    print('Error: $e');
  }
}
