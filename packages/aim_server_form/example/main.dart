import 'dart:io';

import 'package:aim_server/aim_server.dart';
import 'package:aim_server_form/aim_server_form.dart';

void main() async {
  final app = Aim();

  // Home page with HTML forms
  app.get('/', (c) async {
    return c.html('''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>aim_form Example</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      max-width: 800px;
      margin: 50px auto;
      padding: 20px;
    }
    h1, h2 {
      color: #333;
    }
    form {
      background: #f5f5f5;
      padding: 20px;
      border-radius: 8px;
      margin-bottom: 30px;
    }
    label {
      display: block;
      margin-top: 10px;
      font-weight: bold;
    }
    input, button {
      width: 100%;
      padding: 10px;
      margin-top: 5px;
      border: 1px solid #ddd;
      border-radius: 4px;
      box-sizing: border-box;
    }
    button {
      background: #007bff;
      color: white;
      border: none;
      cursor: pointer;
      margin-top: 15px;
    }
    button:hover {
      background: #0056b3;
    }
    .result {
      background: #e7f3ff;
      padding: 15px;
      border-radius: 4px;
      margin-top: 20px;
    }
  </style>
</head>
<body>
  <h1>aim_form Example</h1>

  <h2>1. Login Form</h2>
  <form action="/login" method="POST">
    <label for="username">Username:</label>
    <input type="text" id="username" name="username" required>

    <label for="password">Password:</label>
    <input type="password" id="password" name="password" required>

    <label>
      <input type="checkbox" name="remember" value="on">
      Remember me
    </label>

    <button type="submit">Login</button>
  </form>

  <h2>2. Search Form</h2>
  <form action="/search" method="POST">
    <label for="q">Search Query:</label>
    <input type="text" id="q" name="q" placeholder="Enter search term..." required>

    <label for="filter">Filter:</label>
    <select name="filter" id="filter">
      <option value="all">All</option>
      <option value="recent">Recent</option>
      <option value="popular">Popular</option>
    </select>

    <button type="submit">Search</button>
  </form>

  <h2>3. Contact Form (with Unicode)</h2>
  <form action="/contact" method="POST">
    <label for="name">Name:</label>
    <input type="text" id="name" name="name" value="太郎" required>

    <label for="email">Email:</label>
    <input type="email" id="email" name="email" required>

    <label for="message">Message:</label>
    <input type="text" id="message" name="message" value="こんにちは 👋" required>

    <button type="submit">Send</button>
  </form>
</body>
</html>
    ''');
  });

  // Login endpoint
  app.post('/login', (c) async {
    try {
      final form = await c.req.formData();

      final username = form['username'];
      final password = form['password'];
      final remember = form.get('remember', 'off');

      // Basic validation
      if (username == null || username.isEmpty) {
        return c.json({'error': 'Username is required'}, statusCode: 400);
      }

      if (password == null || password.isEmpty) {
        return c.json({'error': 'Password is required'}, statusCode: 400);
      }

      // Simulate authentication
      final success = username == 'alice' && password == 'secret123';

      if (success) {
        return c.html('''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Login Success</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      max-width: 800px;
      margin: 50px auto;
      padding: 20px;
    }
    .success {
      background: #d4edda;
      color: #155724;
      padding: 20px;
      border-radius: 4px;
    }
    a {
      color: #007bff;
    }
  </style>
</head>
<body>
  <div class="success">
    <h2>Login Successful!</h2>
    <p><strong>Username:</strong> $username</p>
    <p><strong>Remember me:</strong> $remember</p>
  </div>
  <p><a href="/">← Back to home</a></p>
</body>
</html>
        ''');
      } else {
        return c.html('''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Login Failed</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      max-width: 800px;
      margin: 50px auto;
      padding: 20px;
    }
    .error {
      background: #f8d7da;
      color: #721c24;
      padding: 20px;
      border-radius: 4px;
    }
    a {
      color: #007bff;
    }
  </style>
</head>
<body>
  <div class="error">
    <h2>Login Failed</h2>
    <p>Invalid username or password.</p>
    <p>(Try: username=alice, password=secret123)</p>
  </div>
  <p><a href="/">← Back to home</a></p>
</body>
</html>
        ''', statusCode: 401);
      }
    } on FormatException catch (e) {
      return c.json({
        'error': 'Invalid form data',
        'details': e.message,
      }, statusCode: 400);
    }
  });

  // Search endpoint
  app.post('/search', (c) async {
    final form = await c.req.formData();

    final query = form['q'] ?? '';
    final filter = form.get('filter', 'all');

    return c.html('''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Search Results</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      max-width: 800px;
      margin: 50px auto;
      padding: 20px;
    }
    .result {
      background: #e7f3ff;
      padding: 20px;
      border-radius: 4px;
    }
    a {
      color: #007bff;
    }
  </style>
</head>
<body>
  <h1>Search Results</h1>
  <div class="result">
    <p><strong>Query:</strong> $query</p>
    <p><strong>Filter:</strong> $filter</p>
    <p><em>No results found (this is a demo)</em></p>
  </div>
  <p><a href="/">← Back to home</a></p>
</body>
</html>
    ''');
  });

  // Contact endpoint (handles Unicode)
  app.post('/contact', (c) async {
    final form = await c.req.formData();

    final name = form['name'];
    final email = form['email'];
    final message = form['message'];

    return c.html('''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>Message Received</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      max-width: 800px;
      margin: 50px auto;
      padding: 20px;
    }
    .success {
      background: #d4edda;
      color: #155724;
      padding: 20px;
      border-radius: 4px;
    }
    a {
      color: #007bff;
    }
  </style>
</head>
<body>
  <div class="success">
    <h2>Thank you for your message!</h2>
    <p><strong>Name:</strong> $name</p>
    <p><strong>Email:</strong> $email</p>
    <p><strong>Message:</strong> $message</p>
  </div>
  <p><a href="/">← Back to home</a></p>
</body>
</html>
    ''');
  });

  // API endpoint (returns JSON)
  app.post('/api/login', (c) async {
    try {
      final form = await c.req.formData();

      final username = form['username'];
      final password = form['password'];

      if (username == null || password == null) {
        return c.json({
          'error': 'Username and password are required',
        }, statusCode: 400);
      }

      final success = username == 'alice' && password == 'secret123';

      if (success) {
        return c.json({
          'success': true,
          'user': {'username': username, 'token': 'mock-jwt-token'},
        });
      } else {
        return c.json({
          'success': false,
          'error': 'Invalid credentials',
        }, statusCode: 401);
      }
    } on FormatException catch (e) {
      return c.json({
        'error': 'Invalid Content-Type',
        'expected': 'application/x-www-form-urlencoded',
        'details': e.message,
      }, statusCode: 400);
    }
  });

  final server = await app.serve(host: InternetAddress.anyIPv4, port: 8080);

  print('🚀 Server running on http://localhost:${server.port}');
  print('📝 Open http://localhost:${server.port} in your browser');
}
