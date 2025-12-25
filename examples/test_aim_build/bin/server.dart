import 'dart:io';
import 'package:test_aim_build/src/server.dart';

void main() async {
  final app = createApp();

  // Start server
  final server = await app.serve(
    host: InternetAddress.anyIPv4,
    port: 8080,
  );

  print('🚀 Server started: http://${server.host}:${server.port}');
}
