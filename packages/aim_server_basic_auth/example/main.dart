import 'dart:io';

import 'package:aim_server/aim_server.dart';
import 'package:aim_server_basic_auth/aim_server_basic_auth.dart';

void main() {
  final options = BasicAuthOptions(
    realm: 'My Protected Area',
    verify: (username, password) async {
      return username == 'admin' && password == 'password';
    },
  );
  final app = Aim<BasicAuthEnv>(envFactory: () => BasicAuthEnv(options: options));

  app.use(basicAuth());

  app.get('/protected', (c) async {
    final username = c.variables.username;
    return c.json({'message': 'Hello, $username! You have accessed a protected route.'});
  });

  app.serve(host: InternetAddress.anyIPv4, port: 8080);
}