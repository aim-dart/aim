import 'dart:io';

import 'package:aim_server/aim_server.dart';
import 'package:aim_server_logger/aim_server_logger.dart';

void main() {
  final app = Aim();

  app.use(logger(onRequest: (c) async {
    c.param('start');
  }));

  app.get('/', (c) async {
    return c.text('Hello, Aim Server with Logger!');
  });

  app.serve(host: InternetAddress.anyIPv4, port: 8080);
}