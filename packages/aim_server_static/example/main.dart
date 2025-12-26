import 'dart:io';

import 'package:aim_server/aim_server.dart';
import 'package:aim_server_static/aim_server_static.dart';

void main() {
  final app = Aim();

  app.use(serveStatic('./static', path: '/static', index: 'index.html'));

  app.get('/doc', (c) async {
    return c.file('static/index.html', download: true);
  });

  app.serve(host: InternetAddress.anyIPv4, port: 8080);
}
