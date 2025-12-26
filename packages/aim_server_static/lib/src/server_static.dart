import 'dart:io';

import 'package:aim_server/aim_server.dart';
import 'package:aim_server_static/src/static_options.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';

/// Creates a middleware for serving static files from a directory.
///
/// This middleware serves files from the specified [root] directory with
/// built-in security features including path traversal protection and
/// dotfile restrictions.
///
/// **Parameters:**
///
/// - [root] - The root directory to serve files from (e.g., `'./public'`).
///   Can be a relative or absolute path.
///
/// - [path] - Optional URL prefix for serving files. When specified, only
///   requests starting with this prefix will be handled by this middleware.
///
///   Example: If `path: '/static'`, then `/static/style.css` will serve
///   `root/style.css`, while `/api/data` will pass to the next handler.
///
/// - [index] - Optional index file name for directory requests.
///   When specified, requests to directories will serve this file.
///
///   Example: If `index: 'index.html'`, then `/` will serve `root/index.html`
///   and `/about/` will serve `root/about/index.html`.
///
/// - [dotFiles] - Controls how dotfiles (files starting with `.`) are handled.
///   Defaults to [DotFiles.ignore]. See [DotFiles] for available options.
///
/// **Security:**
///
/// - **Path traversal protection**: Prevents access to files outside the root
///   directory using `../` in the URL.
///
/// - **Dotfile protection**: Prevents access to sensitive hidden files like
///   `.env`, `.git/config`, etc. by default.
///
/// **Example:**
///
/// Basic usage:
/// ```dart
/// import 'package:aim_server/aim_server.dart';
/// import 'package:aim_server_static/aim_server_static.dart';
///
/// final app = Aim();
/// app.use(serveStatic('./public'));
/// ```
///
/// With all options:
/// ```dart
/// app.use(serveStatic('./public',
///   path: '/static',
///   index: 'index.html',
///   dotFiles: DotFiles.deny,
/// ));
/// ```
Middleware serveStatic(
  String root, {
  String? path,
  String? index,
  DotFiles dotFiles = DotFiles.ignore,
}) {
  final normalizedRoot = normalize(absolute(root));
  return (c, next) async {
    var requestPath = c.req.path;
    if (path != null) {
      if (!requestPath.startsWith(path)) {
        return await next();
      }
      requestPath = requestPath.substring(path.length);
    }

    if (requestPath.startsWith('/')) {
      requestPath = requestPath.substring(1);
    }

    if (requestPath.isEmpty && index != null) {
      requestPath = index;
    } else if (index != null && requestPath.endsWith('/')) {
      requestPath += index;
    }

    if (dotFiles != DotFiles.allow) {
      final parts = split(requestPath);
      for (final part in parts) {
        if (part.startsWith('.') && part != '.') {
          if (dotFiles == DotFiles.deny) {
            c.text('Forbidden', statusCode: 403);
            return;
          } else {
            return await next();
          }
        }
      }
    }

    final requestedPath = normalize(join(normalizedRoot, requestPath));
    if (!isWithin(normalizedRoot, requestedPath)) {
      return await next();
    }

    final file = File(requestedPath);
    if (await file.exists()) {
      final stat = await file.stat();
      if (stat.type == FileSystemEntityType.directory) {
        return await next();
      }
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      c.stream(
        file.openRead(),
        headers: {
          'Content-Type': mimeType,
          'Content-Length': stat.size.toString(),
        },
      );
      return;
    }
    return await next();
  };
}
