import 'dart:io';

import 'package:aim_server/aim_server.dart';
import 'package:aim_server_jwt/aim_server_jwt.dart';

void main() {
  final app = Aim<JwtEnv>(
    envFactory: () => JwtEnv.create(
      JwtOptions(
        algorithm: HS256(
          secretKey: SecretKey(secret: 'super-secret-key-change-in-production'),
        ),
        excludedPaths: ['/login'],
      ),
    ),
  );
  app.use(jwt());

  app.get('/protected', (c) async {
    final payload = c.variables.jwtPayload;
    return c.json({
      'message': 'This is a protected route',
      'user_id': payload['user_id'],
    });
  });

  app.get('/login', (c) async {
    final jwt = Jwt(options: c.variables.jwtOptions);
    final token = jwt.sign({'user_id': 1, 'role': 'admin'});

    return c.json({'token': token});
  });

  app.serve(host: InternetAddress.anyIPv4, port: 8080);
}
