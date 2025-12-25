import 'dart:io';

import 'package:aim_server/aim_server.dart';
import 'package:aim_server_multipart/src/multipart_request.dart';

void main() {
  final app = Aim();
  app.post('/upload', (c) async {
    final data = c.req.multipart();
    return c.text('received');
  });

  app.serve(
    host: InternetAddress.anyIPv4,
    port: 8080,
  );
}

void hoge () {
  final client= HttpClient();

}