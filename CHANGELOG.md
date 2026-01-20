# Changelog
## 0.1.1
Internal fixes. No functional changes.

## 0.1.0

First beta release of Aim Framework - a modular ecosystem for Dart.

### Highlights

- Lightweight, fast web server framework
- Native PostgreSQL driver (no external dependencies)
- Type-safe ORM with Record syntax
- CLI tools with hot reload and database migrations

### Web Server (aim_server)

- HTTP server built on Dart's native `HttpServer`
- Path-based routing with parameter support (`/users/:id`)
- Composable middleware chain
- JSON, text, HTML response handling
- Real-time SSE streaming support
- Custom error handlers (404, global)

### Middleware Packages

- **aim_server_cors**: CORS configuration
- **aim_server_cookie**: Secure cookie management
- **aim_server_form**: Form data parsing
- **aim_server_multipart**: File upload handling
- **aim_server_static**: Static file serving
- **aim_server_logger**: HTTP request logging
- **aim_server_sse**: Server-Sent Events
- **aim_server_jwt**: JWT authentication
- **aim_server_basic_auth**: Basic authentication

### Testing (aim_server_testing)

- Test helpers and matchers
- Mock objects for unit testing
- Integration test utilities

### Database (aim_database + aim_postgres)

- Database abstraction layer
- Native PostgreSQL Wire Protocol implementation
- SSL/TLS support (disable, allow, prefer, require, verify-ca, verify-full)
- Authentication: cleartext, MD5, SCRAM-SHA-256
- Named parameters (`:name`) and positional parameters (`$1`)
- Transaction support with automatic commit/rollback

### ORM (aim_orm + aim_orm_postgres + aim_orm_codegen)

- Type-safe table definitions using Dart Record syntax
- Column types: `integer`, `bigint`, `varchar`, `text`, `boolean`, `timestamp`, `uuid`, `json`
- Column modifiers: `primaryKey`, `unique`, `nullable`, `withDefault`, `indexed`
- Query builders: SELECT, INSERT, UPDATE, DELETE
- Condition operators: `eq`, `gt`, `lt`, `gte`, `lte`, `inList`
- Code generation with `build_runner`

### CLI (aim_cli)

- `aim create <name>`: Project scaffolding
- `aim dev`: Development server with hot reload
- `aim build`: Production build with native compilation
- `aim db:generate`: Migration SQL generation from schema diff
- `aim db:migrate`: Apply pending migrations
- `aim db:rollback`: Rollback migrations
- `aim db:status`: Show migration status

### Known Limitations

- ORM Relations (1:1, 1:N, N:N) not yet supported
- SQLite driver not yet available
- `db:reset` command not yet implemented

### Requirements

- Dart SDK: `^3.10.0`
- PostgreSQL: 9.5+ (SCRAM-SHA-256 requires 10+)
