import 'dart:io';

import 'package:aim_server/aim_server.dart';
import 'package:aim_server_sse/aim_server_sse.dart';

void main() async {
  final app = Aim();

  // Basic SSE example
  app.get('/events', (c) async {
    return c.sse((stream) async {
      stream.send('Connection established');

      for (var i = 1; i <= 10; i++) {
        await Future.delayed(Duration(seconds: 1));
        print('Sending event $i');
        stream.sendJson({
          'count': i,
          'timestamp': DateTime.now().toIso8601String(),
        }, event: 'count', id: '$i');
      }

      stream.send('Done!');
    });
  });

  // Real-time clock example
  app.get('/clock', (c) async {
    return c.sse((stream) async {
      while (true) {
        stream.sendJson({
          'time': DateTime.now().toIso8601String(),
        }, event: 'time');

        await Future.delayed(Duration(seconds: 1));
      }
    });
  });

  // Keep-alive example
  app.get('/keepalive', (c) async {
    return c.sse((stream) async {
      var count = 0;

      while (true) {
        if (count % 5 == 0) {
          stream.send('Message $count');
        } else {
          stream.keepAlive();
        }

        count++;
        await Future.delayed(Duration(seconds: 1));
      }
    });
  });

  // Debug comments example
  app.get('/debug', (c) async {
    return c.sse((stream) async {
      stream.comment('Starting debug session');

      for (var i = 1; i <= 5; i++) {
        stream.comment('Processing step $i');
        await Future.delayed(Duration(milliseconds: 500));
        stream.send('Step $i completed');
        await Future.delayed(Duration(milliseconds: 500));
      }

      stream.comment('Debug session finished');
    });
  });

  final server = await app.serve(
    host: InternetAddress.anyIPv4,
    port: 8080,
  );

  print('Server started: http://${server.host}:${server.port}');
  print('');
  print('Try these endpoints:');
  print('  /events    - Basic SSE with 10 messages');
  print('  /clock     - Real-time clock updates');
  print('  /keepalive - Keep-alive demonstration');
  print('  /debug     - Debug comments example');
}
