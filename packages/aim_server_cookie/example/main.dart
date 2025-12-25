import 'dart:io';

import 'package:aim_server/aim_server.dart';
import 'package:aim_server_cookie/aim_server_cookie.dart';

void main() async {
  final app = Aim();

  // 基本的なCookieの設定
  app.get('/', (c) async {
    return c.html('''
      <!DOCTYPE html>
      <html>
      <head>
        <title>Cookie Example</title>
        <style>
          body { font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; }
          .example { background: #f5f5f5; padding: 15px; margin: 10px 0; border-radius: 5px; }
          h2 { color: #333; }
          a { display: inline-block; margin: 10px 0; color: #007bff; text-decoration: none; }
          a:hover { text-decoration: underline; }
        </style>
      </head>
      <body>
        <h1>Cookie Examples</h1>

        <div class="example">
          <h2>基本的なCookie</h2>
          <a href="/set-basic-cookie">基本的なCookieを設定</a>
        </div>

        <div class="example">
          <h2>セキュアなCookie</h2>
          <a href="/set-secure-cookie">HttpOnly + Secure Cookieを設定</a>
        </div>

        <div class="example">
          <h2>有効期限付きCookie</h2>
          <a href="/set-cookie-with-expiry">1時間で期限切れのCookieを設定</a>
        </div>

        <div class="example">
          <h2>複数のCookie</h2>
          <a href="/set-multiple-cookies">複数のCookieを設定</a>
        </div>

        <div class="example">
          <h2>Cookieの確認</h2>
          <a href="/get-cookies">現在のCookieを確認</a>
        </div>

        <div class="example">
          <h2>Cookieの削除</h2>
          <a href="/delete-cookie">Cookieを削除</a>
        </div>
      </body>
      </html>
    ''');
  });

  // 基本的なCookieの設定
  app.get('/set-basic-cookie', (c) async {
    c.setCookie('basic_cookie', 'hello_world');
    return c.json({
      'message': 'Basic cookie set!',
      'cookie': 'basic_cookie=hello_world',
    });
  });

  // セキュアなCookieの設定
  app.get('/set-secure-cookie', (c) async {
    c.setCookie(
      'session_id',
      'abc123xyz',
      options: CookieOptions(
        httpOnly: true,
        secure: true,
        sameSite: SameSite.strict,
        path: '/',
      ),
    );
    return c.json({
      'message': 'Secure cookie set!',
      'cookie': 'session_id=abc123xyz',
      'options': {
        'httpOnly': true,
        'secure': true,
        'sameSite': 'Strict',
        'path': '/',
      },
    });
  });

  // 有効期限付きCookieの設定
  app.get('/set-cookie-with-expiry', (c) async {
    c.setCookie(
      'temp_token',
      'token_12345',
      options: CookieOptions(maxAge: Duration(hours: 1), path: '/'),
    );
    return c.json({
      'message': 'Cookie with 1 hour expiry set!',
      'cookie': 'temp_token=token_12345',
      'maxAge': '3600 seconds (1 hour)',
    });
  });

  // 複数のCookieの設定
  app.get('/set-multiple-cookies', (c) async {
    c.setCookie(
      'user_id',
      '12345',
      options: CookieOptions(path: '/', maxAge: Duration(days: 7)),
    );

    c.setCookie(
      'theme',
      'dark',
      options: CookieOptions(path: '/', maxAge: Duration(days: 30)),
    );

    c.setCookie(
      'language',
      'ja',
      options: CookieOptions(path: '/', maxAge: Duration(days: 365)),
    );

    return c.json({
      'message': 'Multiple cookies set!',
      'cookies': [
        {'name': 'user_id', 'value': '12345', 'maxAge': '7 days'},
        {'name': 'theme', 'value': 'dark', 'maxAge': '30 days'},
        {'name': 'language', 'value': 'ja', 'maxAge': '365 days'},
      ],
    });
  });

  // Cookieの確認
  app.get('/get-cookies', (c) async {
    final cookieHeader = c.headers['cookie'] ?? 'No cookies found';
    final cookies = <String, String>{};

    if (cookieHeader != 'No cookies found') {
      for (final cookie in cookieHeader.split('; ')) {
        final parts = cookie.split('=');
        if (parts.length == 2) {
          cookies[parts[0]] = parts[1];
        }
      }
    }

    return c.json({
      'message': 'Current cookies',
      'raw': cookieHeader,
      'parsed': cookies,
    });
  });

  // Cookieの削除
  app.get('/delete-cookie', (c) async {
    c.deleteCookie('basic_cookie', path: '/');
    c.deleteCookie('session_id', path: '/');
    c.deleteCookie('user_id', path: '/');
    c.deleteCookie('theme', path: '/');
    c.deleteCookie('language', path: '/');

    return c.json({
      'message': 'Cookies deleted!',
      'deleted': ['basic_cookie', 'session_id', 'user_id', 'theme', 'language'],
    });
  });

  print('Cookie example server starting on http://localhost:8080');
  print('Open http://localhost:8080 in your browser');
  await app.serve(host: InternetAddress.anyIPv4, port: 8080);
}
