## 0.0.1

Initial release of aim_server - A lightweight and fast web server framework for Dart.

### Features

- HTTP Server: Built on Dart's native HTTP server with minimal overhead
- Routing:
  - Path-based routing with support for GET, POST, PUT, DELETE methods
  - Path parameters (e.g., `/users/:id`)
  - Query parameter support
- Middleware: Composable middleware chain for request/response processing
- Request/Response Handling:
  - JSON request/response support
  - Text and HTML responses
  - Redirect support
  - Custom status codes
- CORS: Built-in Cross-Origin Resource Sharing support
- Error Handling:
  - Custom 404 handler
  - Global error handler
- Environment Variables: Built-in environment variable support with the `Env` class
- Type Safety: Full Dart type safety throughout the API

### Supported

- Dart SDK: `^3.10.0`
- Platforms: All platforms supported by Dart (Linux, macOS, Windows)

### What's Included

- Core `Aim` application class
- `Context` for request handling
- `Request` and `Response` abstractions
- `Body` for request body handling
- `Message` for HTTP message handling
- CORS middleware utilities
- Environment variable utilities
