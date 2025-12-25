import 'dart:io';

import 'package:aim_server/aim_server.dart';
import 'package:aim_server_cors/aim_server_cors.dart';

void main() async {
  final app = Aim();

  // Middleware
  app.use(cors());

  // Simple routes
  app.get('/', (c) async {
    return c.json({'message': 'Hello, Aim Framework!'});
  });

  app.get('/ping', (c) async {
    return c.text('pong');
  });

  // User CRUD routes
  final users = <String, Map<String, dynamic>>{};

  app.post('/users', (c) async {
    final data = await c.req.json();
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    users[id] = {'id': id, ...data};
    return c.json(users[id]!, statusCode: 201);
  });

  app.get('/users/:id', (c) async {
    final id = c.param('id');
    final user = users[id];
    if (user == null) {
      return c.json({'error': 'User not found'}, statusCode: 404);
    }
    return c.json(user);
  });

  app.put('/users/:id', (c) async {
    final id = c.param('id');
    if (!users.containsKey(id)) {
      return c.json({'error': 'User not found'}, statusCode: 404);
    }
    final data = await c.req.json();
    users[id] = {'id': id, ...data};
    return c.json(users[id]!);
  });

  app.patch('/users/:id', (c) async {
    final id = c.param('id');
    final user = users[id];
    if (user == null) {
      return c.json({'error': 'User not found'}, statusCode: 404);
    }
    final data = await c.req.json();
    users[id] = {...user, ...data};
    return c.json(users[id]!);
  });

  app.delete('/users/:id', (c) async {
    final id = c.param('id');
    if (!users.containsKey(id)) {
      return c.json({'error': 'User not found'}, statusCode: 404);
    }
    users.remove(id);
    return c.text('', statusCode: 204);
  });

  // Search with query parameters
  app.get('/search', (c) async {
    final query = c.req.queryParameters['q'];
    final limit = c.req.queryParameters['limit'] ?? '10';
    return c.json({'query': query, 'limit': int.parse(limit), 'results': []});
  });

  final server = await app.serve(host: InternetAddress.anyIPv4, port: 8081);
  print('Server started at http://${server.host}:${server.port}');
}
