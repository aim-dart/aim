import 'dart:io';

import 'package:aim_server/aim_server.dart';

void main() async {
  final app = Aim();

  app.get('/', (c) async {
    return c.json({'message': 'Hello, Aim Framework!'});
  });

  final server = await app.serve(host: InternetAddress.anyIPv4, port: 8081);
  print('Server started at http://${server.host}:${server.port}');
}