# aim_server_static

Static file serving middleware for the Aim framework with security built-in.

## Overview

`aim_server_static` provides secure static file serving for the Aim framework. This package was designed as a separate module to keep applications that don't need static file serving lightweight while providing essential security features like path traversal protection and dotfile restrictions.

## Features

- 📁 **Directory Serving** - Serve entire directories with automatic MIME type detection
- 🔒 **Path Traversal Protection** - Built-in security against `../` attacks
- 🙈 **Dotfile Control** - Prevent access to sensitive hidden files (`.env`, `.git`, etc.)
- 📄 **Index File Support** - Automatic `index.html` serving for directories
- 🎯 **URL Prefix Matching** - Serve static files under specific URL paths
- 📥 **Single File Serving** - Context extension for serving individual files
- 💾 **Download Support** - Force file downloads with custom filenames
- 🎨 **Automatic MIME Types** - Smart content-type detection for common file formats

## Installation

Add `aim_server_static` to your `pubspec.yaml`:

```yaml
dependencies:
  aim_server: ^0.0.6
  aim_server_static: ^0.0.1
```

Then run:

```bash
dart pub get
```

## Usage

### Basic Static File Serving

Serve files from a directory:

```dart
import 'package:aim_server/aim_server.dart';
import 'package:aim_server_static/aim_server_static.dart';

void main() async {
  final app = Aim();

  // Serve files from the 'public' directory
  app.use(serveStatic('./public'));

  app.get('/api/hello', (c) => c.json({'message': 'Hello!'}));

  await app.serve(port: 8080);
}
```

File structure:
```
public/
  ├── index.html
  ├── styles.css
  └── images/
      └── logo.png
```

Requests:
- `GET /index.html` → `public/index.html`
- `GET /styles.css` → `public/styles.css`
- `GET /images/logo.png` → `public/images/logo.png`

### URL Prefix Matching

Serve static files under a specific URL path:

```dart
app.use(serveStatic('./assets', path: '/static'));
```

Requests:
- `GET /static/style.css` → `assets/style.css`
- `GET /static/images/logo.png` → `assets/images/logo.png`
- `GET /api/data` → Not handled by static middleware (passes to next handler)

### Index File Support

Automatically serve `index.html` for directory requests:

```dart
app.use(serveStatic('./public', index: 'index.html'));
```

Requests:
- `GET /` → `public/index.html`
- `GET /about/` → `public/about/index.html`

### Dotfile Protection

Control access to hidden files (files starting with `.`):

```dart
import 'package:aim_server_static/aim_server_static.dart';

// Ignore dotfiles (default) - return 404
app.use(serveStatic('./public', dotFiles: DotFiles.ignore));

// Deny dotfiles - return 403 Forbidden
app.use(serveStatic('./public', dotFiles: DotFiles.deny));

// Allow dotfiles - serve them normally
app.use(serveStatic('./public', dotFiles: DotFiles.allow));
```

Protected files:
- `.env` - Environment variables
- `.git/` - Git repository
- `.htaccess` - Apache configuration
- `.DS_Store` - macOS metadata

### Single File Serving

Use the `c.file()` extension method to serve individual files:

```dart
app.get('/download/manual', (c) {
  return c.file('docs/manual.pdf');
});

// Force download with custom filename
app.get('/download/report', (c) {
  return c.file('reports/2024-report.pdf',
    download: true,
    filename: 'Annual-Report-2024.pdf',
  );
});

// Serve user avatars
app.get('/users/:id/avatar', (c) {
  final id = c.param('id');
  return c.file('avatars/$id.png');
});
```

### Complete Example

```dart
import 'dart:io';
import 'package:aim_server/aim_server.dart';
import 'package:aim_server_static/aim_server_static.dart';

void main() async {
  final app = Aim();

  // Serve static assets under /static
  app.use(serveStatic('./public',
    path: '/static',
    index: 'index.html',
    dotFiles: DotFiles.deny,
  ));

  // Single file downloads
  app.get('/download/manual', (c) => c.file('docs/manual.pdf', download: true));

  // API routes
  app.get('/api/status', (c) => c.json({'status': 'ok'}));

  await app.serve(host: InternetAddress.anyIPv4, port: 8080);
  print('Server running on http://localhost:8080');
}
```

## API Reference

### `serveStatic(String root, {String? path, String? index, DotFiles dotFiles})`

Creates a static file serving middleware.

**Parameters:**
- `root` (required) - Root directory to serve files from (e.g., `'./public'`)
- `path` (optional) - URL prefix for serving files (e.g., `'/static'`)
- `index` (optional) - Index file name for directory requests (e.g., `'index.html'`)
- `dotFiles` (optional) - How to handle dotfiles (default: `DotFiles.ignore`)

**Returns:** `Middleware<E>`

### `c.file(String path, {bool download, String? filename})`

Context extension method for serving a single file.

**Parameters:**
- `path` (required) - Relative path to the file from current directory
- `download` (optional) - Force download instead of displaying in browser (default: `false`)
- `filename` (optional) - Custom filename for downloads

**Returns:** `Future<Response>`

**Throws:**
- `ArgumentError` - If absolute path is provided or path traversal is detected

### `DotFiles` Enum

Controls how dotfiles (files starting with `.`) are handled:

- `DotFiles.allow` - Serve dotfiles normally
- `DotFiles.deny` - Return 403 Forbidden for dotfiles
- `DotFiles.ignore` - Return 404 Not Found for dotfiles (default)

## Security

`aim_server_static` includes several built-in security features:

### Path Traversal Protection

Prevents access to files outside the root directory:

```dart
// ❌ Blocked: GET /static/../../../etc/passwd
// ❌ Blocked: GET /static/%2e%2e/secret.txt
```

The middleware normalizes paths and validates they remain within the specified root directory.

### Dotfile Protection

Prevents access to hidden files that may contain sensitive information:

```dart
// ❌ Blocked (with DotFiles.deny or ignore):
// GET /static/.env
// GET /static/.git/config
```

### Absolute Path Rejection

The `c.file()` method rejects absolute paths to prevent unintended file access:

```dart
// ❌ Throws ArgumentError
c.file('/etc/passwd');
```

## MIME Types

Automatic MIME type detection for common file formats:

| Extension | MIME Type |
|-----------|-----------|
| `.html` | `text/html` |
| `.css` | `text/css` |
| `.js` | `application/javascript` |
| `.json` | `application/json` |
| `.png` | `image/png` |
| `.jpg`, `.jpeg` | `image/jpeg` |
| `.gif` | `image/gif` |
| `.svg` | `image/svg+xml` |
| `.pdf` | `application/pdf` |
| `.txt` | `text/plain` |
| (unknown) | `application/octet-stream` |

## Contributing

Contributions are welcome! Please see the main repository for contribution guidelines.

## License

See the LICENSE file in the main repository.
